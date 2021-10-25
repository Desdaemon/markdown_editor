mod log;
pub mod markdown;
pub mod utils;
pub mod vnode;
pub mod xml;

use js_sys::Function;
use markdown::markdown_to_vdom;
use rust_md_core::events::{attrs_of, class_of, display_of, remap_table_headers, wrap_code_block};
use serde_json::json;
use wasm_bindgen::prelude::*;

// When the `wee_alloc` feature is enabled, use `wee_alloc` as the global
// allocator.
#[cfg(feature = "wee_alloc")]
#[global_allocator]
static ALLOC: wee_alloc::WeeAlloc = wee_alloc::WeeAlloc::INIT;

use rust_md_core::pulldown_cmark::{html::push_html, Event, Options, Parser};
use serde::Deserialize;

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
export function markdown_events(
    markdown: string,
    options: MarkdownOptions | undefined,
    callback: (tag: string, config: any) => void
): void
export interface MarkdownOptions {
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

fn resolve_options(opts: Option<IMarkdownOptions>) -> Options {
    let opts = opts.map(|e| {
        #[cfg(not(feature = "serde-wasm-bindgen"))]
        return JsValue::into_serde::<MarkdownOptions>(&e).unwrap();

        #[cfg(feature = "serde-wasm-bindgen")]
        return serde_wasm_bindgen::from_value::<MarkdownOptions>(e.into()).unwrap();
    });

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
    let opts = resolve_options(options);
    let parser = Parser::new_ext(markdown, opts);
    let mut buf = String::with_capacity(markdown.len());
    push_html(&mut buf, parser);
    format!("<div>{}</div>", buf)
}

#[wasm_bindgen]
pub fn parse_vdom(markdown: &str, options: Option<IMarkdownOptions>) -> JsValue {
    let opts = resolve_options(options);
    let vnode = markdown_to_vdom(markdown, opts);

    #[cfg(not(feature = "serde-wasm-bindgen"))]
    return JsValue::from_serde(&vnode).unwrap();

    #[cfg(feature = "serde-wasm-bindgen")]
    return serde_wasm_bindgen::to_value(&vnode).unwrap();
}

#[wasm_bindgen]
pub fn markdown_events(
    markdown: &str,
    options: Option<IMarkdownOptions>,
    callback: js_sys::Function,
) {
    let opts = resolve_options(options);
    let parser = Parser::new_ext(markdown, opts);
    let events = remap_table_headers(parser);
    let events = wrap_code_block(events);
    let mut memo = (vec![], 0usize);
    let null = JsValue::null();
    for event in events {
        match event {
            Event::Start(tag) => {
                let name = display_of(&tag);
                let class = class_of(&tag);
                let attrs = attrs_of(tag, &mut memo);
                let props = JsValue::from_serde(&json! {{
                    "class": class,
                    "attrs": attrs
                }})
                .unwrap();
                let _ = Function::call2(&callback, &null, &JsValue::from_str(name), &props);
            }
            Event::End(tag) => {
                let name = display_of(&tag);
                let _ = Function::call1(&callback, &null, &JsValue::from_str(name));
            }
            Event::Text(contents) => {
                let _ = Function::call2(
                    &callback,
                    &null,
                    &JsValue::from_str("text"),
                    &JsValue::from_str(&contents),
                );
            }
            Event::Code(contents) => {
                let _ = Function::call2(
                    &callback,
                    &null,
                    &JsValue::from_str("code"),
                    &JsValue::from_str(&contents),
                );
            }
            Event::Html(html) => {
                let _ = Function::call2(
                    &callback,
                    &null,
                    &JsValue::from_str("html"),
                    &JsValue::from_str(&html),
                );
            }
            Event::SoftBreak => {
                let _ = Function::call2(
                    &callback,
                    &null,
                    &JsValue::from_str("text"),
                    &JsValue::from_str("\n"),
                );
            }
            Event::HardBreak => {
                let _ = Function::call1(&callback, &null, &JsValue::from_str("br"));
            }
            Event::Rule => {
                let _ = Function::call1(&callback, &null, &JsValue::from_str("hr"));
            }
            Event::TaskListMarker(checked) => {
                let _ = Function::call2(
                    &callback,
                    &null,
                    &JsValue::from_str("task"),
                    &JsValue::from_bool(checked),
                );
            }
            _ => {}
        }
    }
}
