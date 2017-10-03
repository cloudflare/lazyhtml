extern crate lazyhtml;

use std::mem::zeroed;
use std::ptr::{null, null_mut};
use lazyhtml::*;
use std::os::raw::{c_char, c_void};

struct HandlerState {
    handler: lhtml_token_handler_t,
}

impl HandlerState {
    pub fn new() -> Self {
        HandlerState {
            handler: lhtml_token_handler_t {
                callback: Some(Self::callback),
                next: null_mut(),
            },
        }
    }

    unsafe extern "C" fn callback(token: *mut lhtml_token_t, extra: *mut c_void) {
        println!("{:#?}", *token);
        lhtml_emit(token, extra);
    }
}

fn main() {
    unsafe {
        let buffer: [c_char; 2048] = zeroed();
        let attr_buffer: [lhtml_attribute_t; 256] = zeroed();
        let ns_buffer: [lhtml_ns_t; 64] = zeroed();

        let initial_state = html_en_Data;
        let with_feedback = false;

        let mut tokenizer = lhtml_state_t {
            cs: initial_state as _,
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

        let mut feedback = lhtml_feedback_state_t {
            ns_stack: lhtml_ns_stack_t {
                __bindgen_anon_1: lhtml_ns_stack_t__bindgen_ty_1 {
                    buffer: lhtml_ns_buffer_t {
                        data: ns_buffer.as_ptr(),
                        capacity: ns_buffer.len(),
                    },
                },
                length: 0,
            },
            ..zeroed()
        };

        lhtml_init(&mut tokenizer);

        if with_feedback {
            lhtml_feedback_inject(&mut tokenizer, &mut feedback);
        }

        let mut test_state = HandlerState::new();
        lhtml_append_handlers(&mut tokenizer.base_handler, &mut test_state.handler);

        let input = ::std::env::args().nth(1).expect("Provide HTML snippet");

        assert!(lhtml_feed(
            &mut tokenizer,
            &lhtml_string_t {
                data: input.as_ptr() as _,
                length: input.len(),
            },
        ));

        assert!(lhtml_feed(&mut tokenizer, null()));
    }
}
