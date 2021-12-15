import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

Future<void> exportImpl(String file, {bool html = false, String fileName = 'export'}) async {
  final tempdir = await getTemporaryDirectory();
  final ext = html ? 'html' : 'md';
  final path = p.join(tempdir.path, '$fileName.$ext');
  await File(path).writeAsString(file);
  await launch('file://$path');
}
