import 'package:flutter/material.dart';
import 'package:markdown_editor/widgets/bottom_bar.dart';
import 'package:universal_io/io.dart';

class Main extends StatelessWidget {
  static final _isMobile = Platform.isAndroid || Platform.isIOS;

  Main({Key? key}) : super(key: key);
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();

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
          child: const TextField(
            decoration: InputDecoration.collapsed(hintText: null),
            maxLines: null,
            expands: true,
          ),
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
          child: const SizedBox(width: 300, height: 300, child: Text('test')),
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
