// ignore: avoid_web_libraries_in_flutter
import 'dart:html';

void exportImpl(String file) {
  final text = 'data:text/html;charset=utf8,' + Uri.encodeComponent(file);
  final doc = document.createElement('a')
    ..attributes['download'] = 'export.html'
    ..attributes['href'] = text;
  document.body?.append(doc);
  doc
    ..click()
    ..remove();
}
