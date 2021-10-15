import 'dart:ffi';

import 'package:flutter/foundation.dart';

import '../wire.dart';
import 'dart:io';

const mode = kDebugMode ? 'debug' : 'release';
const base = 'librust_md_dart';
const rustPkg = 'packages/rust-md-dart/target/$mode';

final dylibPath = Platform.isLinux
    ? '$rustPkg/$base.so'
    : Platform.isWindows
        ? '$rustPkg/$base.dll'
        : Platform.isAndroid
            ? '$base.so'
            : const String.fromEnvironment('LIBRARY');
final dylib = Platform.isIOS ? DynamicLibrary.process() : DynamicLibrary.open(dylibPath);
final lib = RustMdDart(dylib);

final markdownToNodes = lib.markdownToNodes;
