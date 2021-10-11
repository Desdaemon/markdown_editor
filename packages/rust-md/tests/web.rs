//! Test suite for the Web and headless browsers.

#![cfg(target_arch = "wasm32")]

extern crate wasm_bindgen_test;
use wasm_bindgen_test::*;

use rust_md::log::log;
use rust_md::vdom_parser::parse_xml_to_vdom;

wasm_bindgen_test_configure!(run_in_browser);

#[wasm_bindgen_test]
fn pass() {
    assert_eq!(1 + 1, 2);
}

#[wasm_bindgen_test]
fn sanity_check() {
    const TEST: &'static str = r#"
<div>
    <foo attr="3" power>
        <img src="somewhere"/>
    </foo>
</div>
"#;
    let dom = parse_xml_to_vdom(TEST).unwrap();
    log(&format!("{:?}", dom));
}
