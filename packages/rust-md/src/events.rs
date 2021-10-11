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

fn is_in_katex(input: &str) -> nom::IResult<&str, bool> {
    let mut display: Option<bool> = None;
    let mut input = input;
    loop {
        if let Some(display) = &display {

        } else if let Ok((new_input, opener)) = take_till(alt((tag("$"), tag("$$")))) {
            input = new_input;
        }
    }
    Ok((input, display))
}
