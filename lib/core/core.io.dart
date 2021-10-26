import 'dart:ffi';

import 'package:universal_io/io.dart';

import '../bridge_generated.dart';

const base = 'librust_md_dart';
final ext = Platform.isWindows
    ? '.dll'
    : Platform.isMacOS
        ? '.dylib'
        : '.so';
final dylib = DynamicLibrary.open('$base$ext');
final lib = RustMdDart(dylib);

final parse = lib.parse;
