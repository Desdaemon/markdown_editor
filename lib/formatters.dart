import 'package:flutter/services.dart';
import 'package:text/text.dart';

String? lastCharacter(TextEditingValue val) {
  if (val.selection.isCollapsed && val.selection.start > 1) {
    return val.text[val.selection.start - 1];
  }
}

class NewlineFormatter extends TextInputFormatter {
  static const newlinePattern = '\r\n';
  static const spaceCharcode = 32;
  static const periodCharcode = 46;
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
      final header = bulletListHeader(previousLine, length) ?? numberListHeader(previousLine, length) ?? '';
      return newValue.copyWith(
        text: [
          newValue.selection.textBefore(newValue.text),
          indent,
          header,
          newValue.selection.textInside(newValue.text),
          newValue.selection.textAfter(newValue.text),
        ].join(),
        selection: TextSelection.collapsed(offset: newValue.selection.baseOffset + length + header.length),
      );
    }
    return newValue;
  }

  String? bulletListHeader(Line previousLine, int indent) {
    final string = String.fromCharCodes(previousLine.characters.skip(indent));
    if (string.startsWith('- [ ] ') || string.startsWith('- [x] ')) {
      return '- [ ] ';
    } else if (string.startsWith('- ')) {
      return '- ';
    }
  }

  String? numberListHeader(Line previousLine, int indent) {
    final string =
        String.fromCharCodes(previousLine.characters.skip(indent).takeWhile((char) => char != periodCharcode));
    final header = int.tryParse(string);
    if (header != null) {
      return '${header + 1}. ';
    }
  }
}
