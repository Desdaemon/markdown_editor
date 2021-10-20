use allo_isolate::ZeroCopyBuffer;
use anyhow::Result;
use pulldown_cmark::{Alignment, Event, Options, Parser};
use rust_md::events;
use rust_md::markdown::{attrs_of, display_of};

fn borrow_text(elm: &mut Option<Element>) -> Option<&mut String> {
    match elm {
        Some(Element {
            text,
            children: None,
            ..
        }) => Some(text),
        _ => None,
    }
}

#[inline]
fn borrow_children(elm: &mut Option<Element>) -> Option<&mut Vec<Element>> {
    match elm {
        Some(Element { children, .. }) => children.as_mut(),
        _ => None,
    }
}

#[derive(Debug, Default)]
pub struct Attribute {
    pub key: String,
    pub val: String,
}

#[derive(Default, Debug)]
pub struct Element {
    pub tag: String,
    pub children: Option<Vec<Element>>,
    pub attributes: Option<Attribute>,
    pub text: String,
}

impl Element {
    #[inline]
    fn text(text: String) -> Self {
        Self {
            text,
            ..Default::default()
        }
    }
}

pub fn greet(text: Option<String>) -> Result<String> {
    dbg!(&text);
    Ok("Hello ".to_owned() + &text.unwrap_or("there".to_owned()))
}

pub fn markdown_to_nodes(markdown: String) -> Result<Option<Element>> {
    let parser = Parser::new_ext(&markdown, Options::all());
    let events = events::remap_table_headers(parser);
    let events = events::wrap_code_block(events);

    let mut current_node: Option<Element> = None;
    let mut memo = (Vec::<Alignment>::new(), 0usize);
    let mut node_stack = vec![Element {
        tag: "div".to_owned(),
        ..Default::default()
    }];

    for event in events {
        match event {
            Event::Start(tag) => {
                if let Some(e) = current_node.take() {
                    node_stack.push(e);
                }
                let name = display_of(&tag);
                let attr = attrs_of(tag, &mut memo).map(|(key, val)| Attribute {
                    key: key.to_owned(),
                    val,
                });
                current_node = Some(Element {
                    tag: name.to_owned(),
                    attributes: attr,
                    children: Some(vec![]),
                    ..Default::default()
                })
            }
            Event::End(_) => {
                if let Some(mut e) = node_stack.pop() {
                    let current = current_node.take().unwrap();
                    e.children.as_mut().unwrap().push(current);
                    current_node = Some(e);
                }
            }
            Event::Text(contents) => {
                if let Some(e) = borrow_text(&mut current_node) {
                    e.push_str(&contents)
                } else if let Some(e) = borrow_children(&mut current_node) {
                    e.push(Element::text(contents.to_string()))
                }
            }
            Event::Code(code) => {
                if let Some(e) = borrow_children(&mut current_node) {
                    e.push(Element {
                        tag: "code".to_owned(),
                        children: Some(vec![Element {
                            text: code.to_string(),
                            ..Default::default()
                        }]),
                        ..Default::default()
                    })
                }
            }
            Event::SoftBreak => {
                if let Some(e) = borrow_text(&mut current_node) {
                    e.push('\n');
                } else if let Some(e) = borrow_children(&mut current_node) {
                    e.push(Element::text("\n".to_owned()))
                }
            }
            Event::HardBreak => {
                if let Some(e) = borrow_children(&mut current_node) {
                    e.push(Element {
                        tag: "br".to_owned(),
                        ..Default::default()
                    })
                }
            }
            Event::Rule => {
                if let Some(e) = borrow_children(&mut current_node) {
                    e.push(Element {
                        tag: "hr".to_owned(),
                        ..Default::default()
                    })
                }
            }
            Event::TaskListMarker(checked) => {
                if let Some(e) = borrow_children(&mut current_node) {
                    e.push(Element {
                        tag: "input".to_owned(),
                        attributes: Some(Attribute {
                            key: "checked".to_owned(),
                            val: checked.to_string(),
                        }),
                        ..Default::default()
                    })
                }
            }
            _ => {}
        }
    }
    Ok(current_node)
}

#[cfg(test)]
mod tests {
    // use crate::Element;
    // use std::mem::size_of;
    // use crate::markdown_to_nodes;

    const SOURCE: &'static str = include_str!("../../markdown_reference.md");

    use crate::entry::markdown_to_nodes;
    use crate::entry::Element;

    #[test]
    fn sanity_test() {
        let node = markdown_to_nodes(SOURCE.to_owned());
        println!("{:#?}", node);
    }

    #[test]
    fn stuff() {
        dbg!(core::mem::size_of::<Element>());
        // dbg!((size_of::<Node>(), size_of::<Element>()));
        // dbg!((
        // size_of::<&str>(),
        // size_of::<*const i8>(),
        // size_of::<*mut i8>(),
        // ));
    }
}

pub struct OptionGallery {
    // primitives
    pub int8: Option<i8>,
    pub int32: Option<i32>,
    pub int64: Option<i64>,
    pub rational: Option<f64>,
    pub boolean: Option<bool>,
    // // delegates
    // pub string: Option<String>,
    // pub buffer: Option<ZeroCopyBuffer<Vec<u8>>>,

    // // primitive lists, missing i32 and bool
    // pub uint8_list: Option<Vec<u8>>,
    // pub int8_list: Option<Vec<i8>>,
    // pub int64_list: Option<Vec<i64>>,
    // pub rational_list: Option<Vec<f64>>,
    // Not supported yet.
    // pub i32_list: Option<Vec<i32>>,
    // pub bool_list: Option<Vec<bool>>,
    // pub boxed_prim: Option<Box<i32>>,
    // pub opt: Option<Attribute>,
    // pub boxed: Box<Attribute>,
}

pub fn passthrough(opt: Option<OptionGallery>) -> Result<Option<OptionGallery>> {
    Ok(None)
}
