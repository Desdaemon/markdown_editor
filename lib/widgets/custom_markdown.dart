import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown_editor/widgets/math.dart';
import 'package:markdown_editor/widgets/thunk_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomMarkdownWidget extends StatefulWidget {
  final EdgeInsetsGeometry? padding;
  final double fontScale;
  final ScrollController? controller;
  final List<md.Node> ast;
  final MarkdownStyleSheet styleSheet;
  final bool lazy;
  const CustomMarkdownWidget({
    required this.ast,
    required this.styleSheet,
    Key? key,
    this.padding,
    this.fontScale = 1,
    this.controller,
    this.lazy = true,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _CustomMarkdownWidgetState();
}

class _CustomMarkdownWidgetState extends State<CustomMarkdownWidget> implements MarkdownBuilderDelegate {
  Widget? _cache;
  final _recognizers = <GestureRecognizer>[];

  @override
  void didUpdateWidget(covariant CustomMarkdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ast != oldWidget.ast ||
        widget.controller != oldWidget.controller ||
        widget.styleSheet != oldWidget.styleSheet ||
        widget.lazy != oldWidget.lazy) {
      _cache = _build();
    }
  }

  @override
  Widget build(BuildContext context) {
    _cache ??= _build();
    return _cache!;
  }

  Widget _build() {
    _disposeRecognizers();
    final builder = MarkdownBuilder(
      delegate: this,
      builders: {'math': MathBuilder(context: context)},
      selectable: false,
      styleSheet: widget.styleSheet,
      listItemCrossAxisAlignment: MarkdownListItemCrossAxisAlignment.baseline,
      imageDirectory: null,
      bulletBuilder: null,
      imageBuilder: null,
      checkboxBuilder: null,
      paddingBuilders: const {},
    );
    final children = builder.build(widget.ast);
    final List<Widget> thunkChildren;
    if (widget.lazy) {
      thunkChildren = children.map(ThunkWidget.from).toList(growable: false);
    } else {
      thunkChildren = [
        Column(
          children: children
              .map(
                (child) => RepaintBoundary(child: ThunkWidget(child: child)),
              )
              .toList(growable: false),
        )
      ];
    }
    return ListView(
      padding: widget.padding,
      controller: widget.controller,
      children: thunkChildren,
    );
  }

  void _disposeRecognizers() {
    for (final reg in _recognizers) {
      reg.dispose();
    }
    _recognizers.clear();
  }

  @override
  GestureRecognizer createLink(String text, String? href, String title) {
    final ret = TapGestureRecognizer();
    ret.onTap = () {
      _onTapLink(text, href, title);
    };
    _recognizers.add(ret);
    return ret;
  }

  void _onTapLink(String text, String? href, String title) async {
    if (!(href != null && href.isNotEmpty)) return;
    final ans = await showDialog<bool>(
      context: context,
      builder: (bc) {
        return SimpleDialog(
          title: Text('Go to $text?'),
          children: [
            SimpleDialogOption(
              child: const Text('Yes'),
              onPressed: () {
                Navigator.pop(bc, true);
              },
            ),
            SimpleDialogOption(
              child: const Text('No'),
              onPressed: () {
                Navigator.pop(bc, false);
              },
            ),
          ],
        );
      },
    );
    if (ans == true && await canLaunch(href)) {
      await launch(href);
    }
  }

  @override
  TextSpan formatText(MarkdownStyleSheet styleSheet, String code) {
    return TextSpan(text: code, style: styleSheet.code);
  }
}

class MathBuilder extends MarkdownElementBuilder {
  final double fontScale;
  final BuildContext context;
  MathBuilder({
    this.fontScale = 1,
    required this.context,
  });

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final display = element.attributes['display']! == 'true';
    final source = element.children!.single.textContent;
    return MathWidget(
      source: source,
      display: display,
      fontSize: 16 * fontScale,
      textColor: Theme.of(context).textTheme.bodyText2?.color,
    );
  }
}
