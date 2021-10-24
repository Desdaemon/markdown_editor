use nom::branch::alt;
use nom::bytes::complete::{is_not, tag, take, take_until, take_while_m_n};
use nom::character::complete::{char, none_of};
use nom::combinator::recognize;
use nom::combinator::{eof, map};
use nom::multi::many0;
use nom::sequence::delimited;
use nom::sequence::terminated;
use nom::IResult;

#[derive(Debug)]
pub enum InlineElement<'a> {
    MathDisplay(&'a str),
    MathText(&'a str),
    Plain(&'a str),
}

pub fn parse_math(input: &str) -> IResult<&str, Vec<InlineElement>> {
    many0(alt((parse_math_display, parse_math_text)))(input)
}

fn parse_math_display(input: &str) -> IResult<&str, InlineElement> {
    map(
        delimited(tag("$$"), take_until("$$"), tag("$$")),
        InlineElement::MathDisplay,
    )(input)
}

fn parse_math_plain(input: &str) -> IResult<&str, InlineElement> {
    map(is_not("$"), InlineElement::Plain)(input)
}

/// Recognizes one or two non-space characters.
fn one_or_two_non_space(input: &str) -> IResult<&str, &str> {
    take_while_m_n(1, 2, |c| c != ' ')(input)
}

fn take_one_less(input: &str) -> IResult<&str, &str> {
    take(input.len() - 1)(input)
}

fn math_wrapped(input: &str) -> IResult<&str, &str> {
    delimited(char('$'), is_not("$"), char('$'))(input)
}

fn parse_math_text(input: &str) -> IResult<&str, InlineElement> {
    match math_wrapped(input) {
        Ok((input, inner)) => {
            let (_, inner) = alt((
                terminated(one_or_two_non_space, eof),
                recognize(delimited(none_of(" "), take_one_less, none_of(" "))),
            ))(inner)?;
            Ok((input, InlineElement::MathText(inner)))
        }
        _ => map(is_not("$"), InlineElement::Plain)(input),
    }
}

#[cfg(test)]
mod tests {

    use super::parse_math;

    #[test]
    fn test_begin_end_non_space() {
        let res = parse_math(
            "
let the result of $1 + 1$ be $2$.
some $1, $2.

$$
\\int_0^1f(x)dx = F(x)+C
$$",
        )
        .unwrap();
        dbg!(res);
    }
}
