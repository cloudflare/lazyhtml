extern crate bindgen;
extern crate glob;

use std::env;
use std::path::PathBuf;
use std::process::Command;
use glob::glob;

const IMPLICIT_DEPS: &[&str] = &[
    "../../c/tokenizer-states.rl",
    "../../c/actions.rl",
    "../../c/field-names.h",
    "../../c/tag-types.h",
    "../../c/tokenizer.*",
    "../../c/parser-feedback.*",
    "../../c/serializer.*",
    "../../syntax/*.rl",
];

fn main() {
    let out_dir = env::var("OUT_DIR").unwrap();
    let out_path = PathBuf::from(&out_dir);

    assert!(
        Command::new("make")
            .current_dir("../../c")
            .arg("lib")
            .arg(format!("OUT_TARGET={}", out_dir))
            .arg("CFLAGS=-fPIC")
            .status()
            .unwrap()
            .success(),
        "building LazyHTML failed"
    );

    bindgen::builder()
        .clang_arg("-U__clang__")
        .header("wrapper.h")
        .rust_target(bindgen::RustTarget::Stable_1_19)
        .prepend_enum_name(false)
        .whitelist_function("lhtml_.*")
        .whitelist_type("lhtml_.*")
        .whitelist_var("LHTML_.*|html_en_.*")
        .constified_enum_module("lhtml_tag_type_t")
        .rustified_enum("lhtml_token_type_t|lhtml_ns_t")
        .derive_debug(false)
        .generate()
        .expect("Unable to generate bindings")
        .write_to_file(out_path.join("bindings.rs"))
        .expect("Unable to write bindings");

    println!("cargo:rustc-link-search=native={}", &out_dir);
    println!("cargo:rustc-link-lib=static=lhtml");

    for dep in IMPLICIT_DEPS {
        for entry in glob(dep).unwrap() {
            println!("cargo:rerun-if-changed={}", entry.unwrap().display());
        }
    }
}
