pub use lazyhtml_sys::*;
use std::mem::zeroed;
use tokenizer::*;

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
        ((*(state as *mut Self)).callback)(::std::str::from_utf8_unchecked(&s))
    }
}

impl<F> TokenHandler for Serializer<F> {
    fn inject_into(&mut self, tokenizer: &mut Tokenizer) {
        unsafe {
            lhtml_serializer_inject(tokenizer.get_state(), &mut self.state);
        }
    }
}
