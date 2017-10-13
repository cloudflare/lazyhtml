extern crate glob;
extern crate html5ever;
extern crate lazyhtml;
extern crate test;

use lazyhtml::*;
use test::black_box;
use std::ptr::{null, null_mut};
use std::mem::zeroed;
use test::Bencher;
use std::os::raw::{c_char, c_void};
use html5ever::tokenizer::{BufferQueue, Token, TokenSink, TokenSinkResult, Tokenizer,
                           TokenizerOpts, TokenizerResult};
use html5ever::tendril::StrTendril;
use test::{test_main, ShouldPanic, TDynBenchFn, TestDesc, TestDescAndFn, TestFn, TestName};
use std::fs::File;
use std::io::Read;

unsafe extern "C" fn handle_token(token: *mut lhtml_token_t, _state: *mut c_void) {
    black_box(*token);
}

const CHUNK_SIZE: usize = 1024;
const BUFFER_SIZE: usize = 100 << 10;
const MAX_ATTR_COUNT: usize = 256;

fn string_chunks(mut s: &str) -> Vec<String> {
    let mut result = Vec::with_capacity((s.len() / CHUNK_SIZE) + 1);

    while !s.is_empty() {
        let mut offset = CHUNK_SIZE;

        if offset < s.len() {
            while !s.is_char_boundary(offset) {
                offset += 1;
            }
        } else {
            offset = s.len();
        }

        let (before, after) = s.split_at(offset);

        result.push(before.to_owned());

        s = after;
    }

    result
}

fn bench_lhtml_tokenizer(chunks: &[String]) {
    unsafe {
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
}

struct Sink;

impl TokenSink for Sink {
    type Handle = ();

    fn process_token(&mut self, token: Token, _line_number: u64) -> TokenSinkResult<()> {
        black_box(token);
        TokenSinkResult::Continue
    }
}

fn bench_html5ever_tokenizer(chunks: &[String]) {
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

struct Bench {
    func: fn(&[String]),
    chunks: Vec<String>,
}

impl TDynBenchFn for Bench {
    fn run(&self, b: &mut Bencher) {
        b.iter(|| {
            (self.func)(&self.chunks);
        });
    }
}

fn main() {
    let args: Vec<_> = ::std::env::args().collect();

    let fixtures: Vec<_> = glob::glob("../bench-fixtures/*.html")
        .unwrap()
        .map(|path| path.unwrap())
        .collect();

    let funcs: [(&str, fn(&[String])); 2] = [
        ("bench_lhtml_tokenizer", bench_lhtml_tokenizer),
        ("bench_html5ever_tokenizer", bench_html5ever_tokenizer),
    ];

    let mut tests = Vec::with_capacity(fixtures.len() * funcs.len());

    for path in fixtures {
        let mut input = String::new();
        File::open(&path)
            .unwrap()
            .read_to_string(&mut input)
            .unwrap();

        let input_name = path.file_name().unwrap().to_str().unwrap();

        let chunks = string_chunks(&input);

        for &(func_name, func) in &funcs {
            tests.push(TestDescAndFn {
                desc: TestDesc {
                    name: TestName::DynTestName(format!("{} x {}", func_name, input_name)),
                    ignore: false,
                    should_panic: ShouldPanic::No,
                    allow_fail: false,
                },
                testfn: TestFn::DynBenchFn(Box::new(Bench {
                    func,
                    chunks: chunks.clone(),
                })),
            });
        }
    }

    test_main(&args, tests);
}
