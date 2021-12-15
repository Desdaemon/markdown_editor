// ignore: avoid_web_libraries_in_flutter
import 'dart:html';

void exportImpl(String file, {bool html = true, String fileName = 'export'}) {
  final type = html ? 'html' : 'text';
  final ext = html ? 'html' : 'md';
  final text = 'data:text/$type;charset=utf8,' + Uri.encodeComponent(file);
  final doc = document.createElement('a')
    ..attributes['download'] = '$fileName.$ext'
    ..attributes['href'] = text;
  document.body?.append(doc);
  doc
    ..click()
    ..remove();
}
