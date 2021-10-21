use anyhow::Result;
use pulldown_cmark::{Event, Options, Parser};
use rust_md::events::{remap_table_headers, wrap_code_block};
use rust_md::markdown::{attrs_of, class_of, display_of};

#[derive(Debug)]
pub struct Element {
    pub tag: String,
    pub attributes: Option<Vec<Attribute>>,
    /// Some comments here?
    pub children: Option<Vec<Element>>,
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

#[derive(Debug)]
pub struct Attribute {
    pub key: String,
    pub value: String,
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

pub fn parse(markdown: String) -> Result<Vec<Element>> {
    let parser = Parser::new_ext(&markdown, Options::all());
    let events = remap_table_headers(wrap_code_block(parser));

    let mut stack: Vec<Element> = vec![Element {
        children: Some(Vec::new()),
        tag: "template".to_owned(),
        attributes: None,
    }];
    let mut current: Option<Element> = None;

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
            Event::End(_) => {
                let mut prev = stack.pop();
                borrow_children(&mut prev)
                    .unwrap()
                    .push(current.take().unwrap());
                current = Some(prev.unwrap());
            }
            Event::Text(text) => {
                if let Some(last) = borrow_text(&mut current) {
                    last.push_str(&text);
                } else {
                    borrow_children(&mut current)
                        .unwrap()
                        .push(Element::text(text.to_string()));
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
            Event::SoftBreak => {
                if let Some(last) = borrow_text(&mut current) {
                    last.push('\n');
                } else {
                    borrow_children(&mut current)
                        .unwrap()
                        .push(Element::text("\n".to_owned()));
                }
            }
            Event::HardBreak => {
                if let Some(last) = borrow_text(&mut current) {
                    last.push_str("\n\n");
                } else {
                    borrow_children(&mut current)
                        .unwrap()
                        .push(Element::text("\n\n".to_owned()));
                }
            }
            Event::Rule => borrow_children(&mut current).unwrap().push(Element {
                tag: "hr".to_owned(),
                attributes: Some(vec![]),
                children: None,
            }),
            other => {
                todo!("{:?}", other)
            }
        }
    }

    Ok(current.take().unwrap().children.unwrap())
}

#[cfg(test)]
mod tests {

    use super::parse;

    const SOURCE: &str = include_str!("../../markdown_reference.md");

    #[test]
    fn sanity_check() {
        let doc = parse(SOURCE.to_owned()).unwrap();
        dbg!(core::mem::size_of_val(&*doc));
    }
}
