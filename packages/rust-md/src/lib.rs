pub mod log;
mod utils;
pub mod vdom_parser;
pub mod vnode;

use vdom_parser::parse_markdown_to_vdom;
use wasm_bindgen::prelude::*;

// When the `wee_alloc` feature is enabled, use `wee_alloc` as the global
// allocator.
#[cfg(feature = "wee_alloc")]
#[global_allocator]
static ALLOC: wee_alloc::WeeAlloc = wee_alloc::WeeAlloc::INIT;

use pulldown_cmark::{html::push_html, Options, Parser};
use serde::Deserialize;

#[wasm_bindgen(start)]
pub fn run() {
    utils::set_panic_hook();
}

#[wasm_bindgen]
extern "C" {
    #[wasm_bindgen(js_namespace = console)]
    fn log(s: &str);
}

#[derive(Deserialize)]
struct MarkdownOptions {
    pub tables: Option<bool>,
    pub footnotes: Option<bool>,
    pub tasklist: Option<bool>,
    pub strikethrough: Option<bool>,
    pub smartypants: Option<bool>,
}

#[wasm_bindgen(typescript_custom_section)]
const TYPESCRIPT: &'static str = "
interface MarkdownOptions {
    tables?: boolean
    footnotes?: boolean
    tasklist?: boolean
    strikethrough?: boolean
    smartypants?: boolean
}";

#[wasm_bindgen]
extern "C" {
    #[wasm_bindgen(typescript_type = "MarkdownOptions")]
    pub type IMarkdownOptions;
}

impl Default for MarkdownOptions {
    fn default() -> Self {
        MarkdownOptions {
            tables: Some(true),
            footnotes: Some(true),
            tasklist: Some(true),
            strikethrough: Some(true),
            smartypants: Some(true),
        }
    }
}

fn resolve_options(opts: Option<MarkdownOptions>) -> Options {
    match opts {
        None => Options::all(),
        Some(md_opts) => {
            let mut opts = Options::empty();
            let MarkdownOptions {
                tables,
                footnotes,
                tasklist,
                strikethrough,
                smartypants,
            } = md_opts;
            if let Some(true) = tables {
                opts.insert(Options::ENABLE_TABLES);
            }
            if let Some(true) = footnotes {
                opts.insert(Options::ENABLE_FOOTNOTES);
            }
            if let Some(true) = tasklist {
                opts.insert(Options::ENABLE_TASKLISTS);
            }
            if let Some(true) = strikethrough {
                opts.insert(Options::ENABLE_STRIKETHROUGH);
            }
            if let Some(true) = smartypants {
                opts.insert(Options::ENABLE_SMART_PUNCTUATION);
            }
            opts
        }
    }
}

#[wasm_bindgen]
pub fn parse(markdown: &str, options: Option<IMarkdownOptions>) -> String {
    let opts = options.map(|e| JsValue::into_serde::<MarkdownOptions>(&e).unwrap());
    let opts = resolve_options(opts);
    let parser = Parser::new_ext(markdown, opts);
    let mut buf = String::with_capacity(markdown.len());
    push_html(&mut buf, parser);
    format!("<div>{}</div>", buf)
}

#[wasm_bindgen]
pub fn parse_vdom(markdown: &str, options: Option<IMarkdownOptions>) -> JsValue {
    let opts = options.map(|e| JsValue::into_serde::<MarkdownOptions>(&e).unwrap());
    let opts = resolve_options(opts);
    let vnode = parse_markdown_to_vdom(markdown, opts);
    JsValue::from_serde(&vnode).unwrap()
}
