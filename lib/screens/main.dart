import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_editor/widgets/bottom_bar.dart';
import 'package:markdown_editor/widgets/custom_markdown.dart';
import 'package:universal_io/io.dart';

import '../providers.dart';

class Main extends StatefulWidget {
  final String? initialValue;
  const Main({Key? key, this.initialValue}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MainState();
}

class _MainState extends State<Main> {
  static final _isMobile = Platform.isAndroid || Platform.isIOS;
  Widget? _cache;

  final previewScrollController = ScrollController();

  @override
  void dispose() {
    super.dispose();
    timer?.cancel();
    previewScrollController.dispose();
  }

  Timer? timer;

  Widget buildEditor(BuildContext bc, WidgetRef ref, Widget? _) {
    return NotificationListener<ScrollUpdateNotification>(
      onNotification: (noti) {
        if (!previewScrollController.hasClients) return false;
        final extent = previewScrollController.position.maxScrollExtent / noti.metrics.maxScrollExtent;
        previewScrollController.jumpTo(noti.metrics.pixels * extent);
        return true;
      },
      child: TextField(
        decoration: const InputDecoration.collapsed(hintText: null),
        maxLines: null,
        expands: true,
        style: const TextStyle(fontFamily: 'JetBrains Mono'),
        controller: ref.watch(editorTextControllerProvider),
        onChanged: ref.read(sourceProvider.notifier).setBuffer,
      ),
    );
  }

  Widget buildPreview(BuildContext bc, WidgetRef ref, Widget? _) {
    final ast = ref.watch(astProvider);
    if (ast.asData?.value == null) {
      return _cache ?? const SizedBox();
    }
    return _cache = CustomMarkdownWidget(
      ast: ast.asData!.value!,
      padding: EdgeInsets.zero,
      controller: previewScrollController,
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(bc)).merge(MarkdownStyleSheet(
        textScaleFactor: 1,
        code: const TextStyle(
          fontFamily: 'JetBrains Mono',
        ),
      )),
    );
  }

  Widget buildPage(BuildContext bc, BoxConstraints cons) {
    final vertical = cons.maxWidth <= 768;
    final children = <Widget>[
      Expanded(
        child: Padding(
          padding: vertical
              ? const EdgeInsets.fromLTRB(16, 0, 16, 8)
              : _isMobile
                  ? const EdgeInsets.fromLTRB(16, 32, 8, 8)
                  : const EdgeInsets.fromLTRB(16, 16, 8, 8),
          child: Consumer(builder: buildEditor),
        ),
      ),
      if (vertical) const Divider() else const VerticalDivider(),
      Expanded(
        child: Container(
          alignment: Alignment.topLeft,
          padding: vertical
              ? _isMobile
                  ? const EdgeInsets.fromLTRB(16, 32, 16, 0)
                  : const EdgeInsets.fromLTRB(16, 16, 16, 8)
              : _isMobile
                  ? const EdgeInsets.fromLTRB(8, 32, 16, 8)
                  : const EdgeInsets.fromLTRB(8, 16, 16, 8),
          child: Consumer(builder: buildPreview),
        ),
      )
    ];
    return Column(
      children: [
        if (vertical)
          ...children.reversed
        else
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        const BottomBar(),
      ],
    );
  }

  @override
  Widget build(context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        body: LayoutBuilder(builder: buildPage),
      ),
    );
  }
}
