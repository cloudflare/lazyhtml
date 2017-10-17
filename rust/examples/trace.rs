extern crate getopts;
extern crate lazyhtml;

use std::mem::zeroed;
use std::ptr::{null, null_mut};
use lazyhtml::*;
use std::os::raw::{c_char, c_void};
use getopts::Options;
use std::env::args;

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
    let mut opts = Options::new();

    opts.optflag("f", "feedback", "Enable parser feedback");
    opts.optopt(
        "s",
        "state",
        "Initial state",
        "-s (Data|PlainText|RCData|RawText|ScriptData|CDataSection)",
    );
    opts.optflag("h", "help", "Show this help");

    let matches = match opts.parse(args().skip(1)) {
        Ok(matches) => if matches.free.is_empty() {
            eprintln!("Missing HTML input");
            None
        } else if matches.opt_present("h") {
            None
        } else {
            Some(matches)
        },
        Err(e) => {
            eprintln!("{}", e);
            None
        }
    };

    let matches = match matches {
        Some(m) => m,
        None => {
            eprintln!("{}", opts.usage("Usage: trace [options] INPUT"));
            return;
        }
    };

    let initial_state = match matches.opt_str("s").as_ref().map(|s| s.as_str()) {
        None | Some("Data") => html_en_Data,
        Some("PlainText") => html_en_PlainText,
        Some("RCData") => html_en_RCData,
        Some("RawText") => html_en_RawText,
        Some("ScriptData") => html_en_ScriptData,
        Some("CDataSection") => html_en_CDataSection,
        _ => {
            eprintln!("Unknown state, defaulting to Data");
            html_en_Data
        }
    };

    let with_feedback = matches.opt_present("f");

    let input = matches.free.first().unwrap();

    unsafe {
        let buffer: [c_char; 2048] = zeroed();
        let attr_buffer: [lhtml_attribute_t; 256] = zeroed();
        let ns_buffer: [lhtml_ns_t; 64] = zeroed();

        let mut tokenizer = lhtml_state_t {
            cs: initial_state,
            buffer: lhtml_char_buffer_t {
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
