use serde_json;
use glob;
use std::io::{BufRead, BufReader};
use std::fs::File;
use unescape::Unescape;
use lazyhtml;
use token::Token;
use feedback_tokens::tokenize_with_tree_builder;

#[derive(Deserialize)]
struct Suite {
    #[serde(default)]
    pub tests: Vec<Test>,
}

macro_rules! read_tests {
    ($path: expr) => (
        glob::glob(concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/../html5lib-tests/",
            $path
        )).unwrap()
        .map(|path| BufReader::new(File::open(path.unwrap()).unwrap()))
    )
}

#[derive(Clone, Copy, Deserialize, Debug)]
#[repr(i32)]
pub enum InitialState {
    #[serde(rename = "Data state")] Data = lazyhtml::html_en_Data,
    #[serde(rename = "PLAINTEXT state")] PlainText = lazyhtml::html_en_PlainText,
    #[serde(rename = "RCDATA state")] RCData = lazyhtml::html_en_RCData,
    #[serde(rename = "RAWTEXT state")] RawText = lazyhtml::html_en_RawText,
    #[serde(rename = "Script data state")] ScriptData = lazyhtml::html_en_ScriptData,
    #[serde(rename = "CDATA section state")] CDataSection = lazyhtml::html_en_CDataSection,
}

fn default_initial_states() -> Vec<InitialState> {
    vec![InitialState::Data]
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Test {
    pub description: String,
    pub input: String,
    pub output: Vec<Token>,

    #[serde(skip)]
    pub with_feedback: bool,

    #[serde(default = "default_initial_states")]
    pub initial_states: Vec<InitialState>,

    #[serde(default)]
    pub double_escaped: bool,

    #[serde(default)]
    pub last_start_tag: String,
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
    read_tests!("tokenizer/*.test")
        .flat_map(|file| serde_json::from_reader::<_, Suite>(file).unwrap().tests)
        .chain(
            read_tests!("tree-construction/*.dat")
                .flat_map(|file| {
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
                    inputs
                })
                .map(|input| Test {
                    description: input
                        .chars()
                        .flat_map(|c| c.escape_default())
                        .collect::<String>() + " (with feedback)",
                    output: tokenize_with_tree_builder(&input),
                    input,
                    with_feedback: true,
                    initial_states: default_initial_states(),
                    double_escaped: false,
                    last_start_tag: String::new(),
                }),
        )
        .collect()
}
