@JS()
library packages.rust_md_dart.pkg.rust_md_dart.d.ts;

// ignore_for_file: non_constant_identifier_names, private_optional_parameter, unused_element
import 'package:js/js.dart';

@JS(r'parse')
external List<Element>? parse(String markdown);

@JS()
@anonymous
class Element {
  external String get tag;
  external set tag(String value);
  external List<Attribute>? get attributes;
  external set attributes(List<Attribute>? value);
  external List<Element>? get children;
  external set children(List<Element>? value);
  external factory Element({
    String tag,
    List<Attribute>? attributes,
    List<Element>? children,
  });
}

@JS()
@anonymous
class Attribute {
  external String get key;
  external set key(String value);
  external String get value;
  external set value(String value);
  external factory Attribute({
    String key,
    String value,
  });
}

typedef InitInput = dynamic;

@JS()
@anonymous
class InitOutput {
  external Memory get memory;
  external num Function(num a, num b) get parse;
  external factory InitOutput({
    Memory memory,
    num Function(num a, num b) parse,
  });
}

typedef Memory = dynamic;

@JS('console.log')
external void log([dynamic o, dynamic o1, dynamic o2]);

@JS('console.error')
external void error([dynamic o, dynamic o1, dynamic o2]);
