use crate::{
    events::{remap_table_headers, wrap_code_block},
    vnode::*,
    xml::xml_to_vdom,
};
use pulldown_cmark::{Alignment, Options, Parser, Tag};
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

// fn hoist_last_text(opt: &mut Option<VNode>) {
// match opt {
// Some(node) => match &node.children {
// Some(vec) if vec.len() == 1 => match vec.last() {
// Some(VNode { text, .. }) if text.is_some() => {
// let text = node.children.take().unwrap().pop().unwrap().text;
// node.text = text;
// }
// _ => {}
// },
// _ => {}
// },
// _ => {}
// }
// }

pub fn display_of(tag: &Tag) -> &'static str {
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

pub fn class_of(tag: &Tag) -> Option<String> {
    match tag {
        pulldown_cmark::Tag::CodeBlock(pulldown_cmark::CodeBlockKind::Fenced(lang)) => {
            Some(lang.to_string())
        }
        _ => None,
    }
}

pub type AlignmentMemo = (Vec<Alignment>, usize);

pub fn attrs_of(
    tag: Tag,
    (alignments, align_index): &mut AlignmentMemo,
) -> Option<serde_json::Value> {
    match tag {
        pulldown_cmark::Tag::Link(typ, dest, _title) => {
            let href: String = match typ {
                pulldown_cmark::LinkType::Email => format!("mailto:{}", &dest),
                _ => dest.to_string(),
            };
            Some(json! {{ "href": href }})
        }
        pulldown_cmark::Tag::TableCell | pulldown_cmark::Tag::TableHead => {
            let align = alignments[*align_index];
            *align_index = (*align_index + 1) % alignments.len();
            match alignment_of(&align) {
                Some(align) => Some(json! {{ "align": align }}),
                _ => None,
            }
        }
        pulldown_cmark::Tag::Table(aligns) => {
            *alignments = aligns;
            *align_index = 0;
            None
        }
        pulldown_cmark::Tag::List(Some(start)) => Some(json! {{ "start": start }}),
        _ => None,
    }
}

fn alignment_of(alignment: &Alignment) -> Option<&'static str> {
    match alignment {
        Alignment::None => None,
        Alignment::Left => Some("left"),
        Alignment::Right => Some("right"),
        Alignment::Center => Some("center"),
    }
}

pub fn markdown_to_vdom(markdown: &str, options: Options) -> Option<VNode> {
    let parser = Parser::new_ext(markdown, options);
    let events = wrap_code_block(parser);
    let events = remap_table_headers(events);
    markdown_to_vdom_with(events)
}

pub fn markdown_to_vdom_with<'a>(
    events: impl Iterator<Item = pulldown_cmark::Event<'a>>,
) -> Option<VNode> {
    let mut node_stack: Vec<VNode> = vec![];
    let mut current_node: Option<VNode> = Some(VNode {
        sel: Some("div".to_owned()),
        children: Some(vec![]),
        ..Default::default()
    });
    let mut memo = (vec![], 0);

    for event in events {
        match event {
            pulldown_cmark::Event::Start(tag) => {
                if let Some(cur) = current_node.take() {
                    node_stack.push(cur);
                }
                let name = display_of(&tag);
                let class = class_of(&tag);
                let attrs = attrs_of(tag, &mut memo);
                current_node = Some(VNode {
                    sel: Some(
                        class
                            .map(|e| format!("{}.language-{}", &name, e))
                            .unwrap_or_else(|| name.to_owned()),
                    ),
                    data: Some(VNodeData { attrs }),
                    children: Some(vec![]),
                    ..Default::default()
                });
            }
            pulldown_cmark::Event::End(tag) => {
                if let pulldown_cmark::Tag::Image(_, dest, _) = &tag {
                    let current_node = current_node.as_mut().unwrap();
                    let children = current_node.children.take().unwrap();
                    let alt = match children.last() {
                        Some(last) => last.text.as_deref().unwrap_or(&dest),
                        _ => &dest,
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
                        data: Some(Default::default()),
                        // it's put in children to separate it from merging
                        // with other segments.
                        children: Some(vec![VNode::text_node(text.to_string())]),
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
                    e.push('\n')
                } else if let Some(e) = borrow_children(&mut current_node) {
                    e.push(VNode::text_node("\n".to_owned()))
                }
            }
            pulldown_cmark::Event::HardBreak => {
                if let Some(e) = borrow_children(&mut current_node) {
                    e.push(VNode {
                        sel: Some("br".to_owned()),
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
    // use assert_json_diff::assert_json_include;
    use pulldown_cmark::Options;
    use serde_json::Value;

    use super::markdown_to_vdom;

    // const SOURCE: &'static str = include_str!("../../markdown_reference.md");
    const SOURCE: &'static str = "
asdasd

---


asdasd";
    const VNODE_JSON: &'static str = include_str!("markdown_reference.json");

    #[test]
    fn spec() {
        // let expected: Value = serde_json::from_str(VNODE_JSON).unwrap();
        let actual = markdown_to_vdom(SOURCE, Options::all()).unwrap();
        let json = serde_json::to_string_pretty(&actual).unwrap();
        println!("{}", &json);
        // assert_json_include!(
        // actual: serde_json::to_value(actual).unwrap(),
        // expected: expected
        // );
    }
}
