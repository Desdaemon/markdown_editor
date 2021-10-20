use allo_isolate::ZeroCopyBuffer;
use anyhow::Result;

pub struct OptionGallery {
    pub int32: Option<i32>,
    pub int64: Option<i64>,
    pub rational: Option<f64>,
    pub boolean: Option<bool>,
    pub string: Option<String>,
    pub zerocopy: Option<ZeroCopyBuffer<Vec<u8>>>,
    pub int8linst: Option<Vec<i8>>,
    pub uint8linst: Option<Vec<u8>>,
    pub rational_list: Option<Vec<f64>>,
    pub person: Option<Person>,
    pub people: Option<Vec<Person>>,
    pub people_nullable: Vec<Option<Person>>,
    pub nullable_people: Option<Vec<Option<Person>>>,
    pub int32_box: Option<Box<i32>>,
    // not supported upstream
    // pub boxed: Option<Box<Person>>,
    // pub int8: Option<i8>,
    // pub uint8: Option<u8>,
}

pub struct Person {
    pub name: String,
    pub age: i32,
    pub bio: Option<String>,
}

pub fn drop(_input: Option<OptionGallery>) -> Result<Option<OptionGallery>> {
    Ok(None)
}
