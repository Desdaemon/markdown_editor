use std::borrow::Cow;

use anyhow::Result;
use rust_md_core::events::{attrs_of, class_of, display_of, remap_table_headers, wrap_code_block};
use rust_md_core::parser::{parse_math, InlineElement};
use rust_md_core::pulldown_cmark::{CowStr, Event, Options, Parser, Tag};

#[cfg(target_arch = "wasm32")]
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

#[cfg_attr(target_arch = "wasm32", derive(serde::Serialize))]
#[derive(Debug)]
pub struct Element {
    /// Tags a la HTML tags.
    pub tag: String,
    /// Attributes.
    pub attributes: Option<Vec<Attribute>>,
    /// Children of this element.
    pub children: Option<Vec<Element>>,
}

#[cfg_attr(target_arch = "wasm32", derive(serde::Serialize))]
#[derive(Debug)]
pub struct Attribute {
    pub key: String,
    pub value: String,
}

impl Element {
    fn text(text: String) -> Self {
        Self {
            tag: text,
            attributes: None,
            children: None,
        }
    }
}

impl Attribute {
    fn new(key: String, value: String) -> Self {
        Attribute { key, value }
    }
}

fn borrow_children(this: &mut Option<Element>) -> Option<&mut Vec<Element>> {
    match this {
        Some(Element { children, .. }) => children.as_mut(),
        _ => None,
    }
}

fn borrow_text(this: &mut Option<Element>) -> Option<&mut String> {
    match this {
        Some(Element {
            children: Some(children),
            ..
        }) => match children.last_mut() {
            Some(Element {
                tag,
                children: None,
                attributes: None,
            }) => Some(tag),
            _ => None,
        },
        _ => None,
    }
}

fn transform_line_breaks<'a>(
    events: impl Iterator<Item = Event<'a>>,
) -> impl Iterator<Item = Event<'a>> {
    events
        .map(|evt| match evt {
            Event::SoftBreak => Event::Text(CowStr::Borrowed(" ")),
            Event::HardBreak => Event::Text(CowStr::Borrowed("\n\n")),
            _ => evt,
        })
        .scan(None, |acc, evt| match (acc.as_mut(), evt) {
            (None, Event::Text(text)) => {
                *acc = Some(text.to_string());
                // Returning a None here would short-circuit the iterator,
                // so we yield an empty list instead.
                Some(vec![])
            }
            (Some(acc), Event::Text(text)) => {
                acc.push_str(&text);
                Some(vec![])
            }
            (Some(_), evt) => Some(vec![Event::Text(CowStr::from(acc.take().unwrap())), evt]),
            (None, evt) => Some(vec![evt]),
        })
        .flatten()
}

fn replace_line_break_in_math(markdown: &str) -> String {
    let cap = markdown.len() + 2 * count_line_breaks(markdown);
    let (_, sections) = parse_math(markdown).unwrap();
    sections
        .into_iter()
        .map(|x| match x {
            InlineElement::MathText(x) => Cow::Owned(format!("${}$", x.replace(r"\\", r"\\\\"))),
            InlineElement::MathDisplay(x) => {
                Cow::Owned(format!("$${}$$", x.replace(r"\\", r"\\\\")))
            }
            InlineElement::Plain(x) => Cow::Borrowed(x),
        })
        .fold(String::with_capacity(cap), |mut acc, x| {
            acc.push_str(&x);
            acc
        })
}

fn count_line_breaks(markdown: &str) -> usize {
    markdown.matches("\\\\").count()
}

pub fn parse(markdown: String) -> Result<Option<Vec<Element>>> {
    let markdown = replace_line_break_in_math(&markdown);
    let parser = Parser::new_ext(&markdown, Options::all());
    let events = transform_line_breaks(remap_table_headers(wrap_code_block(parser)));

    let mut stack: Vec<Element> = vec![];
    let mut current: Option<Element> = Some(Element {
        children: Some(Vec::new()),
        tag: "template".to_owned(),
        attributes: None,
    });
    let mut memo = (vec![], 0);

    for event in events {
        match event {
            Event::Start(tag) => {
                if let Some(tag) = current.take() {
                    stack.push(tag);
                }
                let display = display_of(&tag);
                let class = class_of(&tag);
                let attr = attrs_of(tag, &mut memo);
                let attrs = {
                    let mut ret: Option<Vec<Attribute>> = None;
                    if let Some(class) = class {
                        ret = Some(vec![Attribute::new("class".to_owned(), class)]);
                    }
                    if let Some((key, val)) = attr {
                        let attr = Attribute::new(key.to_owned(), val);
                        if let Some(ret) = &mut ret {
                            ret.push(attr);
                        } else {
                            ret = Some(vec![attr]);
                        }
                    }
                    ret
                };
                current = Some(Element {
                    tag: display.to_owned(),
                    attributes: attrs,
                    children: Some(Vec::new()),
                });
            }
            Event::End(tag) => {
                if let Tag::Image(_, dest, _) = &tag {
                    let current = current.as_mut().unwrap();
                    let mut children = current.children.take().unwrap();
                    let alt = match children.pop() {
                        Some(last) => last.tag,
                        _ => dest.to_string(),
                    };
                    current.attributes = Some(vec![
                        Attribute::new("src".to_owned(), dest.to_string()),
                        Attribute::new("alt".to_owned(), alt),
                    ]);
                }
                let mut prev = stack.pop();
                borrow_children(&mut prev)
                    .unwrap()
                    .push(current.take().unwrap());
                current = prev;
            }
            Event::Text(text) => {
                let (_, segments) = parse_math(&text).unwrap();
                for segment in segments {
                    if let (InlineElement::Plain(plain), Some(last)) =
                        (&segment, borrow_text(&mut current))
                    {
                        last.push_str(plain);
                    } else {
                        let elm = match segment {
                            InlineElement::Plain(text) => Element::text(text.to_owned()),
                            InlineElement::MathText(text) => Element {
                                tag: "math".to_owned(),
                                attributes: Some(vec![Attribute::new(
                                    "display".to_owned(),
                                    "false".to_owned(),
                                )]),
                                children: Some(vec![Element::text(text.to_owned())]),
                            },
                            InlineElement::MathDisplay(text) => Element {
                                tag: "math".to_owned(),
                                attributes: Some(vec![Attribute::new(
                                    "display".to_owned(),
                                    "true".to_owned(),
                                )]),
                                children: Some(vec![Element::text(text.to_owned())]),
                            },
                        };
                        borrow_children(&mut current).unwrap().push(elm);
                    }
                }
            }
            Event::Code(code) => borrow_children(&mut current).unwrap().push(Element {
                tag: "code".to_owned(),
                attributes: None,
                children: Some(vec![Element::text(code.to_string())]),
            }),
            Event::TaskListMarker(checked) => {
                borrow_children(&mut current).unwrap().push(Element {
                    tag: "input".to_owned(),
                    attributes: Some(vec![
                        Attribute::new("type".to_owned(), "checkbox".to_owned()),
                        Attribute::new("disabled".to_owned(), "".to_owned()),
                        Attribute::new("checked".to_owned(), checked.to_string()),
                    ]),
                    children: None,
                })
            }
            Event::Rule => borrow_children(&mut current).unwrap().push(Element {
                tag: "hr".to_owned(),
                attributes: Some(vec![]),
                children: None,
            }),
            _ => {}
        }
    }

    Ok(current.take().map(|x| x.children.unwrap_or_else(Vec::new)))
}
