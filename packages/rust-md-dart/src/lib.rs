use pulldown_cmark::{Alignment, Event, Options, Parser};
use rust_md::events;
use rust_md::markdown::{attrs_of, display_of};

#[derive(Debug)]
pub enum Node {
    Element(Element),
    Text(String),
}

fn borrow_text(elm: &mut Option<Node>) -> Option<&mut String> {
    match elm {
        Some(Node::Text(text)) => Some(text),
        _ => None,
    }
}

#[inline]
fn borrow_children(elm: &mut Option<Node>) -> Option<&mut Vec<Node>> {
    match elm {
        Some(Node::Element(Element { children, .. })) => children.as_mut(),
        _ => None,
    }
}

#[derive(Default, Debug)]
pub struct Element {
    pub tag: String,
    pub children: Option<Vec<Node>>,
    pub attributes: Option<Vec<(&'static str, String)>>,
}

pub fn markdown_to_nodes(markdown: &str) -> Option<Node> {
    let parser = Parser::new_ext(markdown, Options::all());
    let events = events::remap_table_headers(parser);
    let events = events::wrap_code_block(events);

    let mut current_node: Option<Node> = None;
    // let mut current_node = Some(Node::Element(Element {
    //     tag: "div".to_owned(),
    //     children: Some(vec![]),
    //     ..Default::default()
    // }));

    let mut memo = (Vec::<Alignment>::new(), 0usize);
    let mut node_stack = vec![Node::Element(Element {
        tag: "div".to_owned(),
        children: Some(vec![]),
        ..Default::default()
    })];

    for event in events {
        match event {
            Event::Start(tag) => {
                if let Some(e) = current_node.take() {
                    node_stack.push(e);
                }
                let name = display_of(&tag);
                let attr = attrs_of(tag, &mut memo).map(|e| vec![e]);
                current_node = Some(Node::Element(Element {
                    tag: name.to_string(),
                    children: Some(vec![]),
                    attributes: attr,
                }))
            }
            Event::End(_) => {
                if let Some(mut e) = node_stack.pop() {
                    let current = current_node.take().unwrap();
                    if let Node::Element(Element {
                        children: Some(children),
                        ..
                    }) = &mut e
                    {
                        children.push(current);
                    }
                    current_node = Some(e);
                }
            }
            Event::Text(contents) => {
                if let Some(e) = borrow_text(&mut current_node) {
                    e.push_str(&contents)
                } else if let Some(e) = borrow_children(&mut current_node) {
                    e.push(Node::Text(contents.to_string()))
                }
            }
            Event::Code(code) => {
                if let Some(e) = borrow_children(&mut current_node) {
                    e.push(Node::Element(Element {
                        tag: "code".to_owned(),
                        children: Some(vec![Node::Text(code.to_string())]),
                        ..Default::default()
                    }))
                }
            }
            // Event::Html(_) => todo!(),
            // Event::FootnoteReference(_) => todo!(),
            Event::SoftBreak => {
                if let Some(e) = borrow_text(&mut current_node) {
                    e.push('\n');
                } else if let Some(e) = borrow_children(&mut current_node) {
                    e.push(Node::Text("\n".to_owned()))
                }
            }
            Event::HardBreak => {
                if let Some(e) = borrow_children(&mut current_node) {
                    e.push(Node::Element(Element {
                        tag: "br".to_owned(),
                        ..Default::default()
                    }))
                }
            }
            Event::Rule => {
                if let Some(e) = borrow_children(&mut current_node) {
                    e.push(Node::Element(Element {
                        tag: "hr".to_owned(),
                        ..Default::default()
                    }))
                }
            }
            Event::TaskListMarker(checked) => {
                if let Some(e) = borrow_children(&mut current_node) {
                    e.push(Node::Element(Element {
                        tag: "input".to_owned(),
                        attributes: Some(vec![("checked", checked.to_string())]),
                        ..Default::default()
                    }))
                }
            }
            _ => {}
        }
    }
    current_node
}

#[cfg(test)]
mod tests {
    use crate::markdown_to_nodes;

    const SOURCE: &'static str = include_str!("../../markdown_reference.md");

    #[test]
    fn sanity_test() {
        let node = markdown_to_nodes(SOURCE);
        println!("{:#?}", node);
    }
}
