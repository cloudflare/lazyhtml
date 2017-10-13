extern crate html5ever;
extern crate lazyhtml;
extern crate test;

#[macro_use]
extern crate lazy_static;

use lazyhtml::*;
use test::black_box;
use std::ptr::{null, null_mut};
use std::mem::zeroed;
use test::Bencher;
use std::os::raw::{c_char, c_void};
use html5ever::tokenizer::{BufferQueue, Token, TokenSink, TokenSinkResult, Tokenizer,
                           TokenizerOpts, TokenizerResult};
use html5ever::tendril::StrTendril;

unsafe extern "C" fn handle_token(token: *mut lhtml_token_t, _state: *mut c_void) {
    black_box(*token);
}

const CHUNK_SIZE: usize = 1024;
const BUFFER_SIZE: usize = 100 << 10;
const MAX_ATTR_COUNT: usize = 256;

const HUGE_PAGE_1: &'static str = include_str!("../../bench-fixtures/huge-page.html");
const HUGE_PAGE_2: &'static str = include_str!("../../bench-fixtures/huge-page-2.html");

fn string_chunks(s: &'static str) -> Vec<&'static str> {
    let mut last_offset = 0;
    let mut result = Vec::with_capacity((s.len() / CHUNK_SIZE) + 1);
    for (offset, _) in s.char_indices() {
        if offset - last_offset >= CHUNK_SIZE {
            result.push(&s[last_offset..offset]);
            last_offset = offset;
        }
    }
    result.push(&s[last_offset..]);
    result
}

lazy_static! {
    static ref HUGE_PAGE_1_CHUNKS: Vec<&'static str> = string_chunks(HUGE_PAGE_1);
    static ref HUGE_PAGE_2_CHUNKS: Vec<&'static str> = string_chunks(HUGE_PAGE_2);
}

unsafe fn bench_lhtml_tokenizer(chunks: &[&str]) {
    let mut buffer: [c_char; BUFFER_SIZE] = zeroed();
    let mut attr_buffer: [lhtml_attribute_t; MAX_ATTR_COUNT] = zeroed();

    let mut tokenizer = lhtml_state_t {
        buffer: lhtml_buffer_t {
            data: buffer.as_mut_ptr(),
            capacity: buffer.len(),
        },
        attr_buffer: lhtml_attr_buffer_t {
            data: attr_buffer.as_mut_ptr(),
            capacity: attr_buffer.len(),
        },
        ..zeroed()
    };

    lhtml_init(&mut tokenizer);

    let mut bench_handler = lhtml_token_handler_t {
        callback: Some(handle_token),
        next: null_mut(),
    };

    lhtml_append_handlers(&mut tokenizer.base_handler, &mut bench_handler);

    for chunk in chunks {
        assert!(lhtml_feed(
            &mut tokenizer,
            &lhtml_string_t {
                data: chunk.as_ptr() as _,
                length: chunk.len(),
            }
        ));
    }

    assert!(lhtml_feed(&mut tokenizer, null()));
}

struct Sink;

impl TokenSink for Sink {
    type Handle = ();

    fn process_token(&mut self, token: Token, _line_number: u64) -> TokenSinkResult<()> {
        black_box(token);
        TokenSinkResult::Continue
    }
}

fn bench_html5ever_tokenizer(chunks: &[&str]) {
    let mut tokenizer = Tokenizer::new(Sink, TokenizerOpts::default());

    let mut queue = BufferQueue::new();

    for chunk in chunks {
        queue.push_back(StrTendril::from_slice(chunk));

        while let TokenizerResult::Script(_) = tokenizer.feed(&mut queue) {
            // ignore script markers
        }
    }

    tokenizer.end();
}

#[bench]
fn bench_lhtml_tokenizer_1(b: &mut Bencher) {
    b.iter(|| unsafe {
        bench_lhtml_tokenizer(&HUGE_PAGE_1_CHUNKS);
    });
}

#[bench]
fn bench_lhtml_tokenizer_2(b: &mut Bencher) {
    b.iter(|| unsafe {
        bench_lhtml_tokenizer(&HUGE_PAGE_2_CHUNKS);
    });
}

#[bench]
fn bench_html5ever_tokenizer_1(b: &mut Bencher) {
    b.iter(|| {
        bench_html5ever_tokenizer(&HUGE_PAGE_1_CHUNKS);
    });
}

#[bench]
fn bench_html5ever_tokenizer_2(b: &mut Bencher) {
    b.iter(|| {
        bench_html5ever_tokenizer(&HUGE_PAGE_2_CHUNKS);
    });
}
