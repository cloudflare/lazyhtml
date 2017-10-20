pub use lazyhtml_sys::*;
use std::mem::zeroed;
use tokenizer::*;

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
            lhtml_feedback_inject(tokenizer.get_state(), &mut self.0);
        }
    }
}

impl Drop for Feedback {
    fn drop(&mut self) {
        unsafe {
            lhtml_drop_buffer!(self.0.ns_stack.__bindgen_anon_1.buffer);
        }
    }
}
