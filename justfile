alias g := gen-bridge
# Emits bindings for FFI and WASM.
gen-bridge:
    flutter_rust_bridge_codegen -r packages/rust-md-dart/src/api.rs \
                                -d lib/bridge_generated.dart
    dart format --fix -l 120 lib/bridge_generated.dart

build-web:
    cd packages/rust-md-dart && wasm-pack build -t web
    dart_js_lib_gen packages/rust-md-dart/pkg/rust_md_dart.d.ts -o lib/web_bindings -w --no-imports --dynamic-undefs
# vim:expandtab:tabstop=4:shiftwidth=4
