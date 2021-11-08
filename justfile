alias g := gen-bridge
gen-bridge:
    flutter_rust_bridge_codegen -r packages/rust-md-dart/src/api.rs \
                                -d lib/bridge_generated.dart
    dart format --fix -l 120 lib/bridge_generated.dart
# vim:expandtab:tabstop=4:shiftwidth=4

