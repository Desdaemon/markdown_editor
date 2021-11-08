import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_editor/widgets/app_drawer.dart';
import 'package:markdown_editor/widgets/bottom_bar.dart';
import 'package:markdown_editor/widgets/custom_markdown.dart';
import 'package:universal_io/io.dart';

import '../formatters.dart';
import '../providers.dart';

class Main extends ConsumerStatefulWidget {
  final String? initialValue;
  const Main({Key? key, this.initialValue}) : super(key: key);

  @override
  ConsumerState<Main> createState() => _MainState();
}

class EventHandler {
  final bool ctrl;
  final bool alt;
  final bool meta;
  final bool shift;
  final String? description;
  final PhysicalKeyboardKey key;
  final KeyEventResult? Function(WidgetRef ref, RawKeyEvent event) onEvent;

  const EventHandler({
    required this.key,
    required this.onEvent,
    this.ctrl = false,
    this.alt = false,
    this.meta = false,
    this.shift = false,
    this.description,
  });

  KeyEventResult? handle(RawKeyEvent event, WidgetRef ref) {
    if (event.physicalKey == key &&
        (!ctrl || event.isControlPressed) &&
        (!alt || event.isAltPressed) &&
        (!meta || event.isMetaPressed) &&
        (!shift || event.isShiftPressed)) {
      if (description != null) debugPrint(description);
      return onEvent(ref, event);
    }
  }
}

class _MainState extends ConsumerState<Main> {
  static final _isMobile = Platform.isAndroid || Platform.isIOS;
  Widget? _cache;
  Timer? timer;

  final previewScrollController = ScrollController();
  final _node = FocusNode();

  @override
  void dispose() {
    super.dispose();
    timer?.cancel();
    _node.dispose();
    previewScrollController.dispose();
  }

  static final _handlers = <EventHandler>[
    EventHandler(
      key: PhysicalKeyboardKey.tab,
      onEvent: (ref, _) {
        ref.read(handlerProvider).tab();
      },
    ),
    EventHandler(
      key: PhysicalKeyboardKey.keyL,
      ctrl: true,
      description: 'Select line',
      onEvent: (ref, _) {
        ref.read(handlerProvider).selectLine();
      },
    ),
    EventHandler(
      key: PhysicalKeyboardKey.keyM,
      ctrl: true,
      shift: true,
      description: 'Insert math environment',
      onEvent: (ref, _) {
        ref.read(handlerProvider).mathEnvironment('aligned');
      },
    ),
    EventHandler(
      key: PhysicalKeyboardKey.keyM,
      ctrl: true,
      shift: true,
      description: 'Math block (display)',
      onEvent: (ref, event) {
        ref.read(handlerProvider).wrap(left: r'$$');
      },
    ),
    EventHandler(
      key: PhysicalKeyboardKey.keyM,
      ctrl: true,
      description: 'Math block (text)',
      onEvent: (ref, event) {
        ref.read(handlerProvider).mathText();
      },
    ),
    EventHandler(
      key: PhysicalKeyboardKey.keyB,
      ctrl: true,
      description: 'Bold',
      onEvent: (ref, _) {
        ref.read(handlerProvider).bold();
      },
    ),
    EventHandler(
      key: PhysicalKeyboardKey.keyI,
      ctrl: true,
      description: 'Italic',
      onEvent: (ref, _) {
        ref.read(handlerProvider).italic();
      },
    ),
    EventHandler(
      key: PhysicalKeyboardKey.keyS,
      alt: true,
      description: 'Bold',
      onEvent: (ref, _) {
        ref.read(handlerProvider).strikethrough();
      },
    ),
    EventHandler(
      key: PhysicalKeyboardKey.keyS,
      ctrl: true,
      description: 'Save',
      onEvent: (ref, _) {
        ref.read(sourceProvider.notifier).save();
      },
    )
  ];

  KeyEventResult onKey(FocusNode node, RawKeyEvent event) {
    if (event is! RawKeyUpEvent) return KeyEventResult.ignored;
    KeyEventResult? res;
    for (final handler in _handlers) {
      if ((res = handler.handle(event, ref)) != null) {
        return res!;
      }
    }
    return KeyEventResult.ignored;
  }

  Widget buildEditor(BuildContext bc, WidgetRef ref, Widget? _) {
    return NotificationListener<ScrollUpdateNotification>(
      onNotification: (noti) {
        return ref.read(visibiiltyProvider).doSyncScroll ? onScrolNotification(noti) : false;
      },
      child: FocusScope(
        onKey: onKey,
        child: TextField(
          decoration: const InputDecoration.collapsed(hintText: null),
          maxLines: null,
          expands: true,
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: ref.watch(fontSizeProvider),
          ),
          controller: ref.watch(sourceProvider.notifier).controller,
          focusNode: _node,
          onChanged: ref.read(sourceProvider.notifier).setBuffer,
          inputFormatters: [
            NewlineFormatter(),
          ],
        ),
      ),
    );
  }

  bool onScrolNotification(ScrollUpdateNotification noti) {
    if (!previewScrollController.hasClients) return false;
    final extent = previewScrollController.position.maxScrollExtent / noti.metrics.maxScrollExtent;
    previewScrollController.jumpTo(noti.metrics.pixels * extent);
    return true;
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
      lazy: !ref.watch(visibiiltyProvider).doSyncScroll,
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(bc)).merge(MarkdownStyleSheet(
        textScaleFactor: ref.watch(fontSizeProvider) / FontSizeNotifier.baseSize,
        code: const TextStyle(
          fontFamily: 'JetBrains Mono',
        ),
      )),
    );
  }

  Widget buildPage(BuildContext bc, BoxConstraints cons) {
    final vertical = cons.maxWidth <= 768;
    return Consumer(builder: (bc, ref, _) {
      final vis = ref.watch(visibiiltyProvider);
      final children = <Widget>[
        if (vis.editing)
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
        if (vertical && vis.sideBySide) const Divider(),
        if (!vertical && vis.sideBySide) const VerticalDivider(),
        if (vis.previewing)
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
    });
  }

  @override
  Widget build(context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        endDrawer: const AppDrawer(),
        body: LayoutBuilder(builder: buildPage),
      ),
    );
  }
}
