// AUTO GENERATED FILE, DO NOT EDIT.
// Generated by `flutter_rust_bridge`.

// ignore_for_file: non_constant_identifier_names, unused_element, duplicate_ignore, directives_ordering, curly_braces_in_flow_control_structures, unnecessary_lambdas
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'dart:ffi' as ffi;

abstract class RustMdDart extends FlutterRustBridgeBase<RustMdDartWire> {
  factory RustMdDart(ffi.DynamicLibrary dylib) => RustMdDartImpl.raw(RustMdDartWire(dylib));

  RustMdDart.raw(RustMdDartWire inner) : super(inner);

  Future<String> greet({required String? text});

  Future<Element?> markdownToNodes({required String markdown});
}

class Element {
  final String tag;
  final List<Element> children;
  final Attribute? attributes;
  final String text;

  Element({
    required this.tag,
    required this.children,
    this.attributes,
    required this.text,
  });
}

class Attribute {
  final String key;
  final String val;

  Attribute({
    required this.key,
    required this.val,
  });
}

// ------------------------- Implementation Details -------------------------

/// Implementations for RustMdDart. Prefer using RustMdDart if possible; but this class allows more
/// flexible customizations (such as subclassing to create an initializer, a logger, or
/// a timer).
class RustMdDartImpl extends RustMdDart {
  RustMdDartImpl.raw(RustMdDartWire inner) : super.raw(inner);

  Future<String> greet({required String? text}) =>
      execute('greet', (port) => inner.wire_greet(port, _api2wire_opt_String(text)), _wire2api_String);

  Future<Element?> markdownToNodes({required String markdown}) => execute('markdown_to_nodes',
      (port) => inner.wire_markdown_to_nodes(port, _api2wire_String(markdown)), _wire2api_opt_element);

  // Section: api2wire
  ffi.Pointer<wire_uint_8_list> _api2wire_opt_String(String? raw) {
    if (raw == null) return ffi.nullptr;
    return _api2wire_String(raw);
  }

  ffi.Pointer<wire_uint_8_list> _api2wire_String(String raw) {
    return _api2wire_uint_8_list(utf8.encoder.convert(raw));
  }

  ffi.Pointer<wire_uint_8_list> _api2wire_uint_8_list(Uint8List raw) {
    final ans = inner.new_uint_8_list(raw.length);
    ans.ref.ptr.asTypedList(raw.length).setAll(0, raw);
    return ans;
  }

  int _api2wire_u8(int raw) {
    return raw;
  }

  ffi.Pointer<wire_Element> _api2wire_opt_element(Element? raw) {
    if (raw == null) return ffi.nullptr;
    final ptr = inner.new_opt_element();
    _api_fill_to_wire_element(raw, ptr.ref);
    return ptr;
  }

  ffi.Pointer<wire_list_element> _api2wire_list_element(List<Element> raw) {
    final ans = inner.new_list_element(raw.length);
    for (var i = 0; i < raw.length; ++i) {
      _api_fill_to_wire_element(raw[i], ans.ref.ptr[i]);
    }
    return ans;
  }

  ffi.Pointer<wire_Attribute> _api2wire_opt_attribute(Attribute? raw) {
    if (raw == null) return ffi.nullptr;
    final ptr = inner.new_opt_attribute();
    _api_fill_to_wire_attribute(raw, ptr.ref);
    return ptr;
  }

  // Section: api_fill_to_wire

  void _api_fill_to_wire_element(Element apiObj, wire_Element wireObj) {
    wireObj.tag = _api2wire_String(apiObj.tag);
    wireObj.children = _api2wire_list_element(apiObj.children);
    wireObj.attributes = _api2wire_opt_attribute(apiObj.attributes);
    wireObj.text = _api2wire_String(apiObj.text);
  }

  void _api_fill_to_wire_attribute(Attribute apiObj, wire_Attribute wireObj) {
    wireObj.key = _api2wire_String(apiObj.key);
    wireObj.val = _api2wire_String(apiObj.val);
  }
}

// Section: wire2api
String? _wire2api_opt_String(dynamic raw) {
  return raw == null ? null : _wire2api_String(raw);
}

String _wire2api_String(dynamic raw) {
  return raw as String;
}

Uint8List _wire2api_uint_8_list(dynamic raw) {
  return raw as Uint8List;
}

int _wire2api_u8(dynamic raw) {
  return raw as int;
}

Element? _wire2api_opt_element(dynamic raw) {
  return raw == null ? null : _wire2api_element(raw);
}

Element _wire2api_element(dynamic raw) {
  final arr = raw as List<dynamic>;
  if (arr.length != 4) throw Exception('unexpected arr length: expect 4 but see ${arr.length}');
  return Element(
    tag: _wire2api_String(arr[0]),
    children: _wire2api_list_element(arr[1]),
    attributes: _wire2api_opt_attribute(arr[2]),
    text: _wire2api_String(arr[3]),
  );
}

List<Element> _wire2api_list_element(dynamic raw) {
  return (raw as List<dynamic>).map((item) => _wire2api_element(item)).toList();
}

Attribute? _wire2api_opt_attribute(dynamic raw) {
  return raw == null ? null : _wire2api_attribute(raw);
}

Attribute _wire2api_attribute(dynamic raw) {
  final arr = raw as List<dynamic>;
  if (arr.length != 2) throw Exception('unexpected arr length: expect 2 but see ${arr.length}');
  return Attribute(
    key: _wire2api_String(arr[0]),
    val: _wire2api_String(arr[1]),
  );
}

// ignore_for_file: camel_case_types, non_constant_identifier_names, avoid_positional_boolean_parameters, annotate_overrides

// AUTO GENERATED FILE, DO NOT EDIT.
//
// Generated by `package:ffigen`.

/// generated by flutter_rust_bridge
class RustMdDartWire implements FlutterRustBridgeWireBase {
  /// Holds the symbol lookup function.
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName) _lookup;

  /// The symbols are looked up in [dynamicLibrary].
  RustMdDartWire(ffi.DynamicLibrary dynamicLibrary) : _lookup = dynamicLibrary.lookup;

  /// The symbols are looked up with [lookup].
  RustMdDartWire.fromLookup(ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName) lookup)
      : _lookup = lookup;

  void wire_greet(
    int port,
    ffi.Pointer<wire_uint_8_list> text,
  ) {
    return _wire_greet(
      port,
      text,
    );
  }

  late final _wire_greetPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Int64, ffi.Pointer<wire_uint_8_list>)>>('wire_greet');
  late final _wire_greet = _wire_greetPtr.asFunction<void Function(int, ffi.Pointer<wire_uint_8_list>)>();

  void wire_markdown_to_nodes(
    int port,
    ffi.Pointer<wire_uint_8_list> markdown,
  ) {
    return _wire_markdown_to_nodes(
      port,
      markdown,
    );
  }

  late final _wire_markdown_to_nodesPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Int64, ffi.Pointer<wire_uint_8_list>)>>(
          'wire_markdown_to_nodes');
  late final _wire_markdown_to_nodes =
      _wire_markdown_to_nodesPtr.asFunction<void Function(int, ffi.Pointer<wire_uint_8_list>)>();

  ffi.Pointer<wire_uint_8_list> new_uint_8_list(
    int len,
  ) {
    return _new_uint_8_list(
      len,
    );
  }

  late final _new_uint_8_listPtr =
      _lookup<ffi.NativeFunction<ffi.Pointer<wire_uint_8_list> Function(ffi.Int32)>>('new_uint_8_list');
  late final _new_uint_8_list = _new_uint_8_listPtr.asFunction<ffi.Pointer<wire_uint_8_list> Function(int)>();

  ffi.Pointer<wire_Element> new_opt_element() {
    return _new_opt_element();
  }

  late final _new_opt_elementPtr = _lookup<ffi.NativeFunction<ffi.Pointer<wire_Element> Function()>>('new_opt_element');
  late final _new_opt_element = _new_opt_elementPtr.asFunction<ffi.Pointer<wire_Element> Function()>();

  ffi.Pointer<wire_list_element> new_list_element(
    int len,
  ) {
    return _new_list_element(
      len,
    );
  }

  late final _new_list_elementPtr =
      _lookup<ffi.NativeFunction<ffi.Pointer<wire_list_element> Function(ffi.Int32)>>('new_list_element');
  late final _new_list_element = _new_list_elementPtr.asFunction<ffi.Pointer<wire_list_element> Function(int)>();

  ffi.Pointer<wire_Attribute> new_opt_attribute() {
    return _new_opt_attribute();
  }

  late final _new_opt_attributePtr =
      _lookup<ffi.NativeFunction<ffi.Pointer<wire_Attribute> Function()>>('new_opt_attribute');
  late final _new_opt_attribute = _new_opt_attributePtr.asFunction<ffi.Pointer<wire_Attribute> Function()>();

  void rust_dummy_method_to_enforce_bundling() {
    return _rust_dummy_method_to_enforce_bundling();
  }

  late final _rust_dummy_method_to_enforce_bundlingPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function()>>('rust_dummy_method_to_enforce_bundling');
  late final _rust_dummy_method_to_enforce_bundling =
      _rust_dummy_method_to_enforce_bundlingPtr.asFunction<void Function()>();

  void store_dart_post_cobject(
    DartPostCObjectFnType ptr,
  ) {
    return _store_dart_post_cobject(
      ptr,
    );
  }

  late final _store_dart_post_cobjectPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(DartPostCObjectFnType)>>('store_dart_post_cobject');
  late final _store_dart_post_cobject = _store_dart_post_cobjectPtr.asFunction<void Function(DartPostCObjectFnType)>();
}

class wire_uint_8_list extends ffi.Struct {
  external ffi.Pointer<ffi.Uint8> ptr;

  @ffi.Int32()
  external int len;
}

class wire_list_element extends ffi.Struct {
  external ffi.Pointer<wire_Element> ptr;

  @ffi.Int32()
  external int len;
}

class wire_Element extends ffi.Struct {
  external ffi.Pointer<wire_uint_8_list> tag;

  external ffi.Pointer<wire_list_element> children;

  external ffi.Pointer<wire_Attribute> attributes;

  external ffi.Pointer<wire_uint_8_list> text;
}

class wire_Attribute extends ffi.Struct {
  external ffi.Pointer<wire_uint_8_list> key;

  external ffi.Pointer<wire_uint_8_list> val;
}

typedef DartPostCObjectFnType = ffi.Pointer<ffi.NativeFunction<ffi.Uint8 Function(DartPort, ffi.Pointer<ffi.Void>)>>;
typedef DartPort = ffi.Int64;
