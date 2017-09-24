use token::Token;
use serde_json::error::Error;
use serde_json::de::from_str as parse_json;

pub trait Unescape {
    fn unescape(&mut self) -> Result<(), Error>;
}

impl Unescape for String {
    // dummy but does the job
    fn unescape(&mut self) -> Result<(), Error> {
        *self = parse_json(&format!(r#""{}""#, self))?;
        Ok(())
    }
}

impl<T: Unescape> Unescape for Option<T> {
    fn unescape(&mut self) -> Result<(), Error> {
        if let Some(ref mut inner) = *self {
            inner.unescape()?;
        }
        Ok(())
    }
}

impl Unescape for Token {
    fn unescape(&mut self) -> Result<(), Error> {
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
