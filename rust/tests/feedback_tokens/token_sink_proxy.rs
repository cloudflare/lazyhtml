use html5ever::tokenizer::{TagKind, Token, TokenSink, TokenSinkResult};
use std::collections::HashMap;
use std::iter::FromIterator;
use token::Token as MyToken;

// sends tokens to a given sink, while at the same time converting and
// recording them into the provided array
pub struct TokenSinkProxy<'a, Sink> {
    pub inner: Sink,
    pub tokens: &'a mut Vec<MyToken>,
}

impl<'a, Sink> TokenSinkProxy<'a, Sink> {
    fn push_character_token(&mut self, s: &str) {
        if let Some(&mut MyToken::Character(ref mut last)) = self.tokens.last_mut() {
            *last += s;
            return;
        }
        self.tokens.push(MyToken::Character(s.to_string()));
    }
}

impl<'a, Sink> TokenSink for TokenSinkProxy<'a, Sink>
where
    Sink: TokenSink,
{
    type Handle = Sink::Handle;

    fn process_token(&mut self, token: Token, line_number: u64) -> TokenSinkResult<Self::Handle> {
        match token {
            Token::DoctypeToken(ref doctype) => {
                self.tokens.push(MyToken::Doctype {
                    name: doctype.name.as_ref().map(|s| s.to_string()),
                    public_id: doctype.public_id.as_ref().map(|s| s.to_string()),
                    system_id: doctype.system_id.as_ref().map(|s| s.to_string()),
                    correctness: !doctype.force_quirks,
                });
            }
            Token::TagToken(ref tag) => {
                let name = tag.name.to_string();
                self.tokens.push(match tag.kind {
                    TagKind::StartTag => MyToken::StartTag {
                        name,
                        attributes: HashMap::from_iter(
                            tag.attrs
                                .iter()
                                .rev()
                                .map(|attr| (attr.name.local.to_string(), attr.value.to_string())),
                        ),
                        self_closing: tag.self_closing,
                    },
                    TagKind::EndTag => MyToken::EndTag {
                        name: name.to_string(),
                    },
                })
            }
            Token::CommentToken(ref s) => {
                self.tokens.push(MyToken::Comment(s.to_string()));
            }
            Token::CharacterTokens(ref s) => {
                if !s.is_empty() {
                    self.push_character_token(s);
                }
            }
            Token::NullCharacterToken => {
                self.push_character_token("\0");
            }
            _ => {}
        }
        self.inner.process_token(token, line_number)
    }

    fn end(&mut self) {
        self.inner.end()
    }

    fn adjusted_current_node_present_but_not_in_html_namespace(&self) -> bool {
        self.inner
            .adjusted_current_node_present_but_not_in_html_namespace()
    }
}
