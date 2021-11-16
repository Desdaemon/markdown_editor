import 'package:flutter/foundation.dart';

import '../bridge_generated.types.dart';
import '../web_bindings/rust_md_dart.d.dart' as js;

Future<List<Element>?> parse({required String markdown}) => SynchronousFuture(js.parse(markdown));
