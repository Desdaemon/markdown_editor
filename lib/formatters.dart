import 'package:flutter/services.dart';
import 'package:text/text.dart';

String? lastCharacter(TextEditingValue val) {
  if (val.selection.isCollapsed && val.selection.start > 1) {
    return val.text[val.selection.start - 1];
  }
  return null;
}

class NewlineFormatter extends TextInputFormatter {
  static const newlinePattern = '\r\n';
  static final spaceCharcode = ' '.codeUnitAt(0);
  static final periodCharcode = '.'.codeUnitAt(0);
  static bool isSpace(int code) => code == spaceCharcode;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String? last;
    if (newValue.text.length > oldValue.text.length &&
        (last = lastCharacter(newValue)) != null &&
        newlinePattern.contains(last!)) {
      final text = Text(newValue.text);
      final previousLine = text.line(text.locationAt(newValue.selection.start - 1).line - 1);
      final length = previousLine.characters.takeWhile(isSpace).length;
      final indent = ''.padLeft(length);
      var header = bulletListHeader(previousLine, length) ?? numberListHeader(previousLine, length);
      String before = newValue.selection.textBefore(newValue.text);
      int removedLength = 0;
      if (header == null) {
        header = '';
        final prev = lineTrimmed(previousLine, length);
        if (isEmptyHeader(prev)) {
          removedLength = prev.length + 1;
          before = '${before.substring(0, before.length - removedLength - 1)}\n\n';
        }
      }
      final value = [
        before,
        indent,
        header,
        newValue.selection.textInside(newValue.text),
        newValue.selection.textAfter(newValue.text),
      ].join();
      return newValue.copyWith(
        text: value,
        selection: TextSelection.collapsed(
          offset: newValue.selection.baseOffset + length + header.length - removedLength,
        ),
      );
    }
    return newValue;
  }

  String? numberListHeader(Line previousLine, int indent) {
    final string =
        String.fromCharCodes(previousLine.characters.skip(indent).takeWhile((char) => char != periodCharcode));
    final header = int.tryParse(string);
    if (header != null) {
      return '${header + 1}. ';
    }
    return null;
  }
}

String lineTrimmed(Line line, int indent) => String.fromCharCodes(line.characters.skip(indent)).trimRight();
bool isEmptyHeader(String input) => const ['- [ ]', '- [x]', '-'].contains(input);

String? bulletListHeader(Line previousLine, int indent) {
  final line = lineTrimmed(previousLine, indent);
  if (isEmptyHeader(line)) {
    return null;
  }
  if (line.startsWith('- [ ] ') || line.startsWith('- [x] ')) {
    return '- [ ] ';
  }
  if (line.startsWith('- ')) {
    return '- ';
  }
  return null;
}
