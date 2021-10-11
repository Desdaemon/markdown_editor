use crate::vnode::*;
use pulldown_cmark::{Options, Parser, Tag};
use serde_json::json;
// use quick_xml::events::attributes::Attributes;
// use quick_xml::events::Event;
// use quick_xml::Reader;

#[inline]
fn borrow_children(opt: &mut Option<VNode>) -> Option<&mut Vec<VNode>> {
    match opt {
        Some(VNode { children, .. }) => children.as_mut(),
        _ => None,
    }
}

fn borrow_last_text(opt: &mut Option<VNode>) -> Option<&mut String> {
    match opt {
        Some(VNode {
            children: Some(vec),
            ..
        }) => match vec.last_mut() {
            Some(VNode { text, .. }) => text.as_mut(),
            _ => None,
        },
        _ => None,
    }
}

fn hoist_last_text(opt: &mut Option<VNode>) {
    match opt {
        Some(node) => match &node.children {
            Some(vec) if vec.len() == 1 => match vec.last() {
                Some(VNode { text, .. }) if text.is_some() => {
                    let text = node.children.take().unwrap().pop().unwrap().text;
                    node.text = text;
                }
                _ => {}
            },
            _ => {}
        },
        _ => {}
    }
}

fn tag_to_display(tag: &Tag, in_header: &mut bool) -> &'static str {
    match tag {
        pulldown_cmark::Tag::Paragraph => "p",
        pulldown_cmark::Tag::Heading(lvl) => match lvl {
            1 => "h1",
            2 => "h2",
            3 => "h3",
            4 => "h4",
            5 => "h5",
            6 => "h6",
            _ => unreachable!(),
        },
        pulldown_cmark::Tag::BlockQuote => "blockquote",
        pulldown_cmark::Tag::CodeBlock(_) => "pre",
        pulldown_cmark::Tag::List(Some(_)) => "ol",
        pulldown_cmark::Tag::List(None) => "ul",
        pulldown_cmark::Tag::Item => "li",
        // pulldown_cmark::Tag::FootnoteDefinition(_) => todo!(),
        pulldown_cmark::Tag::Table(_) => "table",
        pulldown_cmark::Tag::TableHead => {
            *in_header = true;
            "tr"
        }
        pulldown_cmark::Tag::TableRow => "tr",
        pulldown_cmark::Tag::TableCell => {
            if *in_header {
                "th"
            } else {
                "td"
            }
        }
        pulldown_cmark::Tag::Emphasis => "em",
        pulldown_cmark::Tag::Strong => "strong",
        pulldown_cmark::Tag::Strikethrough => "s",
        pulldown_cmark::Tag::Link(_, _, _) => "a",
        pulldown_cmark::Tag::Image(_, _, _) => "img",
        _ => "!", // comment
    }
}

pub fn parse_markdown_to_vdom(markdown: &str, options: Options) -> Option<VNode> {
    let parser = Parser::new_ext(markdown, options);
    let mut node_stack: Vec<VNode> = vec![];
    let mut current_node: Option<VNode> = Some(VNode {
        sel: Some("div".to_owned()),
        children: Some(vec![]),
        ..Default::default()
    });
    let mut in_header = false;

    for event in parser {
        match event {
            pulldown_cmark::Event::Start(tag) => {
                if let Some(cur) = current_node.take() {
                    node_stack.push(cur);
                }
                let name = tag_to_display(&tag, &mut in_header);
                let class = match &tag {
                    pulldown_cmark::Tag::CodeBlock(pulldown_cmark::CodeBlockKind::Fenced(lang)) => {
                        Some(lang)
                    }
                    _ => None,
                };
                let attrs = match &tag {
                    pulldown_cmark::Tag::Link(typ, dest, _title) => {
                        let href: String = match typ {
                            pulldown_cmark::LinkType::Email => format!("mailto:{}", &dest),
                            _ => dest.to_string(),
                        };
                        Some(json! {{ "href": href }})
                    }
                    _ => None,
                };
                current_node = Some(VNode {
                    sel: Some(
                        class
                            .map(|e| format!("{}.language-{}", &name, e))
                            .unwrap_or(name.to_owned()),
                    ),
                    data: Some(VNodeData {
                        attrs,
                        ..Default::default()
                    }),
                    children: Some(vec![]),
                    ..Default::default()
                });
            }
            pulldown_cmark::Event::End(tag) => {
                if let pulldown_cmark::Tag::TableHead = &tag {
                    in_header = false;
                }
                if let pulldown_cmark::Tag::Image(_, dest, _) = &tag {
                    let current_node = current_node.as_mut().unwrap();
                    let children = current_node.children.take().unwrap();
                    let alt = match children.last() {
                        Some(last) => last.text.as_deref().unwrap_or(&dest),
                        _ => &dest,
                    };
                    let attrs = Some(json! {{ "src": dest.to_string(), "alt": alt }});
                    if let Some(data) = current_node.data.as_mut() {
                        data.attrs = attrs;
                    }
                }
                if !node_stack.is_empty() {
                    let done = current_node.take().unwrap();
                    current_node = node_stack.pop();
                    if let Some(e) = borrow_children(&mut current_node) {
                        e.push(done)
                    }
                }
                hoist_last_text(&mut current_node);
            }
            pulldown_cmark::Event::Text(text) => {
                if let Some(e) = borrow_last_text(&mut current_node) {
                    e.push_str(&text)
                } else if let Some(e) = borrow_children(&mut current_node) {
                    e.push(VNode::text_node(text.to_string()))
                }
            }
            pulldown_cmark::Event::Code(text) => {
                if let Some(e) = borrow_children(&mut current_node) {
                    let code_node = VNode {
                        sel: Some("code".to_owned()),
                        // it's put in children to separate it from merging
                        // with other segments.
                        children: Some(vec![VNode::text_node(text.to_string())]),
                        data: Some(Default::default()),
                        ..Default::default()
                    };
                    e.push(code_node);
                }
            }
            // pulldown_cmark::Event::Html(xml) => {
            // if let Some(vnode) = parse_xml_to_vdom(&xml) {
            // borrow_children(&mut current_node).map(|e| e.push(vnode));
            // }
            // }
            // pulldown_cmark::Event::FootnoteReference(_) => todo!(),
            pulldown_cmark::Event::SoftBreak => {
                if let Some(e) = borrow_last_text(&mut current_node) {
                    e.push(' ')
                } else if let Some(e) = borrow_children(&mut current_node) {
                    e.push(VNode::text_node(" ".to_owned()))
                }
            }
            pulldown_cmark::Event::HardBreak => {
                if let Some(e) = borrow_children(&mut current_node) {
                    e.push(VNode {
                        sel: Some("br".to_owned()),
                        data: Some(Default::default()),
                        ..Default::default()
                    });
                }
            }
            pulldown_cmark::Event::Rule => {
                if let Some(e) = borrow_children(&mut current_node) {
                    e.push(VNode {
                        sel: Some("hr".to_owned()),
                        ..Default::default()
                    })
                }
            }
            pulldown_cmark::Event::TaskListMarker(checked) => {
                let current_node = current_node.as_mut().unwrap();
                current_node
                    .sel
                    .as_mut()
                    .unwrap()
                    .push_str(".task-list-item");
                current_node.children.as_mut().unwrap().push(VNode {
                    sel: Some("input.task-list-item-checkbox".to_owned()),
                    data: Some(VNodeData {
                        attrs: Some(json! ({
                            "type": "checkbox",
                            "disabled": "",
                            "checked": checked
                        })),
                        ..Default::default()
                    }),
                    ..Default::default()
                });
            }
            _ => {}
        }
    }

    current_node.take()
}

#[cfg(test)]
mod tests {
    // use crate::parse;
    // use crate::vdom_parser::parse_xml_to_vdom;
    use pulldown_cmark::{Options, Parser};

    use super::parse_markdown_to_vdom;

    // const SOURCE: &'static str = include_str!("markdown_reference.md");
    const SOURCE: &'static str = "
$$
asd \\
sdf
$$";

    #[test]
    fn sanity_check() {
        let node = parse_markdown_to_vdom(SOURCE, Options::all());
        dbg!(node);
    }

    // #[test]
    // fn markdown_to_xml_to_vdom() {
    // let xml = parse(SOURCE, None);
    // let vdom = parse_xml_to_vdom(&xml);
    // println!("{:?}", vdom);
    // }

    #[test]
    fn basic() {
        let parser = Parser::new_ext(SOURCE, Options::all());
        for event in parser {
            dbg!(event);
        }
    }
}

// pub fn parse_xml_to_vdom(xml: &str) -> Option<VNode> {
// let mut reader = Reader::from_str(xml);
// let mut buf = Vec::new();
// let mut node_stack: Vec<VNode> = Vec::new();
// let mut current_node: Option<VNode> = None;
// loop {
// match &reader.read_event(&mut buf) {
// Ok(Event::Eof) => break,
// Ok(Event::Start(start)) => {
// if let Some(cur) = current_node.take() {
// node_stack.push(cur);
// }
// let tag = String::from_utf8_lossy(start.name());
// let attrs = parse_attributes(start.attributes());
// let id = attrs
// .get("id")
// .map(|e| format!("#{}", e))
// .unwrap_or_else(String::new);
// let classes = attrs
// .get("class")
// .map(|e| format!(".{}", e.split(' ').collect::<Box<_>>().join(".")))
// .unwrap_or_else(String::new);
// current_node = Some(VNode {
// sel: Some([tag.to_string(), id, classes].join("")),
// data: Some(VNodeData {
// attrs: Some(serde_json::to_value(attrs).unwrap()),
// ..Default::default()
// }),
// children: Some(vec![]),
// ..Default::default()
// });
// }
// Ok(Event::End(_)) => {
// if !node_stack.is_empty() {
// let done = current_node.take().unwrap();
// current_node = node_stack.pop();
// borrow_children(&mut current_node).map(|e| e.push(done));
// }
// }
// Ok(Event::Text(text)) => {
// borrow_children(&mut current_node).map(|e| {
// e.push(VNode::text_node(
// String::from_utf8_lossy(text.escaped()).to_string(),
// ));
// });
// }
// Ok(Event::Empty(elm)) => {
// borrow_children(&mut current_node).map(|e| {
// let tag = String::from_utf8_lossy(elm.name());
// let attrs = parse_attributes(elm.attributes());
// let node = VNode {
// sel: Some(tag.to_string()),
// data: Some(VNodeData {
// attrs: Some(serde_json::to_value(attrs).unwrap()),
// ..Default::default()
// }),
// ..Default::default()
// };
// e.push(node);
// });
// }
// // Err(e) => return Err(JsValue::from_str(&format!("{}", e))),
// Err(_) => return None,
// _ => {}
// }
// buf.clear();
// }

// // Ok(JsValue::from_serde(&current_node.take()).unwrap())
// current_node.take()
// }
