use nom::bytes::complete::*;
use pulldown_cmark::{Event, Tag};

pub fn process_katex<'a>(
    events: impl Iterator<Item = Event<'a>>,
) -> impl Iterator<Item = Event<'a>> {
    events.map(|event| match event {
        Event::Text(text) => Event::Text(text),
        Event::HardBreak => {
            todo!()
        }
        e => e,
    })
}

pub fn remap_table_headers<'a>(
    events: impl Iterator<Item = Event<'a>>,
) -> impl Iterator<Item = Event<'a>> {
    events.scan(false, |in_header, event| match event {
        Event::Start(Tag::TableHead) => {
            *in_header = true;
            Some(Event::Start(Tag::TableRow))
        }
        Event::End(Tag::TableHead) => {
            *in_header = false;
            Some(Event::End(Tag::TableRow))
        }
        Event::Start(Tag::TableCell) if *in_header => Some(Event::Start(Tag::TableHead)),
        Event::End(Tag::TableCell) if *in_header => Some(Event::End(Tag::TableHead)),
        e => Some(e),
    })
}

pub fn wrap_code_block<'a>(
    events: impl Iterator<Item = Event<'a>>,
) -> impl Iterator<Item = Event<'a>> {
    events.scan(false, |in_pre, event| match event {
        event @ Event::Start(Tag::CodeBlock(_)) => {
            *in_pre = true;
            Some(event)
        }
        event @ Event::End(Tag::CodeBlock(_)) => {
            *in_pre = false;
            Some(event)
        }
        Event::Text(contents) if *in_pre => Some(Event::Code(contents)),
        e => Some(e),
    })
}

fn is_in_katex(input: &str) -> nom::IResult<&str, bool> {
    let mut display: Option<bool> = None;
    let mut input = input;
    // loop {
    // if let Some(display) = &display {
    // } else if let Ok((new_input, opener)) = take_till(alt((tag("$"), tag("$$")))) {
    // input = new_input;
    // }
    // }
    Ok((input, display.unwrap_or(true)))
}
