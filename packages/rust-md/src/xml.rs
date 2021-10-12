use crate::vnode::*;
use std::borrow::Cow;
use std::collections::HashMap;

use quick_xml::events::attributes::Attributes;
use quick_xml::events::Event;
use quick_xml::Reader;

fn parse_attributes(attrs: Attributes) -> HashMap<Cow<str>, Cow<str>> {
    attrs
        .filter_map(|a| match a {
            Err(_) => None,
            Ok(a) => {
                let key = String::from_utf8_lossy(a.key);
                let value = match a.value {
                    Cow::Borrowed(bytes) => String::from_utf8_lossy(bytes),
                    Cow::Owned(vec) => match String::from_utf8(vec) {
                        Ok(e) => Cow::Owned(e),
                        _ => return None,
                    },
                };
                Some((key, value))
            }
        })
        .collect()
}

pub fn xml_to_vdom(xml: &str) -> Option<VNode> {
    let mut reader = Reader::from_str(xml);
    let mut buf = Vec::new();
    let mut node_stack: Vec<VNode> = Vec::new();
    let mut current_node: Option<VNode> = None;
    loop {
        match &reader.read_event(&mut buf) {
            Ok(Event::Eof) => break,
            Ok(Event::Start(start)) => {
                if let Some(cur) = current_node.take() {
                    node_stack.push(cur);
                }
                let tag = String::from_utf8_lossy(start.name());
                let attrs = parse_attributes(start.attributes());
                let id = attrs
                    .get("id")
                    .map(|e| format!("#{}", e))
                    .unwrap_or_else(String::new);
                let classes = attrs
                    .get("class")
                    .map(|e| format!(".{}", e.split(' ').collect::<Box<_>>().join(".")))
                    .unwrap_or_else(String::new);
                current_node = Some(VNode {
                    sel: Some([tag.to_string(), id, classes].join("")),
                    data: Some(VNodeData {
                        attrs: Some(serde_json::to_value(attrs).unwrap()),
                    }),
                    children: Some(vec![]),
                    ..Default::default()
                });
            }
            Ok(Event::End(_)) => {
                if !node_stack.is_empty() {
                    let done = current_node.take().unwrap();
                    current_node = node_stack.pop();
                    if let Some(e) = borrow_children(&mut current_node) {
                        e.push(done);
                    }
                }
            }
            Ok(Event::Text(text)) => {
                if let Some(e) = borrow_children(&mut current_node) {
                    e.push(VNode::text_node(
                        String::from_utf8_lossy(text.escaped()).to_string(),
                    ));
                }
            }
            Ok(Event::Empty(elm)) => {
                if let Some(e) = borrow_children(&mut current_node) {
                    let tag = String::from_utf8_lossy(elm.name());
                    let attrs = parse_attributes(elm.attributes());
                    let node = VNode {
                        sel: Some(tag.to_string()),
                        data: Some(VNodeData {
                            attrs: Some(serde_json::to_value(attrs).unwrap()),
                        }),
                        ..Default::default()
                    };
                    e.push(node);
                }
            }
            Err(_) => return None,
            _ => {}
        }
        buf.clear();
    }

    current_node.take()
}
