use serde_json;
use glob;
use std::io::{BufRead, BufReader};
use std::fs::File;
use unescape::Unescape;
use lazyhtml;
use token::{Token, TokenRange};
use feedback_tokens::tokenize_with_tree_builder;
use parse_errors::{ParseErrors, ERROR_CODES};

// Skip some errors in certain tests due to the limited functionality of the parser.
const SKIP_ERRORS: &'static [(&'static str, &'static str)] = &[
    ("Duplicate close tag attributes", "duplicate-attribute"), // We don't collect attributes on end tags
];

#[derive(Deserialize)]
struct Suite {
    #[serde(default)]
    pub tests: Vec<Test>,
}

macro_rules! read_tests {
    ($path: expr) => (
        glob::glob(concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/../",
            $path
        )).unwrap()
        .map(|path| BufReader::new(File::open(path.unwrap()).unwrap()))
    )
}

#[derive(Clone, Copy, Deserialize, Debug)]
#[repr(i32)]
pub enum InitialState {
    #[serde(rename = "Data state")]
    Data = lazyhtml::html_en_Data,
    #[serde(rename = "PLAINTEXT state")]
    PlainText = lazyhtml::html_en_PlainText,
    #[serde(rename = "RCDATA state")]
    RCData = lazyhtml::html_en_RCData,
    #[serde(rename = "RAWTEXT state")]
    RawText = lazyhtml::html_en_RawText,
    #[serde(rename = "Script data state")]
    ScriptData = lazyhtml::html_en_ScriptData,
    #[serde(rename = "CDATA section state")]
    CDataSection = lazyhtml::html_en_CDataSection,
}

fn default_initial_states() -> Vec<InitialState> {
    vec![InitialState::Data]
}

fn default_with_errors() -> bool {
    true // ¯\_(ツ)_/¯
}

#[derive(Deserialize)]
pub struct ParseError {
    pub code: String,
    pub line: usize,
    pub col: usize,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Test {
    pub description: String,
    pub input: String,
    pub output: Vec<Token>,

    #[serde(skip)]
    pub with_feedback: bool,

    #[serde(default = "default_with_errors")]
    pub with_errors: bool,

    #[serde(default = "default_initial_states")]
    pub initial_states: Vec<InitialState>,

    #[serde(default)]
    pub double_escaped: bool,

    #[serde(default)]
    pub last_start_tag: String,

    #[serde(default)]
    errors: Vec<ParseError>,
}

impl Test {
    pub fn get_expected_parse_errors(
        &self,
        token_ranges: Vec<TokenRange>,
    ) -> Result<ParseErrors, String> {
        let mut expected_errors = ParseErrors::new();

        let errors = self.errors.iter().filter_map(|err| {
            ERROR_CODES
                .iter()
                .filter(|&code| !SKIP_ERRORS.contains(&(self.description.as_str(), code)))
                .find(|&&code| code == err.code)
                .map(|&code| {
                    let pos = self.input
                        .split("\n")
                        .take(err.line - 1)
                        .fold(err.col - 1, |pos, s| pos + s.len());

                    // NOTE: use error code slice from the static array
                    // to avoid specifying lifetimes on owning structures.
                    (code, pos)
                })
        });

        'outer: for (code, pos) in errors {
            for &range in token_ranges.iter() {
                if range.contains(pos) {
                    expected_errors.insert((range, code));
                    continue 'outer;
                }
            }

            return Err(format!(
                "The following error doesn't fit into any token range: {:?}",
                (code, pos)
            ));
        }

        Ok(expected_errors)
    }
}

impl Unescape for Test {
    fn unescape(&mut self) -> Result<(), serde_json::error::Error> {
        if self.double_escaped {
            self.double_escaped = false;
            self.input.unescape()?;
            for token in &mut self.output {
                token.unescape()?;
            }
        }
        Ok(())
    }
}

pub fn get_tests() -> Vec<Test> {
    let mut tests = Vec::new();
    for file in read_tests!("html5lib-tests/tokenizer/*.test") {
        tests.extend(serde_json::from_reader::<_, Suite>(file).unwrap().tests);
    }
    for file in read_tests!("error-with-feedback-tests/*.test") {
        tests.extend(
            serde_json::from_reader::<_, Suite>(file)
                .unwrap()
                .tests
                .into_iter()
                .map(|mut test| {
                    test.with_feedback = true;
                    test
                }),
        );
    }
    for file in read_tests!("html5lib-tests/tree-construction/*.dat") {
        let mut inputs = Vec::new();
        let mut in_data = 0;
        for line in file.lines().map(|line| line.unwrap()) {
            if line == "#data" {
                in_data = 1;
            } else if line.starts_with('#') {
                in_data = 0;
            } else if in_data > 0 {
                if in_data > 1 {
                    let s: &mut String = inputs.last_mut().unwrap();
                    s.push('\n');
                    s.push_str(&line);
                } else {
                    inputs.push(line);
                }
                in_data += 1;
            }
        }
        tests.extend(inputs.into_iter().map(|input| {
            Test {
                description: input
                    .chars()
                    .flat_map(|c| c.escape_default())
                    .collect::<String>() + " (with feedback)",
                output: tokenize_with_tree_builder(&input),
                input,
                with_feedback: true,
                with_errors: false,
                initial_states: default_initial_states(),
                double_escaped: false,
                last_start_tag: String::new(),
                errors: Vec::default(),
            }
        }));
    }
    tests
}
