extern crate lazyhtml_sys;

pub use lazyhtml_sys::*;
use std::ops::{Deref, DerefMut};
use std::mem::zeroed;
use std::marker::PhantomData;

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

pub struct Tokenizer<'a> {
    state: lhtml_state_t,
    phantom: PhantomData<&'a ()>,
}

impl<'a> Tokenizer<'a> {
    pub fn new(char_capacity: usize, attr_capacity: usize) -> Self {
        let mut state = lhtml_state_t {
            buffer: lhtml_alloc_buffer!(lhtml_char_buffer_t, char_capacity),
            attr_buffer: lhtml_alloc_buffer!(lhtml_attr_buffer_t, attr_capacity),
            ..unsafe { zeroed() }
        };
        unsafe {
            lhtml_init(&mut state);
        }
        Tokenizer {
            state,
            phantom: PhantomData,
        }
    }

    fn feed_opt(&mut self, input: *const lhtml_string_t) -> Result<(), ()> {
        if unsafe { lhtml_feed(&mut self.state, input) } {
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

impl<'a> Drop for Tokenizer<'a> {
    fn drop(&mut self) {
        lhtml_drop_buffer!(self.buffer);
        lhtml_drop_buffer!(self.attr_buffer);
    }
}

impl<'a> Deref for Tokenizer<'a> {
    type Target = lhtml_state_t;

    fn deref(&self) -> &lhtml_state_t {
        &self.state
    }
}

impl<'a> DerefMut for Tokenizer<'a> {
    fn deref_mut(&mut self) -> &mut lhtml_state_t {
        &mut self.state
    }
}

pub trait TokenHandler {
    fn inject_into<'a>(&'a mut self, tokenizer: &mut Tokenizer<'a>);
}

pub struct Feedback(lhtml_feedback_state_t);

impl Feedback {
    pub fn new(ns_capacity: usize) -> Self {
        Feedback(lhtml_feedback_state_t {
            ns_stack: lhtml_ns_stack_t {
                __bindgen_anon_1: lhtml_ns_stack_t__bindgen_ty_1 {
                    buffer: lhtml_alloc_buffer!(lhtml_ns_buffer_t, ns_capacity),
                },
                length: 0,
            },
            ..unsafe { zeroed() }
        })
    }
}

impl TokenHandler for Feedback {
    fn inject_into(&mut self, tokenizer: &mut Tokenizer) {
        unsafe {
            lhtml_feedback_inject(&mut tokenizer.state, &mut self.0);
        }
    }
}

impl Drop for Feedback {
    fn drop(&mut self) {
        lhtml_drop_buffer!(self.0.ns_stack.__bindgen_anon_1.buffer);
    }
}

#[repr(C)]
pub struct Serializer<F> {
    state: lhtml_serializer_state_t,
    callback: F,
}

impl<F: FnMut(&str)> Serializer<F> {
    pub fn new(callback: F) -> Self {
        Serializer {
            state: lhtml_serializer_state_t {
                handler: unsafe { zeroed() },
                writer: Some(Self::writer),
            },
            callback,
        }
    }

    unsafe extern "C" fn writer(s: lhtml_string_t, state: *mut lhtml_serializer_state_t) {
        if s.length == 0 {
            // not just optimisation, but also ensures that from_raw_parts
            // doesn't get an unsupported NULL pointer
            return;
        }
        ((*(state as *mut Self)).callback)(::std::str::from_utf8_unchecked(
            ::std::slice::from_raw_parts(s.data as _, s.length),
        ))
    }
}

impl<F> TokenHandler for Serializer<F> {
    fn inject_into(&mut self, tokenizer: &mut Tokenizer) {
        unsafe {
            lhtml_serializer_inject(&mut tokenizer.state, &mut self.state);
        }
    }
}
