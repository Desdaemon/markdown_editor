import 'dart:ffi';

import '../bridge_generated.dart';

const dylibPath = 'packages/rust-md-dart/target/release/librust_md_dart.so';
final dylib = DynamicLibrary.open(dylibPath);
final lib = RustMdDart(dylib);

final parse = lib.parse;
