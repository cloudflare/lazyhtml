pub use lazyhtml_sys::*;
use std::mem::zeroed;
use std::marker::PhantomData;

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

    pub fn end(mut self) -> Result<(), ()> {
        self.feed_opt(::std::ptr::null())
    }

    pub fn set_cs(&mut self, cs: ::std::os::raw::c_int) {
        self.state.cs = cs;
    }

    pub fn set_last_start_tag(&mut self, last_start_tag: &str) {
        unsafe {
            self.state.last_start_tag_type = lhtml_get_tag_type(lhtml_string_t {
                data: last_start_tag.as_ptr() as _,
                length: last_start_tag.len(),
            });
        }
    }

    pub unsafe fn get_state(&mut self) -> &mut lhtml_state_t {
        &mut self.state
    }
}

impl<'a> Drop for Tokenizer<'a> {
    fn drop(&mut self) {
        unsafe {
            let state = self.get_state();
            lhtml_drop_buffer!(state.buffer);
            lhtml_drop_buffer!(state.attr_buffer);
        }
    }
}

pub trait TokenHandler {
    fn inject_into<'a>(&'a mut self, tokenizer: &mut Tokenizer<'a>);
}

impl TokenHandler for lhtml_token_handler_t {
    fn inject_into(&mut self, tokenizer: &mut Tokenizer) {
        unsafe {
            lhtml_append_handlers(&mut tokenizer.get_state().base_handler, self);
        }
    }
}
