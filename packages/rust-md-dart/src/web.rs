use wasm_bindgen::prelude::*;

use crate::api;

#[wasm_bindgen(typescript_custom_section)]
const TS: &str = "
interface Element {
    tag: string
    attributes?: Attribute[]
    children?: Element[]
}

interface Attribute {
    key: string
    value: string
}";

#[wasm_bindgen]
extern "C" {
    #[wasm_bindgen(typescript_type = "Element[] | null")]
    pub type Element;
}

#[wasm_bindgen]
pub fn parse(markdown: String) -> Element {
    JsValue::from_serde(&api::parse(markdown).unwrap())
        .unwrap()
        .into()
}
