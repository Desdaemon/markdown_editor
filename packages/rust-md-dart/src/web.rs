use wasm_bindgen::prelude::*;

use crate::api;

#[wasm_bindgen]
pub fn parse(markdown: String) -> JsValue {
    JsValue::from_serde(&api::parse(markdown).unwrap()).unwrap()
}
