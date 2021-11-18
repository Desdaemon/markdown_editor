web_crate := "packages/rust-md-dart"

# Emits bindings for FFI and WASM.
bridge:
    flutter_rust_bridge_codegen -r packages/rust-md-dart/src/api.rs \
                                -d lib/bridge_generated.dart
    dart format --fix -l 120 lib/bridge_generated.dart

web:
    cd {{web_crate}} && wasm-pack build -t web
    cp {{web_crate}}/pkg/*.js {{web_crate}}/pkg/*.wasm web/
    dart_js_lib_gen {{web_crate}}/pkg/rust_md_dart.d.ts -o lib/web_bindings -w --no-imports --dynamic-undefs

# vim:expandtab:tabstop=4:shiftwidth=4
