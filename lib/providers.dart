import 'dart:async';

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
