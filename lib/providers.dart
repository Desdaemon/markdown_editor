import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'element.dart';

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

  void restore() {}

  void setBuffer(String buffer) {
    timer?.cancel();
    timer = Timer(const Duration(milliseconds: 400), () {
      state = state.copyWith(buffer: buffer);
    });
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
    icon: Icons.brightness_low,
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

final sharedPrefsProvider = FutureProvider((_) => SharedPreferences.getInstance());
final editorTextControllerProvider = Provider((ref) {
  final s = ref.watch(sharedPrefsProvider);
  final data = s.asData;
  if (data != null) {
    return TextEditingController(text: data.value.getString('source') ?? '');
  }
});

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
