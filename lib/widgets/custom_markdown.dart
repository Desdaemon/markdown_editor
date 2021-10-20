import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown_editor/widgets/math.dart';
import 'package:markdown_editor/widgets/thunk_widget.dart';
import 'package:url_launcher/url_launcher.dart';

SliverGrid transformTable(Table table, [BuildContext? context]) {
  return SliverGrid(
    delegate: SliverChildListDelegate.fixed(
      table.children.expand((row) => row.children!).toList(growable: false),
    ),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: table.children[0].children!.length,
    ),
  );
}

class SliverCollector {
  final slivers = <Widget>[];
  var current = <Widget>[];

  List<Widget> iterate(List<Widget> widgets) {
    for (final next in widgets) {
      if (next is Table) {
        slivers.add(SliverList(delegate: SliverChildListDelegate.fixed(List.of(current, growable: false))));
        current = [];
        slivers.add(
          SliverGrid(
            delegate: SliverChildListDelegate.fixed(
              next.children
                  .expand((row) => row.children!)
                  .map((child) => ThunkWidget(child: child is TableCell ? child.child : child))
                  .toList(growable: false),
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: next.children[0].children!.length,
              childAspectRatio: 6,
            ),
          ),
        );
      } else {
        current.add(ThunkWidget(child: next));
      }
    }
    slivers.add(SliverList(delegate: SliverChildListDelegate.fixed(current)));
    return slivers;
  }
}

class CustomMarkdownWidget extends MarkdownWidget {
  final EdgeInsetsGeometry? padding;
  final double fontScale;
  final ScrollController? controller;
  const CustomMarkdownWidget({
    required String data,
    Key? key,
    this.padding,
    this.fontScale = 1,
    md.ExtensionSet? extensionSet,
    List<md.InlineSyntax>? inlineSyntaxes,
    List<md.BlockSyntax>? blockSyntaxes,
    MarkdownStyleSheet? styleSheet,
    this.controller,
  }) : super(
          data: data,
          key: key,
          extensionSet: extensionSet,
          inlineSyntaxes: inlineSyntaxes,
          blockSyntaxes: blockSyntaxes,
          styleSheet: styleSheet,
        );
  @override
  List<md.InlineSyntax>? get inlineSyntaxes =>
      [if (super.inlineSyntaxes != null) ...super.inlineSyntaxes!, MathSyntax()];

  @override
  Map<String, MarkdownElementBuilder> get builders => {...super.builders, 'math': MathBuilder(fontScale: fontScale)};

  @override
  MarkdownTapLinkCallback? get onTapLink => _onTapLink;

  void _onTapLink(String text, String? href, String title) async {
    debugPrint('text=$text href=$href title=$title');
    if (href != null && href.isNotEmpty && await canLaunch(href)) {
      await launch(href);
    }
  }

  @override
  Widget build(BuildContext context, List<Widget>? children) {
    if (children == null) return const SizedBox();
    // final slivers = SliverCollector().iterate(children);
    // return CustomScrollView(controller: controller, slivers: slivers);
    final thunkChildren = children.map((child) => ThunkWidget(child: child)).toList(growable: false);
    return ListView(controller: controller, padding: padding, children: thunkChildren);
    // return ListView(controller: controller, padding: padding, children: [
    // ThunkWidget(
    // child: Column(children: thunkChildren),
    // ),
    // ]);
  }
}

class MathSyntax extends md.InlineSyntax {
  MathSyntax() : super(r'(\${1,2})([^\0]+?)\1');
  @override
  bool onMatch(md.InlineParser parser, Match match) {
    if (match.groupCount != 2) return true;
    final display = match[1]! == r'$$';
    final elm = md.Element('math', [
      md.Text(match[2]!),
    ])
      ..attributes.addAll({'display': display.toString()});
    parser.addNode(elm);
    return true;
  }
}

class MathBuilder extends MarkdownElementBuilder {
  final double fontScale;
  MathBuilder({this.fontScale = 1});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final display = element.attributes['display']! == 'true';
    final source = element.children!.single.textContent;
    return MathWidget(
      source: source,
      display: display,
      fontSize: 16 * fontScale,
    );
  }
}
