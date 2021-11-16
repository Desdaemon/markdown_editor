@JS()
library rust_md_dart;

import 'package:js/js.dart';

@JS()
external dynamic parse(String markdown);

@JS()
@anonymous
class Element {
  external String get tag;
  external set tag(String value);
  external List<Attribute>? get attributes;
  external set attributes(List<Attribute>? value);
  external List<Element>? get children;
  external set children(List<Element>? value);

  external factory Element({String tag, List<Attribute>? attributes, List<Element>? value});
}

@JS()
@anonymous
class Attribute {
  external String get key;
  external set key(String value);
  external String get value;
  external set value(String value);
  external factory Attribute({String key, String value});
}
