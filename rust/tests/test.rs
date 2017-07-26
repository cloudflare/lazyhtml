extern crate lazyhtml_sys;

extern crate serde;
extern crate serde_json;

#[macro_use]
extern crate serde_derive;

// From 'rustc-test' crate.
// Mirrors Rust's internal 'libtest'.
// https://doc.rust-lang.org/1.1.0/test/index.html
extern crate test;

extern crate glob;

use serde::{Deserialize, Deserializer};

use std::collections::HashMap;
use std::fmt::{self, Formatter};
use lazyhtml_sys::*;
use lhtml_token_type_t::*;
use std::mem::{replace, zeroed};
use std::os::raw::{c_char, c_int, c_void};
use std::ascii::AsciiExt;
use std::iter::FromIterator;
use std::ptr::{null, null_mut};
use std::fs::File;
use test::{test_main, ShouldPanic, TestDesc, TestDescAndFn, TestFn, TestName};

#[derive(Clone, Copy, Deserialize)]
enum TokenKind {
    Character,
    Comment,
    StartTag,
    EndTag,

    #[serde(rename = "DOCTYPE")]
    Doctype,
}

#[derive(Debug, PartialEq, Eq)]
enum Token {
    Character(String),

    Comment(String),

    StartTag {
        name: String,
        attributes: HashMap<String, String>,
        self_closing: bool,
    },

    EndTag { name: String },

    Doctype {
        name: Option<String>,
        public_id: Option<String>,
        system_id: Option<String>,
        correctness: bool,
    },
}

impl<'de> Deserialize<'de> for Token {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        struct Visitor;

        impl<'de> ::serde::de::Visitor<'de> for Visitor {
            type Value = Token;

            fn expecting(&self, f: &mut Formatter) -> fmt::Result {
                f.write_str("['TokenKind', ...]")
            }

            fn visit_seq<A>(self, mut seq: A) -> Result<Self::Value, A::Error>
            where
                A: ::serde::de::SeqAccess<'de>,
            {
                let mut actual_length = 0;

                macro_rules! next {
                    ($expected: expr) => (match seq.next_element()? {
                        Some(value) => {
                            #[allow(unused_assignments)] {
                                actual_length += 1;
                            }

                            value
                        },
                        None => return Err(serde::de::Error::invalid_length(
                            actual_length,
                            &$expected
                        ))
                    })
                }

                let kind = next!("2 or more");

                Ok(match kind {
                    TokenKind::Character => Token::Character(next!("2")),
                    TokenKind::Comment => Token::Comment(next!("2")),
                    TokenKind::StartTag => Token::StartTag {
                        name: {
                            let mut value: String = next!("3 or 4");
                            value.make_ascii_lowercase();
                            value
                        },
                        attributes: {
                            let value: HashMap<String, String> = next!("3 or 4");
                            HashMap::from_iter(value.into_iter().map(|(mut k, v)| {
                                k.make_ascii_lowercase();
                                (k, v)
                            }))
                        },
                        self_closing: seq.next_element()?.unwrap_or(false),
                    },
                    TokenKind::EndTag => Token::EndTag {
                        name: {
                            let mut value: String = next!("2");
                            value.make_ascii_lowercase();
                            value
                        },
                    },
                    TokenKind::Doctype => Token::Doctype {
                        name: {
                            let mut value: Option<String> = next!("5");
                            if let Some(ref mut value) = value {
                                value.make_ascii_lowercase();
                            }
                            value
                        },
                        public_id: next!("5"),
                        system_id: next!("5"),
                        correctness: next!("5"),
                    },
                })
            }
        }

        deserializer.deserialize_seq(Visitor)
    }
}

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

unsafe fn lhtml_to_str(s: &lhtml_string_t) -> &str {
    let bytes = if s.data.is_null() {
        b""
    } else {
        ::std::slice::from_raw_parts(s.data as _, s.length)
    };
    ::std::str::from_utf8_unchecked(bytes)
}

unsafe fn lhtml_to_string(s: lhtml_string_t) -> String {
    lhtml_to_str(&s).to_owned()
}

unsafe fn lhtml_to_name(s: lhtml_string_t) -> String {
    lhtml_to_str(&s).to_ascii_lowercase()
}

struct HandlerState {
    handler: lhtml_token_handler_t,
    tokens: Vec<Token>,
    saw_eof: bool,
}

impl Default for HandlerState {
    fn default() -> HandlerState {
        HandlerState {
            handler: lhtml_token_handler_t {
                callback: Some(HandlerState::callback),
                next: null_mut(),
            },
            tokens: Vec::new(),
            saw_eof: false,
        }
    }
}

impl HandlerState {
    unsafe extern "C" fn callback(token: *mut lhtml_token_t, state: *mut c_void) {
        let state = state as *mut Self;
        let data = &(*token).__bindgen_anon_1;

        (*state).tokens.push(match (*token).type_ {
            LHTML_TOKEN_CHARACTER => {
                let value = lhtml_to_str(&data.character.value);

                if let Some(&mut Token::Character(ref mut s)) = (*state).tokens.last_mut() {
                    *s += value;
                    return;
                }

                Token::Character(value.to_owned())
            }
            LHTML_TOKEN_COMMENT => Token::Comment(lhtml_to_string(data.comment.value)),
            LHTML_TOKEN_START_TAG => {
                let start_tag = &data.start_tag;
                let attrs = ::std::slice::from_raw_parts(
                    start_tag.attributes.__bindgen_anon_1.buffer.data,
                    start_tag.attributes.length,
                );
                Token::StartTag {
                    name: lhtml_to_name(start_tag.name),
                    attributes: HashMap::from_iter(attrs.iter().rev().map(|attr| {
                        (lhtml_to_name(attr.name), lhtml_to_string(attr.value))
                    })),
                    self_closing: start_tag.self_closing,
                }
            }
            LHTML_TOKEN_END_TAG => Token::EndTag {
                name: lhtml_to_name(data.end_tag.name),
            },
            LHTML_TOKEN_DOCTYPE => {
                let doctype = &data.doctype;
                Token::Doctype {
                    name: if doctype.name.has_value {
                        Some(lhtml_to_name(doctype.name.value))
                    } else {
                        None
                    },
                    public_id: if doctype.public_id.has_value {
                        Some(lhtml_to_string(doctype.public_id.value))
                    } else {
                        None
                    },
                    system_id: if doctype.system_id.has_value {
                        Some(lhtml_to_string(doctype.system_id.value))
                    } else {
                        None
                    },
                    correctness: !doctype.force_quirks,
                }
            }
            LHTML_TOKEN_EOF if !(*state).saw_eof => {
                (*state).saw_eof = true;
                return;
            }
            _ => {
                panic!("Unexpected token type");
            }
        });
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
        let input = lhtml_string_t {
            data: self.input.as_ptr() as _,
            length: self.input.len(),
        };

        let last_start_tag_type = lhtml_get_tag_type(lhtml_string_t {
            data: self.last_start_tag.as_ptr() as _,
            length: self.last_start_tag.len(),
        });

        for &cs in &self.initial_states {
            let buffer: [c_char; 2048] = zeroed();
            let attr_buffer: [lhtml_attribute_t; 256] = zeroed();

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

            lhtml_init(&mut tokenizer);

            let mut test_state = HandlerState::default();

            lhtml_append_handlers(&mut tokenizer.base_handler, &mut test_state.handler);

            lhtml_feed(&mut tokenizer, &input);
            lhtml_feed(&mut tokenizer, null());

            assert!(
                test_state.tokens == self.output,
                "Token mismatch in {:?} state\n\
                 actual: {:?}\n\
                 expected: {:?}",
                cs,
                test_state.tokens,
                self.output
            );
        }
    }
}

#[derive(Deserialize)]
struct Suite {
    #[serde(default)]
    pub tests: Vec<Test>,
}

fn main() {
    let args: Vec<_> = ::std::env::args().collect();

    let tests = glob::glob(concat!(
        env!("CARGO_MANIFEST_DIR"),
        "/../html5lib-tests/tokenizer/*.test"
    )).unwrap()
        .map(|path| path.unwrap())
        .flat_map(|path| {
            let file = File::open(&path).unwrap();
            serde_json::from_reader::<_, Suite>(file).unwrap().tests
        })
        .map(|mut test| {
            let ignore = test.unescape().is_err() || test.input.chars().any(|c| match c {
                '\u{0}' | '\r' | '&' => true, // TODO: decoding support
                _ => false,
            });

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
