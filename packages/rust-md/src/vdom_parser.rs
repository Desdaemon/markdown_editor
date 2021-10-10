use std::borrow::BorrowMut;
use std::collections::HashMap;

use crate::vnode::*;
use pulldown_cmark::{Options, Parser, Tag};
// use quick_xml::events::attributes::Attributes;
// use quick_xml::events::Event;
// use quick_xml::Reader;

// fn parse_attributes(attrs: Attributes) -> HashMap<String, String> {
// attrs
// .filter_map(Result::ok)
// .map(|a| {
// (
// String::from_utf8_lossy(a.key).to_string(),
// String::from_utf8_lossy(&a.value).to_string(),
// )
// })
// .collect()
// }

#[inline]
fn borrow_children(node: &mut Option<VNode>) -> Option<&mut Vec<VNode>> {
    match node {
        Some(cur) => cur.children.borrow_mut().as_mut(),
        _ => None,
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

fn tag_to_display(tag: &Tag) -> &'static str {
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
        pulldown_cmark::Tag::TableHead => "th",
        pulldown_cmark::Tag::TableRow => "tr",
        pulldown_cmark::Tag::TableCell => "td",
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

    for event in parser {
        match event {
            pulldown_cmark::Event::Start(tag) => {
                if let Some(cur) = current_node.take() {
                    node_stack.push(cur);
                }
                let name = tag_to_display(&tag);
                let mut attrs: Option<HashMap<String, bool>> = None;
                if let pulldown_cmark::Tag::CodeBlock(pulldown_cmark::CodeBlockKind::Fenced(lang)) =
                    tag
                {
                    let mut map = HashMap::new();
                    map.entry(format!("language-{}", &lang)).or_insert(true);
                    attrs = Some(map);
                }
                current_node = Some(VNode {
                    sel: Some(name.to_owned()),
                    data: Some(VNodeData {
                        attrs: attrs.map(|e| serde_json::to_value(e).unwrap()),
                        ..Default::default()
                    }),
                    children: Some(vec![]),
                    ..Default::default()
                });
            }
            pulldown_cmark::Event::End(_) => {
                if !node_stack.is_empty() {
                    let done = current_node.take().unwrap();
                    current_node = node_stack.pop();
                    borrow_children(&mut current_node).map(|e| e.push(done));
                }
            }
            pulldown_cmark::Event::Text(text) => {
                borrow_children(&mut current_node)
                    .map(|e| e.push(VNode::text_node(text.to_string())));
            }
            pulldown_cmark::Event::Code(text) => {
                borrow_children(&mut current_node).map(|e| {
                    let pre_node = VNode {
                        sel: Some("code".to_owned()),
                        data: Some(Default::default()),
                        children: Some(vec![VNode::text_node(text.to_string())]),
                        ..Default::default()
                    };
                    e.push(pre_node);
                });
            }
            // pulldown_cmark::Event::Html(xml) => {
            // if let Some(vnode) = parse_xml_to_vdom(&xml) {
            // borrow_children(&mut current_node).map(|e| e.push(vnode));
            // }
            // }
            // pulldown_cmark::Event::FootnoteReference(_) => todo!(),
            pulldown_cmark::Event::SoftBreak | pulldown_cmark::Event::HardBreak => {
                borrow_children(&mut current_node)
                    .map(|e| e.push(VNode::text_node("\n".to_owned())));
            }
            pulldown_cmark::Event::Rule => {
                borrow_children(&mut current_node).map(|e| {
                    e.push(VNode {
                        sel: Some("hr".to_owned()),
                        ..Default::default()
                    })
                });
            }
            pulldown_cmark::Event::TaskListMarker(checked) => {
                borrow_children(&mut current_node).map(|e| {
                    let mut attrs = HashMap::new();
                    attrs
                        .entry("checked".to_owned())
                        .or_insert(checked.to_string());
                    attrs
                        .entry("disabled".to_owned())
                        .or_insert("false".to_owned());
                    let node = VNode {
                        sel: Some("checkbox".to_owned()),
                        data: Some(VNodeData {
                            attrs: Some(serde_json::to_value(attrs).unwrap()),
                            ..Default::default()
                        }),
                        ..Default::default()
                    };
                    e.push(node);
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

    const SOURCE: &'static str = include_str!("markdown_reference.md");

    #[test]
    fn sanity_check() {
        let node = parse_markdown_to_vdom(SOURCE, Options::all());
        println!("{:?}", node);
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
            println!("{:?}", event);
        }
    }
}
