extern crate lazyhtml;

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
mod unescape;
mod html5lib;

use std::collections::HashMap;
use lazyhtml::*;
use std::mem::{replace, zeroed};
use std::os::raw::c_void;
use std::ascii::AsciiExt;
use std::iter::FromIterator;
use std::ptr::null_mut;
use test::{test_main, ShouldPanic, TestDesc, TestDescAndFn, TestFn, TestName};
use token::Token;
use decoder::Decoder;
use unescape::Unescape;
use html5lib::{get_tests, Test};

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
    tokenizer: *const lhtml_state_t,
    tokens: Vec<Token>,
    raw_output: String,
    saw_eof: bool,
}

impl HandlerState {
    pub fn new(tokenizer: &lhtml_state_t) -> Self {
        HandlerState {
            handler: lhtml_token_handler_t {
                callback: Some(HandlerState::callback),
                next: null_mut(),
            },
            tokenizer,
            tokens: Vec::new(),
            raw_output: String::new(),
            saw_eof: false,
        }
    }

    unsafe extern "C" fn callback(token: *mut lhtml_token_t, extra: *mut c_void) {
        use lhtml_token_type_t::*;

        let state = &mut *(extra as *mut Self);
        let data = &(*token).__bindgen_anon_1;

        if let Some(&mut Token::Character(ref mut s)) = state.tokens.last_mut() {
            if (*token).type_ != LHTML_TOKEN_CHARACTER {
                *s = {
                    let mut decoder = Decoder::new(s);

                    if (*state.tokenizer).unsafe_null {
                        decoder = decoder.unsafe_null();
                    }

                    if (*state.tokenizer).entities {
                        decoder = decoder.text_entities();
                    }

                    decoder.run()
                };
            }
        }

        let test_token = match (*token).type_ {
            LHTML_TOKEN_CDATA_START | LHTML_TOKEN_CDATA_END => None,
            LHTML_TOKEN_CHARACTER => {
                let value = lhtml_to_raw_str(&data.character.value);

                if let Some(&mut Token::Character(ref mut s)) = state.tokens.last_mut() {
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

                assert_eq!(lhtml_get_tag_type(start_tag.name), start_tag.type_);

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
            LHTML_TOKEN_END_TAG => {
                let end_tag = &data.end_tag;

                assert_eq!(lhtml_get_tag_type(end_tag.name), end_tag.type_);

                Some(Token::EndTag {
                    name: lhtml_to_name(end_tag.name),
                })
            }
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
            LHTML_TOKEN_EOF if !state.saw_eof => {
                state.saw_eof = true;
                None
            }
            _ => {
                panic!("Unexpected token type");
            }
        };

        if let Some(test_token) = test_token {
            state.tokens.push(test_token);
        }

        assert!((*token).raw.has_value);
        state.raw_output += lhtml_to_raw_str(&(*token).raw.value);
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

impl Test {
    pub unsafe fn run(&self) {
        for &cs in &self.initial_states {
            let mut serializer = SerializerState::new();

            for pass in 0..2 {
                let mut feedback;

                let mut tokenizer = Tokenizer::new(2048, 256);
                tokenizer.set_cs(cs as _);
                tokenizer.set_last_start_tag(&self.last_start_tag);

                if self.with_feedback {
                    feedback = Feedback::new(64);
                    feedback.inject_into(&mut tokenizer);
                }

                let mut test_state = HandlerState::new(&tokenizer);
                lhtml_append_handlers(&mut tokenizer.base_handler, &mut test_state.handler);

                let input = if pass == 0 {
                    lhtml_serializer_inject(&mut *tokenizer, &mut serializer.serializer);
                    &self.input
                } else {
                    &serializer.output
                };

                tokenizer.feed(input).expect("Could not feed input");
                tokenizer.end().expect("Could not finalize input");

                assert_eq!(&test_state.raw_output, input);

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

fn main() {
    let args: Vec<_> = ::std::env::args().collect();

    let tests = get_tests()
        .into_iter()
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
