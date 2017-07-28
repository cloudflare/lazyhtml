use std::collections::HashMap;
use serde::de::{Deserialize, Deserializer, Error as DeError};
use std::fmt::{self, Formatter};
use std::iter::FromIterator;
use std::ascii::AsciiExt;

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
pub enum Token {
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
                        None => return Err(DeError::invalid_length(
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
