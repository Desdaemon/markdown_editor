import 'dart:async';

import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:text/text.dart';

import 'core/core.dart';
import 'element.dart';

final sharedPrefsProvider = FutureProvider((_) => SharedPreferences.getInstance());
final editorTextControllerProvider = Provider((ref) {
  final s = ref.watch(sharedPrefsProvider);
  final data = s.asData;
  if (data != null) {
    return TextEditingController(text: data.value.getString('source') ?? '');
  }
});
// final editorFocusNode = Provider((_) => FocusNode());
final handlerProvider = Provider((ref) => TextControllerHandler(ref));

final sourceProvider = StateNotifierProvider<AppNotifier, AppModel>((ref) {
  final s = ref.watch(sharedPrefsProvider);
  final data = s.asData;
  if (data != null) {
    return AppNotifier(
      sharedPrefs: data.value,
      buffer: data.value.getString('source') ?? '',
    );
  } else {
    return AppNotifier();
  }
});

final astProvider = FutureProvider((ref) async {
  final source = ref.watch(sourceProvider);
  final ast = await parse(markdown: source.buffer);
  return ast?.map(ElementAdapter.from).toList();
});

final themeModeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  final s = ref.watch(sharedPrefsProvider);
  final data = s.asData;
  if (data != null) {
    final index = data.value.getInt('tm') ?? ThemeMode.system.index;
    return ThemeNotifier(
      pref: data.value,
      theme: ThemeState.fromIndex(index),
    );
  } else {
    return ThemeNotifier();
  }
});

final visibiiltyProvider = StateNotifierProvider<VisibilityNotifier, VisibilityState>((ref) {
  final s = ref.watch(sharedPrefsProvider);
  final data = s.asData;
  if (data != null) {
    final index = data.value.getInt('vis') ?? VisibilityStates.sbs.index;
    return VisibilityNotifier(
      pref: data.value,
      visibility: VisibilityState.fromIndex(index),
    );
  } else {
    return VisibilityNotifier();
  }
});

// ------------------------ class definitions -----------------------------------

class AppModel {
  final String buffer;
  final List<String> activeBuffers;
  final int currentBufferIndex;
  const AppModel({
    required this.buffer,
    required this.activeBuffers,
    required this.currentBufferIndex,
  });

  AppModel copyWith({String? buffer, List<String>? activeBuffers, int? currentBufferIndex}) {
    return AppModel(
      buffer: buffer ?? this.buffer,
      activeBuffers: activeBuffers ?? this.activeBuffers,
      currentBufferIndex: currentBufferIndex ?? this.currentBufferIndex,
    );
  }
}

class AppNotifier extends StateNotifier<AppModel> {
  final SharedPreferences? sharedPrefs;
  Timer? timer;
  AppNotifier({
    this.sharedPrefs,
    String buffer = '',
  }) : super(AppModel(buffer: buffer, activeBuffers: [], currentBufferIndex: -1));

  void setBuffer(String buffer) {
    timer?.cancel();
    timer = Timer(const Duration(milliseconds: 400), () {
      immediatelySetBuffer(buffer);
    });
  }

  void immediatelySetBuffer(String buffer) {
    state = state.copyWith(buffer: buffer);
  }

  void save() {
    if (state.currentBufferIndex != -1) {
      sharedPrefs?.setString(state.activeBuffers[state.currentBufferIndex], state.buffer);
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

  static const light = ThemeState(
    themeMode: ThemeMode.light,
    message: 'Light Mode',
    icon: Icons.brightness_high,
  );

  static const dark = ThemeState(
    themeMode: ThemeMode.dark,
    message: 'Dark Mode',
    icon: Icons.brightness_2,
  );

  static const system = ThemeState(
    themeMode: ThemeMode.system,
    message: 'Follow System',
    icon: Icons.brightness_auto,
  );

  ThemeState get next {
    switch (themeMode) {
      case ThemeMode.light:
        return dark;
      case ThemeMode.dark:
        return system;
      case ThemeMode.system:
        return light;
    }
  }

  static ThemeState fromIndex(int index) {
    switch (ThemeMode.values[index]) {
      case ThemeMode.light:
        return dark;
      case ThemeMode.dark:
        return system;
      case ThemeMode.system:
        return light;
    }
  }
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  final SharedPreferences? pref;
  ThemeNotifier({ThemeState? theme, this.pref}) : super(theme ?? ThemeState.system);

  ThemeState next() {
    pref?.setInt('tm', state.next.themeMode.index);
    return state = state.next;
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

  static const editor = VisibilityState(
    visibiilty: VisibilityStates.editor,
    icon: Icons.edit,
    message: 'Edit',
  );
  static const preview = VisibilityState(
    visibiilty: VisibilityStates.preview,
    icon: Icons.visibility,
    message: 'Preview',
  );
  static const sbs = VisibilityState(
    visibiilty: VisibilityStates.sbs,
    icon: Icons.vertical_split,
    message: 'Side-by-side',
  );
  static const sbsUnlocked = VisibilityState(
    visibiilty: VisibilityStates.sbsUnlocked,
    icon: Icons.lock_open,
    message: 'Side-by-side (unlocked)',
  );

  VisibilityState get next {
    switch (visibiilty) {
      case VisibilityStates.sbs:
        return sbsUnlocked;
      case VisibilityStates.sbsUnlocked:
        return editor;
      case VisibilityStates.editor:
        return preview;
      case VisibilityStates.preview:
        return sbs;
    }
  }

  factory VisibilityState.fromIndex(int index) {
    switch (VisibilityStates.values[index]) {
      case VisibilityStates.editor:
        return editor;
      case VisibilityStates.preview:
        return preview;
      case VisibilityStates.sbs:
        return sbs;
      case VisibilityStates.sbsUnlocked:
        return sbsUnlocked;
    }
  }

  bool get editing => visibiilty != VisibilityStates.preview;
  bool get previewing => visibiilty != VisibilityStates.editor;
  bool get doSyncScroll => visibiilty == VisibilityStates.sbs;
  bool get sideBySide => visibiilty == VisibilityStates.sbs || visibiilty == VisibilityStates.sbsUnlocked;
}

class VisibilityNotifier extends StateNotifier<VisibilityState> {
  final SharedPreferences? pref;
  VisibilityNotifier({VisibilityState? visibility, this.pref}) : super(visibility ?? VisibilityState.sbs);

  VisibilityState next() {
    pref?.setInt('vis', state.next.visibiilty.index);
    return state = state.next;
  }
}

class TextControllerHandler {
  final ProviderRef<void> ref;
  const TextControllerHandler(this.ref);

  TextEditingController? get controller => ref.read(editorTextControllerProvider);
  AppNotifier get source => ref.read(sourceProvider.notifier);

  void wrap({required String left, String? right}) {
    final ctl = controller;
    if (ctl == null) return;
    final _right = right ?? left;
    final sel = ctl.selection;
    final text = ctl.text;
    final output = [sel.textBefore(text), left, sel.textInside(text), _right, sel.textAfter(text)].join();
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

  void selectLine() {
    final ctl = controller;
    if (ctl == null) return;
    final text = Text(ctl.text);
    final line = text.line(text.locationAt(ctl.selection.start).line - 1);
    ctl.selection = TextSelection(
      baseOffset: line.start,
      extentOffset: line.end,
    );
  }
}
