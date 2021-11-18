use crate::{vnode::*, xml::xml_to_vdom};
use rust_md_core::events::{
    attrs_of, class_of, display_of, remap_table_headers, transform_line_breaks, wrap_code_block,
};
use rust_md_core::parser::replace_line_break_in_math;
use rust_md_core::pulldown_cmark::{Event, Options, Parser, Tag};
use serde_json::json;

fn borrow_last_text(opt: &mut Option<VNode>) -> Option<&mut String> {
    match opt {
        Some(node) => match node.children.last_mut() {
            Some(node) => node.text.as_mut(),
            _ => None,
        },
        _ => None,
    }
}

pub fn markdown_to_vdom(markdown: &str, options: Options) -> Option<VNode> {
    let markdown = replace_line_break_in_math(markdown);
    let parser = Parser::new_ext(&markdown, options);
    let events = transform_line_breaks(wrap_code_block(remap_table_headers(parser)));
    markdown_to_vdom_with(events)
}

pub fn markdown_to_vdom_with<'a>(events: impl Iterator<Item = Event<'a>>) -> Option<VNode> {
    let mut node_stack: Vec<VNode> = vec![];
    let mut current_node: Option<VNode> = Some(VNode {
        sel: Some("div".to_owned()),
        children: vec![],
        ..Default::default()
    });
    let mut memo = (vec![], 0);

    for event in events {
        match event {
            Event::Start(tag) => {
                if let Some(cur) = current_node.take() {
                    node_stack.push(cur);
                }
                let name = display_of(&tag);
                let class = class_of(&tag);
                let attrs = attrs_of(tag, &mut memo).map(|(key, val)| json! {{ key: val }});
                current_node = Some(VNode {
                    sel: Some(
                        class
                            .map(|e| format!("{}.language-{}", &name, e))
                            .unwrap_or_else(|| name.to_owned()),
                    ),
                    data: Some(VNodeData { attrs }),
                    children: vec![],
                    ..Default::default()
                });
            }
            Event::End(tag) => {
                if let Tag::Image(_, dest, _) = &tag {
                    let current_node = current_node.as_mut().unwrap();
                    let alt = match &current_node.children[..] {
                        [.., VNode {
                            text: Some(dest), ..
                        }] => dest.as_str(),
                        _ => dest,
                    };
                    let attrs = Some(json! {{ "src": dest.to_string(), "alt": alt }});
                    if let Some(data) = &mut current_node.data {
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
                // hoist_last_text(&mut current_node);
            }
            Event::Text(text) => {
                if let Some(e) = borrow_last_text(&mut current_node) {
                    e.push_str(&text)
                } else if let Some(e) = borrow_children(&mut current_node) {
                    e.push(VNode::text_node(text.to_string()))
                }
            }
            Event::Code(text) => {
                if let Some(e) = borrow_children(&mut current_node) {
                    let code_node = VNode {
                        sel: Some("code".to_owned()),
                        data: Some(Default::default()),
                        // it's put in children to separate it from merging
                        // with other segments.
                        children: vec![VNode::text_node(text.to_string())],
                        ..Default::default()
                    };
                    e.push(code_node);
                }
            }
            Event::Html(xml) => {
                if let Some(e) = borrow_children(&mut current_node) {
                    if let Some(vnode) = xml_to_vdom(&xml) {
                        e.push(vnode);
                    }
                }
            }
            // pulldown_cmark::Event::FootnoteReference(_) => todo!(),
            Event::SoftBreak => {
                if let Some(e) = borrow_last_text(&mut current_node) {
                    e.push('\n')
                } else if let Some(e) = borrow_children(&mut current_node) {
                    e.push(VNode::text_node("\n".to_owned()))
                }
            }
            Event::HardBreak => {
                if let Some(e) = borrow_children(&mut current_node) {
                    e.push(VNode {
                        sel: Some("br".to_owned()),
                        ..Default::default()
                    });
                }
            }
            Event::Rule => {
                if let Some(e) = borrow_children(&mut current_node) {
                    e.push(VNode {
                        sel: Some("hr".to_owned()),
                        ..Default::default()
                    })
                }
            }
            Event::TaskListMarker(checked) => {
                let current_node = current_node.as_mut().unwrap();
                current_node
                    .sel
                    .as_mut()
                    .unwrap()
                    .push_str(".task-list-item");
                current_node.children.push(VNode {
                    sel: Some("input.task-list-item-checkbox".to_owned()),
                    data: Some(VNodeData {
                        attrs: Some(json! ({
                            "type": "checkbox",
                            "disabled": "",
                            "checked": checked
                        })),
                    }),
                    ..Default::default()
                });
            }
            _ => {}
        }
    }

    current_node.take()
}
