use wasm_bindgen::prelude::*;

use crate::api;

#[wasm_bindgen]
extern "C" {
    #[wasm_bindgen(typescript_type = "Element[] | null")]
    pub type Elements;
}

#[wasm_bindgen]
pub fn parse(markdown: String) -> Elements {
    JsValue::from_serde(&api::parse(markdown).unwrap())
        .unwrap()
        .into()
}
