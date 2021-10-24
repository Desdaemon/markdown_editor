import 'dart:ffi';

import 'package:universal_io/io.dart';

import '../bridge_generated.dart';

final dylibPath = Platform.isLinux ? 'packages/rust-md-dart/target/release/librust_md_dart.so' : 'librust_md_dart.so';
final dylib = DynamicLibrary.open(dylibPath);
final lib = RustMdDart(dylib);

final parse = lib.parse;
