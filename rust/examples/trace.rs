extern crate getopts;
extern crate lazyhtml;

use std::ptr::null_mut;
use lazyhtml::*;
use std::os::raw::c_void;
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

    let mut test_state = HandlerState::new();

    let mut feedback;

    let mut tokenizer = Tokenizer::new(2048, 256);
    tokenizer.set_cs(initial_state);

    if with_feedback {
        feedback = Feedback::new(64);
        feedback.inject_into(&mut tokenizer);
    }

    test_state.handler.inject_into(&mut tokenizer);

    tokenizer.feed(input).expect("Could not feed input");
    tokenizer.end().expect("Could not finalize input");
}
