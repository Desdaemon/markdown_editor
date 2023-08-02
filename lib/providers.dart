import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scribble/scribble.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:text/text.dart';
import 'package:universal_io/io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:markdown/markdown.dart' as md;

import 'helpers/helpers.dart'
    if (dart.library.io) 'helpers/helpers.io.dart'
    if (dart.library.html) 'helpers/helpers.web.dart';

final sharedPrefsProvider = FutureProvider((_) => SharedPreferences.getInstance());
final initializedProvider = Provider<bool>((ref) => ref.watch(sharedPrefsProvider).asData != null);
final handlerProvider = Provider((ref) => TextControllerHandler(ref));

final sourceProvider = StateNotifierProvider<AppNotifier, AppModel>((ref) {
  final s = ref.watch(sharedPrefsProvider);
  return AppNotifier.fromPref(s.asData?.value);
});

final dirtyProvider = Provider((ref) {
  final source = ref.watch(sourceProvider);
  final buffers = source.activeBuffers;
  final index = source.currentBufferIndex;
  return buffers[index].dirty;
});

final bufferProvider = Provider((ref) => ref.watch(sourceProvider).buffer);

final astProvider = Provider((ref) {
  final source = ref.watch(bufferProvider);
  final doc = md.Document(
    extensionSet: md.ExtensionSet.gitHubWeb,
    inlineSyntaxes: [MathSyntax()],
    blockSyntaxes: const [md.UnorderedListWithCheckboxSyntax()],
  );
  return doc.parseLines(const LineSplitter().convert(source));
});

final themeModeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  final s = ref.watch(sharedPrefsProvider);
  return ThemeNotifier.fromPref(s.asData?.value);
});

final visibiiltyProvider = StateNotifierProvider<VisibilityNotifier, VisibilityState>((ref) {
  final s = ref.watch(sharedPrefsProvider);
  return VisibilityNotifier.fromPref(s.asData?.value);
});

final fontSizeProvider = StateNotifierProvider<FontSizeNotifier, double>((ref) {
  final s = ref.watch(sharedPrefsProvider);
  return FontSizeNotifier.fromPref(s.asData?.value);
});

final scribbleProvider =
    StateNotifierProvider<ScribbleNotifier, ScribbleState>((_) => ScribbleNotifier(maxHistoryLength: 100));

// ------------------------ class definitions -----------------------------------

class Buffer {
  final String value;
  final bool dirty;
  final String? path;
  const Buffer(this.value, {required this.dirty, this.path});

  Buffer copyWith({String? value, bool? dirty, String? path}) {
    return Buffer(
      value ?? this.value,
      dirty: dirty ?? this.dirty,
      path: path ?? this.path,
    );
  }

  Map<String, dynamic> toJson() => {
        'value': value,
        'dirty': dirty,
        'path': path,
      };
  static Buffer fromJson(Map<String, dynamic> json) => Buffer(
        json['value'],
        dirty: json['dirty'] == 'true',
        path: json['path'],
      );

  String get title => value + (dirty ? ' •' : '');

  /// Writes to [path] the given contents if [path] is not null.
  Future<void> writeFile(String contents) async {
    if (path != null) await File(path!).writeAsString(contents, flush: true);
  }
}

class AppModel {
  final String buffer;
  final List<Buffer> activeBuffers;
  final int currentBufferIndex;
  const AppModel({
    required this.buffer,
    required this.activeBuffers,
    required this.currentBufferIndex,
  });

  AppModel copyWith({
    String? buffer,
    List<Buffer>? activeBuffers,
    int? currentBufferIndex,
  }) {
    return AppModel(
      activeBuffers: activeBuffers ?? this.activeBuffers,
      currentBufferIndex: currentBufferIndex ?? this.currentBufferIndex,
      buffer: buffer ?? this.buffer,
    );
  }

  Buffer get currentBuffer => activeBuffers[currentBufferIndex];
  List<String> bufferKeys() => activeBuffers.map((e) => e.value).toList(growable: false);
}

class AppNotifier extends StateNotifier<AppModel> {
  static const _activeBufferKey = '__activeBuffers__';
  static const _currentBufferIndexKey = '__currentBufferIndex__';
  static const _delay = Duration(milliseconds: 400);
  final SharedPreferences? sharedPrefs;
  final TextEditingController controller;
  Timer? timer;
  AppNotifier({
    required this.controller,
    required List<Buffer> activeBuffers,
    required int currentBufferIndex,
    String? buffer,
    this.sharedPrefs,
  }) : super(AppModel(
          buffer: buffer ?? '',
          activeBuffers: activeBuffers,
          currentBufferIndex: currentBufferIndex,
        ));

  factory AppNotifier.fromPref(SharedPreferences? pref) {
    final buffers =
        pref?.getStringList(_activeBufferKey)?.map((source) => Buffer.fromJson(jsonDecode(source))).toList() ??
            [const Buffer('source', dirty: false)];
    final active = pref?.getInt(_currentBufferIndexKey) ?? 0;
    final buffer = pref?.getString(buffers[active].value);
    return AppNotifier(
      buffer: buffer,
      currentBufferIndex: active,
      activeBuffers: buffers,
      sharedPrefs: pref,
      controller: TextEditingController(text: buffer),
    );
  }

  String get newBufferName {
    final keys = state.bufferKeys();
    if (!keys.contains('Untitled')) return 'Untitled';
    int idx = 1;
    while (keys.contains('Untitled ($idx)')) {
      idx++;
    }
    return 'Untitled ($idx)';
  }

  /// Creates a new buffer with [bufferName].
  void newBuffer({
    String? bufferName,
    String? contents,
    String? path,
  }) {
    contents ??= '';
    state = state.copyWith(
      buffer: contents,
      currentBufferIndex: state.activeBuffers.length,
      activeBuffers: [
        ...state.activeBuffers,
        Buffer(
          bufferName ?? newBufferName,
          dirty: false,
          path: path,
        )
      ],
    );
    controller.text = contents;
    persist(buffer: true, activeBuffers: true, currentBufferIndex: true);
  }

  Future<void> persist({
    bool buffer = false,
    bool activeBuffers = false,
    bool currentBufferIndex = false,
  }) async {
    if (activeBuffers) {
      sharedPrefs?.setStringList(
        _activeBufferKey,
        state.activeBuffers.map((e) => jsonEncode(e.toJson())).toList(growable: false),
      );
    }
    if (currentBufferIndex) {
      sharedPrefs?.setInt(_currentBufferIndexKey, state.currentBufferIndex);
    }
    if (buffer) {
      sharedPrefs?.setString(activeBuffer.value, state.buffer);
      await activeBuffer.writeFile(state.buffer);
    }
  }

  /// Waits for [_delay] before updating the buffer.
  void setBuffer(String buffer) {
    timer?.cancel();
    timer = Timer(_delay, () {
      immediatelySetBuffer(buffer);
    });
  }

  Buffer get activeBuffer => state.activeBuffers[state.currentBufferIndex];

  /// Sets the current buffer to [buffer] and mark it as dirty.
  void immediatelySetBuffer(String buffer) {
    int idx = 0;
    state = state.copyWith(
      buffer: buffer,
      activeBuffers: [
        for (final b in state.activeBuffers)
          if (idx++ == state.currentBufferIndex) b.copyWith(dirty: true) else b
      ],
    );
  }

  /// Sets the buffer *and* the text controller's contents together.
  void syncControllerWithBuffer(String buffer) {
    controller.text = buffer;
    immediatelySetBuffer(buffer);
  }

  /// Saves the current buffer.
  void save() {
    if (!activeBuffer.dirty) return;
    int idx = 0;
    state = state.copyWith(
      activeBuffers: [
        for (final b in state.activeBuffers)
          if (idx++ == state.currentBufferIndex) b.copyWith(dirty: false) else b
      ],
    );
    persist(buffer: true, activeBuffers: true);
  }

  void switchBuffer(int index) {
    assert(0 <= index && index < state.activeBuffers.length, "Index should be in bounds");
    save();
    controller.text = sharedPrefs?.getString(state.activeBuffers[index].value) ?? '';
    state = state.copyWith(currentBufferIndex: index, buffer: controller.text);
    persist(currentBufferIndex: true);
  }

  void nextBuffer() => switchBuffer((state.currentBufferIndex + 1) % state.activeBuffers.length);

  /// Clears all buffers.
  void clearBuffers() {
    controller.clear();
    state = state.copyWith(
      buffer: '',
      activeBuffers: [const Buffer('Untitled', dirty: false)],
      currentBufferIndex: 0,
    );
    persist(buffer: true, activeBuffers: true, currentBufferIndex: true);
  }

  /// Removes the buffer at [index], or clear all buffers if there is only one buffer left.
  void removeBuffer(int index) {
    assert(0 <= index && index < state.activeBuffers.length, "Index should be in bounds");
    if (state.activeBuffers.length == 1) return clearBuffers();
    int newIndex = max(0, index - 1);
    int idx = 0;
    state = state.copyWith(
      currentBufferIndex: newIndex,
      activeBuffers: [
        for (final b in state.activeBuffers)
          if (idx++ != index) b
      ],
    );
    controller.text = sharedPrefs?.getString(activeBuffer.value) ?? '';
    state = state.copyWith(buffer: controller.text);
    persist(activeBuffers: true, currentBufferIndex: true);
  }

  Future<void> open() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['md', 'txt'],
    );
    if (result == null) return;
    final file = result.files.single;
    String contents;
    String? path;
    if (kIsWeb) {
      contents = const Utf8Decoder().convert(file.bytes!);
    } else {
      path = file.path;
      contents = await File(file.path!).readAsString();
    }
    newBuffer(bufferName: file.name, path: path, contents: contents);
  }

  void export(Exports type) {
    switch (type) {
      case Exports.htmlPlain:
        return _exportHtmlPlain();
      case Exports.html:
        return _exportHtml();
      case Exports.md:
        return _exportMarkdown();
    }
  }

  String _currentBufferAsHtml() => md.markdownToHtml(
        controller.text,
        extensionSet: md.ExtensionSet.gitHubWeb,
        blockSyntaxes: const [md.UnorderedListWithCheckboxSyntax()],
      );

  void _exportMarkdown() {
    final markdown = controller.text;
    if (markdown.isNotEmpty) {
      exportImpl(markdown, html: false, fileName: state.currentBuffer.title);
    }
  }

  void _exportHtmlPlain() {
    final html = _currentBufferAsHtml();
    if (html.isNotEmpty) {
      final title = state.currentBuffer.title;
      exportImpl(html, html: true, fileName: '$title-plain');
    }
  }

  void _exportHtml() {
    final body = _currentBufferAsHtml();
    if (body.isNotEmpty) {
      final title = state.currentBuffer.title;
      const template = '''
<!DOCTYPE html>
<html lang="en">
	<head>
		<meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
		<title>{{ title }}</title>
		<script>
			var media = matchMedia("(prefers-color-scheme: dark)");
			function onPreferredThemeChange(event) {
				var suffix = event.matches ? 'dark': 'light';
				var elm;
				if (elm = document.getElementById('markdown-style')) { elm.remove(); }
				var link = document.createElement('link');
				link.setAttribute('rel', 'stylesheet');
				link.setAttribute('href', `https://cdnjs.cloudflare.com/ajax/libs/github-markdown-css/5.0.0/github-markdown-\${suffix}.min.css`);
				link.setAttribute('id', 'markdown-style');
				document.head.appendChild(link);
			}
			onPreferredThemeChange(media);
			media.addEventListener('change', onPreferredThemeChange);
		</script>
		<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.13.0/dist/katex.min.css"
          integrity="sha384-t5CR+zwDAROtph0PXGte6ia8heboACF9R5l/DiY+WZ3P2lxNgvJkQk5n7GPvLMYw" crossorigin="anonymous">
    <script defer src="https://cdn.jsdelivr.net/npm/katex@0.13.0/dist/katex.min.js"
        integrity="sha384-FaFLTlohFghEIZkw6VGwmf9ISTubWAVYW8tG8+w2LAIftJEULZABrF9PPFv+tVkH"
        crossorigin="anonymous"></script>
    <script defer src="https://cdn.jsdelivr.net/npm/katex@0.13.0/dist/contrib/auto-render.min.js"
        integrity="sha384-bHBqxz8fokvgoJ/sc17HODNxa42TlaEhB+w8ZJXTc2nZf1VgEaFZeZvT4Mznfz0v"
        crossorigin="anonymous"></script>
    <script>
			document.addEventListener("DOMContentLoaded", function render() {
				renderMathInElement(document.body, {
					delimiters: [
						{ left: "\$\$", right: "\$\$", display: true },
						{ left: "\$", right: "\$", display: false }
					],
					throwOnError: false
				});
			});
    </script>
	</head>
	<body>
		<article class="markdown-body">{{ body }}</article>
		<style>
			body {
				margin: 0;
			}
			.markdown-body .task-list-item {
				list-style-type: none;
			}
			.markdown-body .task-list-item+.task-list-item {
				margin-top: 3px;
			}
			.markdown-body .task-list-item input {
				margin: 0 .2em .25em -1.6em;
				vertical-align: middle;
			}
			.markdown-body {
				box-sizing: border-box;
				min-width: 200px;
				max-width: 980px;
				margin: 0 auto;
				padding: 45px;
			}
			@media (max-width: 767px) {
				.markdown-body {
					padding: 15px;
				}
			}
			@media (prefers-color-scheme: dark) {
				body {
					background-color: #0d1117;
				}
			}
		</style>
	</body>
</html>''';
      final page = template.replaceFirst('{{ title }}', title).replaceFirst('{{ body }}', body);
      exportImpl(page, html: true, fileName: title);
    }
  }
}

class ThemeState {
  final ThemeMode themeMode;
  final IconData icon;
  final String message;
  const ThemeState({
    required this.themeMode,
    required this.icon,
    required this.message,
  });

  static const values = [
    ThemeState(
      themeMode: ThemeMode.system,
      message: 'Follow System',
      icon: Icons.brightness_auto,
    ),
    ThemeState(
      themeMode: ThemeMode.light,
      message: 'Light Mode',
      icon: Icons.brightness_high,
    ),
    ThemeState(
      themeMode: ThemeMode.dark,
      message: 'Dark Mode',
      icon: Icons.brightness_2,
    ),
  ];

  static ThemeState get system => values[0];

  ThemeState get next => values[(themeMode.index + 1) % values.length];

  static ThemeState fromIndex(int index) => values[index];
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  static const persistKey = 'tm';
  final SharedPreferences? pref;
  ThemeNotifier({ThemeState? theme, this.pref}) : super(theme ?? ThemeState.system);

  factory ThemeNotifier.fromPref(SharedPreferences? pref) {
    if (pref == null) return ThemeNotifier();
    return ThemeNotifier(theme: stateOf(pref), pref: pref);
  }

  ThemeState next() {
    pref?.setInt(persistKey, state.next.themeMode.index);
    return state = state.next;
  }

  static ThemeState stateOf(SharedPreferences pref) {
    final index = pref.getInt(persistKey) ?? ThemeState.system.themeMode.index;
    return ThemeState.fromIndex(index);
  }
}

enum VisibilityStates { editor, preview, sbs, sbsUnlocked }

class VisibilityState {
  final VisibilityStates visibiilty;
  final IconData icon;
  final String message;

  const VisibilityState({
    required this.visibiilty,
    required this.icon,
    required this.message,
  });

  static const values = [
    VisibilityState(
      visibiilty: VisibilityStates.editor,
      icon: Icons.edit,
      message: 'Edit',
    ),
    VisibilityState(
      visibiilty: VisibilityStates.preview,
      icon: Icons.visibility,
      message: 'Preview',
    ),
    VisibilityState(
      visibiilty: VisibilityStates.sbs,
      icon: Icons.vertical_split,
      message: 'Side-by-side',
    ),
    VisibilityState(
      visibiilty: VisibilityStates.sbsUnlocked,
      icon: Icons.lock_open,
      message: 'Side-by-side (unlocked)',
    ),
  ];

  static VisibilityState get sbs => values[2];

  VisibilityState get next => values[(visibiilty.index + 1) % values.length];

  factory VisibilityState.fromIndex(int index) => values[index];

  bool get editing => visibiilty != VisibilityStates.preview;
  bool get previewing => visibiilty != VisibilityStates.editor;
  bool get doSyncScroll => visibiilty == VisibilityStates.sbs;
  bool get sideBySide => visibiilty == VisibilityStates.sbs || visibiilty == VisibilityStates.sbsUnlocked;
}

class VisibilityNotifier extends StateNotifier<VisibilityState> {
  static const persistKey = '__vis__';
  final SharedPreferences? pref;
  VisibilityNotifier({VisibilityState? visibility, this.pref}) : super(visibility ?? VisibilityState.sbs);

  factory VisibilityNotifier.fromPref(SharedPreferences? pref) {
    if (pref == null) return VisibilityNotifier();
    final index = pref.getInt(persistKey) ?? VisibilityState.sbs.visibiilty.index;
    return VisibilityNotifier(visibility: VisibilityState.fromIndex(index), pref: pref);
  }

  VisibilityState next() {
    pref?.setInt(persistKey, state.next.visibiilty.index);
    return state = state.next;
  }
}

class FontSizeNotifier extends StateNotifier<double> {
  static const persistKey = '__fontSize__';
  final SharedPreferences? pref;
  static const baseSize = 14.0;
  FontSizeNotifier({double? fontSize, this.pref}) : super(fontSize ?? baseSize);

  factory FontSizeNotifier.fromPref(SharedPreferences? pref) {
    final data = pref?.getDouble(persistKey);
    return FontSizeNotifier(fontSize: data, pref: pref);
  }

  @override
  set state(double state) {
    pref?.setDouble(persistKey, state);
    super.state = state;
  }
}

class TextControllerHandler {
  final ProviderRef<void> ref;
  const TextControllerHandler(this.ref);

  AppNotifier get source => ref.read(sourceProvider.notifier);
  TextEditingController? get controller => source.controller;

  void wrap({
    required String left,
    String? right,
  }) {
    final ctl = controller;
    if (ctl == null) return;
    right ??= left;
    final sel = ctl.selection;
    final text = ctl.text;
    final output = [sel.textBefore(text), left, sel.textInside(text), right, sel.textAfter(text)].join();
    ctl.value = TextEditingValue(
      text: output,
      selection: sel.copyWith(
        baseOffset: sel.baseOffset + left.length,
        extentOffset: sel.extentOffset + left.length,
      ),
    );
    source.immediatelySetBuffer(output);
  }

  void bold() => wrap(left: '**');
  void italic() => wrap(left: '*');
  void strikethrough() => wrap(left: '~~');
  void mathText() => wrap(left: '\$');
  void mathEnvironment(String environment) => wrap(
        left: '\$\$\\begin{$environment}\n',
        right: '\\end{$environment}\$\$',
      );

  void tab({int length = 2}) {
    final ctl = controller;
    if (ctl == null) return;
    final indent = ''.padLeft(length);
    final sel = ctl.selection;
    final text = ctl.text;
    final output = [sel.textBefore(text), indent, sel.textInside(text), sel.textAfter(text)].join();
    ctl.value = TextEditingValue(
      text: output,
      selection: sel.copyWith(
        baseOffset: sel.baseOffset + length,
        extentOffset: sel.extentOffset + length,
      ),
    );
    source.immediatelySetBuffer(output);
  }

  Line _currentLine(Text text, TextEditingController ctl) {
    return text.line(text.locationAt(ctl.selection.start).line - 1);
  }

  void selectLine() {
    final ctl = controller;
    if (ctl == null) return;
    final text = Text(ctl.text);
    final line = _currentLine(text, ctl);
    ctl.selection = TextSelection(
      baseOffset: line.start,
      extentOffset: line.end,
    );
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

enum Exports { html, htmlPlain, md }
