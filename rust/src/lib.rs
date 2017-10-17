extern crate lazyhtml_sys;

pub use lazyhtml_sys::*;
use std::ops::{Deref, DerefMut};

macro_rules! lhtml_alloc_buffer {
    ($ty:ident, $capacity:expr) => {{
        let mut vec = Vec::with_capacity($capacity);
        let buf = $ty {
            data: vec.as_mut_ptr(),
            capacity: vec.capacity()
        };
        ::std::mem::forget(vec);
        buf
    }};
}

macro_rules! lhtml_drop_buffer {
    ($buf:expr) => {
        unsafe {
            let buf = $buf;
            Box::from_raw(::std::slice::from_raw_parts_mut(
                buf.data,
                buf.capacity
            ));
        }
    }
}

pub struct Tokenizer(lhtml_state_t);

impl Tokenizer {
    pub fn new(char_capacity: usize, attr_capacity: usize) -> Self {
        let mut state = lhtml_state_t {
            buffer: lhtml_alloc_buffer!(lhtml_char_buffer_t, char_capacity),
            attr_buffer: lhtml_alloc_buffer!(lhtml_attr_buffer_t, attr_capacity),
            ..unsafe { ::std::mem::zeroed() }
        };
        unsafe {
            lhtml_init(&mut state);
        }
        Tokenizer(state)
    }

    fn feed_opt(&mut self, input: *const lhtml_string_t) -> Result<(), ()> {
        if unsafe { lhtml_feed(&mut self.0, input) } {
            Ok(())
        } else {
            Err(())
        }
    }

    pub fn feed(&mut self, input: &str) -> Result<(), ()> {
        self.feed_opt(&lhtml_string_t {
            data: input.as_ptr() as _,
            length: input.len(),
        })
    }

    pub fn end(&mut self) -> Result<(), ()> {
        self.feed_opt(::std::ptr::null())
    }

    pub fn set_cs(&mut self, cs: ::std::os::raw::c_int) {
        self.cs = cs;
    }

    pub fn set_last_start_tag(&mut self, last_start_tag: &str) {
        self.last_start_tag_type = unsafe {
            lhtml_get_tag_type(lhtml_string_t {
                data: last_start_tag.as_ptr() as _,
                length: last_start_tag.len(),
            })
        };
    }
}

impl Drop for Tokenizer {
    fn drop(&mut self) {
        lhtml_drop_buffer!(self.buffer);
        lhtml_drop_buffer!(self.attr_buffer);
    }
}

impl Deref for Tokenizer {
    type Target = lhtml_state_t;

    fn deref(&self) -> &lhtml_state_t {
        &self.0
    }
}

impl DerefMut for Tokenizer {
    fn deref_mut(&mut self) -> &mut lhtml_state_t {
        &mut self.0
    }
}
