use nom::branch::alt;
use nom::bytes::complete::{
    is_not, tag, take, take_till1, take_until, take_until1, take_while_m_n,
};
use nom::character::complete::{anychar, char, none_of};
use nom::combinator::{eof, map, opt, rest_len};
use nom::combinator::{map_parser, map_res, recognize};
use nom::sequence::{delimited, pair, preceded};
use nom::sequence::{terminated, tuple};
use nom::IResult;

pub enum InlineElement<'a> {
    MathDisplay(&'a str),
    MathText(&'a str),
    Plain(&'a str),
}

fn parse_math_display(input: &str) -> IResult<&str, InlineElement> {
    let (input, inner) = delimited(tag("$$"), take_until("$$"), tag("$$"))(input)?;
    Ok((input, InlineElement::MathDisplay(inner)))
}

fn one_or_two_non_space(input: &str) -> IResult<&str, &str> {
    take_while_m_n(1, 2, |c| c != ' ')(input)
}

fn take_one_less(len: usize) -> FnMut(&str) -> IResult<&str, &str> {}

fn begin_end_non_space(input: &str) -> IResult<&str, &str> {
    let (input, inner) = delimited(char('$'), is_not("$"), char('$'))(input)?;
    let (_, maybe_inner) = opt(terminated(take_while_m_n(1, 2, |c| c != ' '), eof))(inner)?;
    if let Some(inner) = maybe_inner {
        return Ok((input, inner));
    }
    let (_, inner) = recognize(delimited(
        none_of(" "),
        map(rest_len, |len| take(len - 1)),
        none_of(" "),
    ))(inner)?;
    Ok((input, inner))
}

#[cfg(test)]
mod tests {
    use crate::parser::begin_end_non_space;

    #[test]
    fn sanity_check() {
        let output = begin_end_non_space("$ asd$ sdfkljsdfkje").unwrap();
        dbg!(output);
    }
}
