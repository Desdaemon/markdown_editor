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
