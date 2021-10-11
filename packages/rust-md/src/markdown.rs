use crate::{vnode::*, xml::xml_to_vdom};
use pulldown_cmark::{Options, Parser, Tag};
use serde_json::json;

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

pub fn markdown_to_vdom(markdown: &str, options: Options) -> Option<VNode> {
    let parser = Parser::new_ext(markdown, options);
    markdown_to_vdom_with(parser)
}

pub fn markdown_to_vdom_with(parser: Parser) -> Option<VNode> {
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
                        Some(json!{{ "href": href }})
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
                let text = text.escape_debug().to_string();
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
            pulldown_cmark::Event::Html(xml) => {
                if let Some(e) = borrow_children(&mut current_node) {
                    if let Some(vnode) = xml_to_vdom(&xml) {
                        e.push(vnode);
                    }
                }
            }
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
    use pulldown_cmark::Options;

    use super::markdown_to_vdom;

    #[test]
    fn test_mixed_xml() {
        let source = "
$$
one two \\\\
three
$$";
        let node = markdown_to_vdom(source, Options::all());
        dbg!(node);
    }
}
