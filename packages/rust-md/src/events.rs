use nom::bytes::complete::*;
use pulldown_cmark::Event;

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

fn is_in_katex(input: &str, initial: bool) -> nom::IResult<&str, bool> {
    Ok((input, initial))
}
