export '../bridge_generated.dart' show Element, Attribute;
export "./core.stub.dart" if (dart.library.io) "./core.io.dart" if (dart.library.html) "./core.web.dart";
