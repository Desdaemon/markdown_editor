import 'package:flutter/foundation.dart';

import '../bridge_generated.types.dart' as bridge;
import '../web_bindings/rust_md_dart.d.dart' as js;

Future<List<bridge.Element>?> parse({required String markdown}) =>
    SynchronousFuture((js.parse(markdown) as List<dynamic>).cast<js.Element>().map(convertElement).toList());

bridge.Element convertElement(js.Element js) {
  return bridge.Element(
      tag: js.tag,
      children: js.children?.map(convertElement).toList(),
      attributes: js.attributes?.map(convertAttribute).toList());
}

bridge.Attribute convertAttribute(js.Attribute js) {
  return bridge.Attribute(key: js.key, value: js.value);
}

void log([dynamic o, dynamic o1, dynamic o2]) => js.log(o, o1, o2);
void error([dynamic o, dynamic o1, dynamic o2]) => js.error(o, o1, o2);
