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

    bindgen::builder()
        .header("../c/tokenizer.h")
        .unstable_rust(true)
        .prepend_enum_name(false)
        .whitelisted_function("lhtml_.*")
        .whitelisted_type("lhtml_.*")
        .whitelisted_var("LHTML_.*")
        .constified_enum_module("lhtml_tag_type_t")
        .derive_debug(false)
        .generate()
        .expect("Unable to generate bindings")
        .write_to_file(out_path.join("bindings.rs"))
        .expect("Unable to write bindings");

    assert!(
        Command::new("make")
            .current_dir("../c")
            .arg("lib")
            .arg(format!("OUT_TARGET={}", out_dir))
            .status()
            .unwrap()
            .success(),
        "building LazyHTML failed"
    );

    println!("cargo:rustc-link-search=native={}", &out_dir);
    println!("cargo:rustc-link-lib=static=lhtml");

    for dep in IMPLICIT_DEPS {
        for entry in glob(dep).unwrap() {
            println!("cargo:rerun-if-changed={}", entry.unwrap().display());
        }
    }
}
