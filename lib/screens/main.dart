import 'package:flutter/material.dart' hide Element;
import 'package:markdown_editor/core/core.dart';
import '../wire.dart';
import 'package:markdown_editor/widgets/bottom_bar.dart';
import 'package:universal_io/io.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

String visitElement(Element? elm) {
  if (elm == null) return '<empty>';
  final attr = elm.attributes == null ? '' : ' ${elm.attributes!.key}=${elm.attributes!.val}';
  final tag = elm.tag.isEmpty ? '#text' : elm.tag;
  var children = elm.children.map(visitElement).join('\n');
  if (children.isEmpty) children = elm.text;
  return '''
<$tag$attr>
	$children
</$tag>''';
}

final controllerProvider = ChangeNotifierProvider((_) => TextEditingController());
final sourceProvider = Provider((ref) => ref.watch(controllerProvider).text);

class Main extends StatelessWidget {
  static final _isMobile = Platform.isAndroid || Platform.isIOS;

  Main({Key? key}) : super(key: key);
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();

  static Widget buildEditor(BuildContext bc, WidgetRef ref, Widget? _) {
    final ctl = ref.watch(controllerProvider);
    return TextField(
      decoration: const InputDecoration.collapsed(hintText: null),
      maxLines: null,
      expands: true,
      controller: ctl,
    );
  }

  static Widget buildPreview(BuildContext bc, WidgetRef ref, Widget? _) {
    final source = ref.watch(sourceProvider);
    final nodes = markdownToNodes(markdown: source);
    return FutureBuilder<Element?>(
      future: nodes,
      builder: (bc, snapshot) {
        final data = snapshot.data;
        if (data != null) {
          final children = Text(visitElement(data as dynamic));
          return children;
        }
        return const Text("Loading...");
      },
    );
  }

  @override
  Widget build(BuildContext context) =>
      SafeArea(child: Scaffold(key: scaffoldKey, body: LayoutBuilder(builder: buildLayout)));

  Widget buildLayout(BuildContext bc, BoxConstraints cons) {
    final vertical = cons.maxWidth < 700;
    final children = <Widget>[
      Expanded(
        child: Padding(
          padding: vertical
              ? const EdgeInsets.fromLTRB(16, 16, 16, 8)
              : _isMobile
                  ? const EdgeInsets.fromLTRB(16, 32, 8, 8)
                  : const EdgeInsets.fromLTRB(16, 16, 8, 8),
          child: const Consumer(builder: buildEditor),
        ),
      ),
      Expanded(
        child: Container(
          alignment: Alignment.topLeft,
          padding: vertical
              ? _isMobile
                  ? const EdgeInsets.fromLTRB(16, 32, 16, 8)
                  : const EdgeInsets.fromLTRB(16, 16, 16, 8)
              : _isMobile
                  ? const EdgeInsets.fromLTRB(8, 32, 16, 8)
                  : const EdgeInsets.fromLTRB(8, 16, 16, 8),
          child: const Consumer(builder: buildPreview),
        ),
      )
    ];
    return Column(children: [
      if (vertical)
        ...children.reversed
      else
        Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: children)),
      BottomBar(scaffoldKey: scaffoldKey)
    ]);
  }
}
