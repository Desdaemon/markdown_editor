import 'package:markdown_editor/core/core.dart';

void main() async {
  const source = '''
			Hello there!
# asd
## sdf
### 123
			''';
  print(await parse(markdown: source));
}
