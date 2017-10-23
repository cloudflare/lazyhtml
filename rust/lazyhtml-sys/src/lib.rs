#![allow(non_upper_case_globals)]
#![allow(non_camel_case_types)]
#![allow(non_snake_case)]
#![allow(unused)]

use std::fmt::{self, Debug, Formatter};
use std::slice;
use std::ops::{Deref, DerefMut};

include!(concat!(env!("OUT_DIR"), "/bindings.rs"));

impl Deref for lhtml_string_t {
    type Target = [u8];

    fn deref(&self) -> &[u8] {
        if self.data.is_null() {
            &[]
        } else {
            unsafe { slice::from_raw_parts(self.data as _, self.length) }
        }
    }
}

impl Deref for lhtml_attributes_t {
    type Target = [lhtml_attribute_t];

    fn deref(&self) -> &[lhtml_attribute_t] {
        let data = unsafe { self.__bindgen_anon_1.buffer.data };

        if data.is_null() {
            &[]
        } else {
            unsafe { slice::from_raw_parts(data, self.length) }
        }
    }
}

impl DerefMut for lhtml_attributes_t {
    fn deref_mut(&mut self) -> &mut [lhtml_attribute_t] {
        let data = unsafe { self.__bindgen_anon_1.buffer.data };

        if data.is_null() {
            &mut []
        } else {
            unsafe { slice::from_raw_parts_mut(data, self.length) }
        }
    }
}

impl Debug for lhtml_string_t {
    fn fmt(&self, f: &mut Formatter) -> Result<(), fmt::Error> {
        let s = unsafe { ::std::str::from_utf8_unchecked(self) };
        s.fmt(f)
    }
}

impl Debug for lhtml_opt_string_t {
    fn fmt(&self, f: &mut Formatter) -> Result<(), fmt::Error> {
        if self.has_value {
            self.value.fmt(f)
        } else {
            f.write_str("(none)")
        }
    }
}

impl Debug for lhtml_token_comment_t {
    fn fmt(&self, f: &mut Formatter) -> Result<(), fmt::Error> {
        f.debug_struct("lhtml_token_comment_t")
            .field("value", &self.value)
            .finish()
    }
}

impl Debug for lhtml_attribute_t {
    fn fmt(&self, f: &mut Formatter) -> Result<(), fmt::Error> {
        write!(f, "{:?}: {:?} (raw: {:?})", self.name, self.value, self.raw)
    }
}

impl Debug for lhtml_attributes_t {
    fn fmt(&self, f: &mut Formatter) -> Result<(), fmt::Error> {
        f.debug_list().entries(self.iter()).finish()
    }
}

impl Debug for lhtml_token_starttag_t {
    fn fmt(&self, f: &mut Formatter) -> Result<(), fmt::Error> {
        f.debug_struct("lhtml_token_starttag_t")
            .field("name", &self.name)
            .field("attributes", &self.attributes)
            .field("self_closing", &self.self_closing)
            .finish()
    }
}

impl Debug for lhtml_token_endtag_t {
    fn fmt(&self, f: &mut Formatter) -> Result<(), fmt::Error> {
        f.debug_struct("lhtml_token_endtag_t")
            .field("name", &self.name)
            .finish()
    }
}

impl Debug for lhtml_token_doctype_t {
    fn fmt(&self, f: &mut Formatter) -> Result<(), fmt::Error> {
        f.debug_struct("lhtml_token_doctype_t")
            .field("name", &self.name)
            .field("public_id", &self.public_id)
            .field("system_id", &self.system_id)
            .field("force_quirks", &self.force_quirks)
            .finish()
    }
}

impl Debug for lhtml_token_t {
    fn fmt(&self, f: &mut Formatter) -> Result<(), fmt::Error> {
        use lhtml_token_type_t::*;

        let mut f = f.debug_struct("lhtml_token_t");

        f.field("type", &self.type_);

        unsafe {
            match self.type_ {
                LHTML_TOKEN_COMMENT => {
                    f.field("comment", &self.__bindgen_anon_1.comment);
                }
                LHTML_TOKEN_START_TAG => {
                    f.field("start_tag", &self.__bindgen_anon_1.start_tag);
                }
                LHTML_TOKEN_END_TAG => {
                    f.field("end_tag", &self.__bindgen_anon_1.end_tag);
                }
                LHTML_TOKEN_DOCTYPE => {
                    f.field("doctype", &self.__bindgen_anon_1.doctype);
                }
                _ => {}
            }
        }

        f.field("raw", &self.raw);

        f.finish()
    }
}
