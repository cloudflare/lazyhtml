extern crate lazyhtml_sys;

extern crate serde;
extern crate serde_json;

#[macro_use]
extern crate serde_derive;

#[macro_use]
extern crate html5ever;

// From 'rustc-test' crate.
// Mirrors Rust's internal 'libtest'.
// https://doc.rust-lang.org/1.1.0/test/index.html
extern crate test;

extern crate glob;

mod token;
mod feedback_tokens;
mod decoder;

use std::collections::HashMap;
use lazyhtml_sys::*;
use lhtml_token_character_kind_t::*;
use std::mem::{replace, zeroed};
use std::os::raw::{c_char, c_int, c_void};
use std::ascii::AsciiExt;
use std::iter::FromIterator;
use std::ptr::{null, null_mut};
use std::fs::File;
use test::{test_main, ShouldPanic, TestDesc, TestDescAndFn, TestFn, TestName};
use token::Token;
use std::io::{BufRead, BufReader};
use feedback_tokens::tokenize_with_tree_builder;
use decoder::Decoder;

#[derive(Clone, Copy, Deserialize, Debug)]
enum InitialState {
    #[serde(rename = "Data state")]
    Data,

    #[serde(rename = "PLAINTEXT state")]
    PlainText,

    #[serde(rename = "RCDATA state")]
    RCData,

    #[serde(rename = "RAWTEXT state")]
    RawText,

    #[serde(rename = "Script data state")]
    ScriptData,

    #[serde(rename = "CDATA section state")]
    CData,
}

impl InitialState {
    unsafe fn to_lhtml(self) -> c_int {
        use InitialState::*;

        match self {
            Data => LHTML_STATE_DATA,
            PlainText => LHTML_STATE_PLAINTEXT,
            RCData => LHTML_STATE_RCDATA,
            RawText => LHTML_STATE_RAWTEXT,
            ScriptData => LHTML_STATE_SCRIPTDATA,
            CData => LHTML_STATE_CDATA,
        }
    }
}

fn default_initial_states() -> Vec<InitialState> {
    vec![InitialState::Data]
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
struct Test {
    pub description: String,
    pub input: String,
    pub output: Vec<Token>,

    #[serde(skip)]
    pub with_feedback: bool,

    #[serde(default = "default_initial_states")]
    pub initial_states: Vec<InitialState>,

    #[serde(default)]
    pub double_escaped: bool,

    #[serde(default)]
    pub last_start_tag: String,
}

trait Unescape {
    fn unescape(&mut self) -> Result<(), serde_json::error::Error>;
}

impl Unescape for String {
    // dummy but does the job
    fn unescape(&mut self) -> Result<(), serde_json::error::Error> {
        *self = serde_json::de::from_str(&format!(r#""{}""#, self))?;
        Ok(())
    }
}

impl<T: Unescape> Unescape for Option<T> {
    fn unescape(&mut self) -> Result<(), serde_json::error::Error> {
        if let Some(ref mut inner) = *self {
            inner.unescape()?;
        }
        Ok(())
    }
}

impl Unescape for Token {
    fn unescape(&mut self) -> Result<(), serde_json::error::Error> {
        match *self {
            Token::Character(ref mut s) | Token::Comment(ref mut s) => {
                s.unescape()?;
            }

            Token::EndTag { ref mut name } => {
                name.unescape()?;
            }

            Token::StartTag {
                ref mut name,
                ref mut attributes,
                ..
            } => {
                name.unescape()?;
                for value in attributes.values_mut() {
                    value.unescape()?;
                }
            }

            Token::Doctype {
                ref mut name,
                ref mut public_id,
                ref mut system_id,
                ..
            } => {
                name.unescape()?;
                public_id.unescape()?;
                system_id.unescape()?;
            }
        }
        Ok(())
    }
}

unsafe fn lhtml_to_raw_str(s: &lhtml_string_t) -> &str {
    let bytes = if s.data.is_null() {
        b""
    } else {
        ::std::slice::from_raw_parts(s.data as _, s.length)
    };
    ::std::str::from_utf8_unchecked(bytes)
}

unsafe fn lhtml_to_name(s: lhtml_string_t) -> String {
    let mut s = Decoder::new(lhtml_to_raw_str(&s)).unsafe_null().run();

    s.make_ascii_lowercase();

    s
}

struct HandlerState {
    handler: lhtml_token_handler_t,
    tokens: Vec<Token>,
    saw_eof: bool,
    last_char_kind: lhtml_token_character_kind_t,
}

impl Default for HandlerState {
    fn default() -> Self {
        HandlerState {
            handler: lhtml_token_handler_t {
                callback: Some(HandlerState::callback),
                next: null_mut(),
            },
            tokens: Vec::new(),
            saw_eof: false,
            last_char_kind: LHTML_TOKEN_CHARACTER_RAW,
        }
    }
}

impl HandlerState {
    unsafe extern "C" fn callback(token: *mut lhtml_token_t, extra: *mut c_void) {
        use lhtml_token_type_t::*;

        let state = extra as *mut Self;
        let data = &(*token).__bindgen_anon_1;

        if let Some(&mut Token::Character(ref mut s)) = (*state).tokens.last_mut() {
            if (*token).type_ != LHTML_TOKEN_CHARACTER {
                if (*state).last_char_kind == LHTML_TOKEN_CHARACTER_RAW {
                    println!("Raw character token: {:?}", s);
                }

                *s = match (*state).last_char_kind {
                    LHTML_TOKEN_CHARACTER_RAW => Decoder::new(s),

                    LHTML_TOKEN_CHARACTER_RCDATA => Decoder::new(s).unsafe_null().text_entities(),

                    LHTML_TOKEN_CHARACTER_SAFE => Decoder::new(s).unsafe_null(),

                    LHTML_TOKEN_CHARACTER_DATA => Decoder::new(s).text_entities(),
                }.run();

                (*state).last_char_kind = LHTML_TOKEN_CHARACTER_RAW;
            }
        }

        let test_token = match (*token).type_ {
            LHTML_TOKEN_CDATA_START | LHTML_TOKEN_CDATA_END => None,
            LHTML_TOKEN_CHARACTER => {
                let value = lhtml_to_raw_str(&data.character.value);

                match ((*state).last_char_kind, data.character.kind) {
                    (LHTML_TOKEN_CHARACTER_RAW, kind) => {
                        (*state).last_char_kind = kind;
                    }
                    (_, LHTML_TOKEN_CHARACTER_RAW) => {}
                    (last_char_kind, kind) => {
                        assert_eq!(
                            last_char_kind,
                            kind,
                            "Consequent character tokens with different kinds"
                        );
                    }
                }

                if let Some(&mut Token::Character(ref mut s)) = (*state).tokens.last_mut() {
                    *s += value;
                    None
                } else {
                    Some(Token::Character(value.to_owned()))
                }
            }
            LHTML_TOKEN_COMMENT => Some(Token::Comment(
                Decoder::new(lhtml_to_raw_str(&data.comment.value))
                    .unsafe_null()
                    .run(),
            )),
            LHTML_TOKEN_START_TAG => {
                let start_tag = &data.start_tag;

                let attrs = ::std::slice::from_raw_parts_mut(
                    // need to cast mutability because
                    // https://github.com/rust-lang-nursery/rust-bindgen/issues/511
                    start_tag.attributes.__bindgen_anon_1.buffer.data as *mut lhtml_attribute_t,
                    start_tag.attributes.length,
                );

                Some(Token::StartTag {
                    name: lhtml_to_name(start_tag.name),

                    attributes: HashMap::from_iter(attrs.iter_mut().rev().map(|attr| {
                        attr.raw.has_value = false;

                        (
                            lhtml_to_name(attr.name),
                            Decoder::new(lhtml_to_raw_str(&attr.value))
                                .unsafe_null()
                                .attr_entities()
                                .run(),
                        )
                    })),

                    self_closing: start_tag.self_closing,
                })
            }
            LHTML_TOKEN_END_TAG => Some(Token::EndTag {
                name: lhtml_to_name(data.end_tag.name),
            }),
            LHTML_TOKEN_DOCTYPE => {
                let doctype = &data.doctype;

                Some(Token::Doctype {
                    name: if doctype.name.has_value {
                        Some(lhtml_to_name(doctype.name.value))
                    } else {
                        None
                    },
                    public_id: if doctype.public_id.has_value {
                        Some(
                            Decoder::new(lhtml_to_raw_str(&doctype.public_id.value))
                                .unsafe_null()
                                .run(),
                        )
                    } else {
                        None
                    },
                    system_id: if doctype.system_id.has_value {
                        Some(
                            Decoder::new(lhtml_to_raw_str(&doctype.system_id.value))
                                .unsafe_null()
                                .run(),
                        )
                    } else {
                        None
                    },
                    correctness: !doctype.force_quirks,
                })
            }
            LHTML_TOKEN_EOF if !(*state).saw_eof => {
                (*state).saw_eof = true;
                None
            }
            _ => {
                panic!("Unexpected token type");
            }
        };

        if let Some(test_token) = test_token {
            (*state).tokens.push(test_token);
        }

        (*token).raw.has_value = false;

        lhtml_emit(token, extra);
    }
}

struct SerializerState {
    serializer: lhtml_serializer_state_t,
    output: String,
}

impl SerializerState {
    fn new() -> Self {
        SerializerState {
            serializer: lhtml_serializer_state_t {
                writer: Some(SerializerState::callback),
                ..unsafe { zeroed() }
            },
            output: String::new(),
        }
    }

    unsafe extern "C" fn callback(s: lhtml_string_t, state: *mut lhtml_serializer_state_t) {
        (*(state as *mut SerializerState)).output += lhtml_to_raw_str(&s);
    }
}

impl Unescape for Test {
    fn unescape(&mut self) -> Result<(), serde_json::error::Error> {
        if self.double_escaped {
            self.double_escaped = false;
            self.input.unescape()?;
            for token in &mut self.output {
                token.unescape()?;
            }
        }
        Ok(())
    }
}

impl Test {
    pub unsafe fn run(&self) {
        let last_start_tag_type = lhtml_get_tag_type(lhtml_string_t {
            data: self.last_start_tag.as_ptr() as _,
            length: self.last_start_tag.len(),
        });

        for &cs in &self.initial_states {
            let mut serializer = SerializerState::new();

            for pass in 0..2 {
                let buffer: [c_char; 2048] = zeroed();
                let attr_buffer: [lhtml_attribute_t; 256] = zeroed();
                let ns_buffer: [lhtml_ns_t; 64] = zeroed();

                let mut tokenizer = lhtml_state_t {
                    cs: cs.to_lhtml(),
                    last_start_tag_type,
                    buffer: lhtml_buffer_t {
                        data: buffer.as_ptr(),
                        capacity: buffer.len(),
                    },
                    attr_buffer: lhtml_attr_buffer_t {
                        data: attr_buffer.as_ptr(),
                        capacity: attr_buffer.len(),
                    },
                    ..zeroed()
                };

                let mut feedback = lhtml_feedback_state_t {
                    ns_stack: lhtml_ns_stack_t {
                        __bindgen_anon_1: lhtml_ns_stack_t__bindgen_ty_1 {
                            buffer: lhtml_ns_buffer_t {
                                data: ns_buffer.as_ptr(),
                                capacity: ns_buffer.len(),
                            },
                        },
                        length: 0,
                    },
                    ..zeroed()
                };

                lhtml_init(&mut tokenizer);

                if self.with_feedback {
                    lhtml_feedback_inject(&mut tokenizer, &mut feedback);
                }

                let mut test_state = HandlerState::default();
                lhtml_append_handlers(&mut tokenizer.base_handler, &mut test_state.handler);

                let input = if pass == 0 {
                    lhtml_serializer_inject(&mut tokenizer, &mut serializer.serializer);
                    &self.input
                } else {
                    &serializer.output
                };

                lhtml_feed(
                    &mut tokenizer,
                    &lhtml_string_t {
                        data: input.as_ptr() as _,
                        length: input.len(),
                    },
                );

                lhtml_feed(&mut tokenizer, null());

                assert!(
                    test_state.tokens == self.output,
                    "Token mismatch\n\
                     state: {:?}\n\
                     with feedback: {:?}\n\
                     original input: {:?}\n\
                     input: {:?}\n\
                     actual: {:#?}\n\
                     expected: {:#?}",
                    cs,
                    self.with_feedback,
                    if pass == 1 { Some(&self.input) } else { None },
                    input,
                    test_state.tokens,
                    self.output
                );
            }
        }
    }
}

#[derive(Deserialize)]
struct Suite {
    #[serde(default)]
    pub tests: Vec<Test>,
}

macro_rules! read_tests {
    ($path: expr) => (
        glob::glob(concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/../html5lib-tests/",
            $path
        )).unwrap()
        .map(|path| BufReader::new(File::open(path.unwrap()).unwrap()))
    )
}

fn main() {
    let args: Vec<_> = ::std::env::args().collect();

    let tests = read_tests!("tokenizer/*.test")
        .flat_map(|file| {
            serde_json::from_reader::<_, Suite>(file).unwrap().tests
        })
        .chain(
            read_tests!("tree-construction/*.dat")
                .flat_map(|file| {
                    let mut inputs = Vec::new();
                    let mut in_data = 0;
                    for line in file.lines().map(|line| line.unwrap()) {
                        if line == "#data" {
                            in_data = 1;
                        } else if line.starts_with('#') {
                            in_data = 0;
                        } else if in_data > 0 {
                            if in_data > 1 {
                                let s: &mut String = inputs.last_mut().unwrap();
                                s.push('\n');
                                s.push_str(&line);
                            } else {
                                inputs.push(line);
                            }
                            in_data += 1;
                        }
                    }
                    inputs
                })
                .map(|input| {
                    Test {
                        description: input.chars().flat_map(|c| c.escape_default()).collect(),
                        output: tokenize_with_tree_builder(&input),
                        input,
                        with_feedback: true,
                        initial_states: default_initial_states(),
                        double_escaped: false,
                        last_start_tag: String::new(),
                    }
                }),
        )
        .map(|mut test| {
            let ignore = test.unescape().is_err();

            TestDescAndFn {
                desc: TestDesc {
                    name: TestName::DynTestName(replace(&mut test.description, String::new())),
                    ignore,
                    should_panic: ShouldPanic::No,
                    allow_fail: false,
                },
                testfn: TestFn::DynTestFn(Box::new(move || unsafe {
                    test.run();
                })),
            }
        })
        .collect();

    test_main(&args, tests);
}
