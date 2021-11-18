use nom::branch::alt;
use nom::bytes::complete::{is_not, tag, take, take_until, take_while_m_n};
use nom::character::complete::{char, none_of};
use nom::combinator::{eof, map, opt, recognize};
use nom::multi::many0;
use nom::sequence::{delimited, terminated};
use nom::IResult;
use std::borrow::Cow;

#[derive(Debug)]
pub enum InlineElement<'a> {
    MathDisplay(&'a str),
    MathText(&'a str),
    Plain(&'a str),
}

pub fn parse_math(input: &str) -> IResult<&str, Vec<InlineElement>> {
    many0(alt((parse_math_display, parse_math_text, parse_math_plain)))(input)
}

fn parse_math_display(input: &str) -> IResult<&str, InlineElement> {
    map(
        delimited(tag("$$"), take_until("$$"), tag("$$")),
        InlineElement::MathDisplay,
    )(input)
}

fn parse_math_plain(input: &str) -> IResult<&str, InlineElement> {
    let (input, till_opener) = opt(is_not("$"))(input)?;
    if let Some(inner) = till_opener {
        Ok((input, InlineElement::Plain(inner)))
    } else {
        map(take(1usize), InlineElement::Plain)(input)
    }
}

/// Recognizes one or two non-space characters.
fn one_or_two_non_space(input: &str) -> IResult<&str, &str> {
    take_while_m_n(1, 2, |c| !(c == ' ' || c == '\n'))(input)
}

fn take_one_less(input: &str) -> IResult<&str, &str> {
    take(input.len() - 1)(input)
}

fn math_wrapped(input: &str) -> IResult<&str, &str> {
    delimited(char('$'), is_not("$"), char('$'))(input)
}

fn parse_math_text(input: &str) -> IResult<&str, InlineElement> {
    let (input, inner) = math_wrapped(input)?;
    let (_, inner) = alt((
        terminated(one_or_two_non_space, eof),
        recognize(delimited(none_of(" \n"), take_one_less, none_of(" \n"))),
    ))(inner)?;
    Ok((input, InlineElement::MathText(inner)))
}

pub fn replace_line_break_in_math(markdown: &str) -> String {
    let cap = markdown.len() + 2 * count_line_breaks(markdown);
    let (_, sections) = parse_math(markdown).unwrap();
    sections
        .into_iter()
        .map(|x| match x {
            InlineElement::MathText(x) => Cow::Owned(format!("${}$", x.replace(r"\\", r"\\\\"))),
            InlineElement::MathDisplay(x) => {
                Cow::Owned(format!("$${}$$", x.replace(r"\\", r"\\\\")))
            }
            InlineElement::Plain(x) => Cow::Borrowed(x),
        })
        .fold(String::with_capacity(cap), |mut acc, x| {
            acc.push_str(&x);
            acc
        })
}

fn count_line_breaks(markdown: &str) -> usize {
    markdown.matches("\\\\").count()
}
