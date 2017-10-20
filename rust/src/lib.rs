extern crate lazyhtml_sys;

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
        let buf = $buf;
        Box::from_raw(::std::slice::from_raw_parts_mut(
            buf.data,
            buf.capacity
        ));
    }
}

mod tokenizer;
mod feedback;
mod serializer;

pub use tokenizer::*;
pub use feedback::*;
pub use serializer::*;
