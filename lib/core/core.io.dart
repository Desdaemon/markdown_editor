import 'dart:ffi';

import 'package:universal_io/io.dart';

import '../bridge_generated.dart';

const base = 'rust_md_dart';
final path = Platform.isWindows
    ? '$base.dll'
    : Platform.isMacOS
        ? 'lib$base.dylib'
        : 'lib$base.so';
final dylib = DynamicLibrary.open(path);
final lib = RustMdDart(dylib);

final parse = lib.parse;

void log([dynamic o, dynamic o1, dynamic o2]) => print([o, o1, o2].map((e) => e.toString()).join('\n'));
void error([dynamic o, dynamic o1, dynamic o2]) => print('err: ' + [o, o1, o2].map((e) => e.toString()).join('\n'));
