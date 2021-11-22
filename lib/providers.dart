import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:text/text.dart';
import 'package:universal_io/io.dart';
import 'package:file_picker/file_picker.dart';

import 'core/core.dart';
import 'element.dart';

final firebaseProvider = FutureProvider((_) => Firebase.initializeApp());
final sharedPrefsProvider = FutureProvider((_) => SharedPreferences.getInstance());
final initializedProvider = Provider((ref) => ref.watch(sharedPrefsProvider).asData != null);
final handlerProvider = Provider((ref) => TextControllerHandler(ref));
final userProvider = StreamProvider((_) => FirebaseAuth.instance.userChanges());
final uidProvider = Provider((ref) => ref.watch(userProvider).asData?.value?.uid);
final buffersCollection = FirebaseFirestore.instance.collection('buffers').withConverter<Buffer>(
      fromFirestore: (doc, _) => Buffer.fromJson({
        ...doc.data()!,
        'id': doc.id,
      }),
      toFirestore: (buf, _) => buf.toJson(),
    );
final buffersProvider = FutureProvider((ref) async {
  final user = ref.watch(userProvider).asData?.value;
  if (user != null) {
    final snap = await buffersCollection.where('uid', isEqualTo: user.uid).where('removed', isNotEqualTo: true).get();
    return snap.docs.map((e) => e.data()).toList(growable: false);
  }
});

final sourceProvider = StateNotifierProvider<AppNotifier, AppModel>((ref) {
  final s = ref.watch(sharedPrefsProvider);
  return AppNotifier.fromPref(s.asData?.value, ref, seed: ref.watch(buffersProvider).asData?.value);
});

final dirtyProvider = Provider((ref) {
  final source = ref.watch(sourceProvider);
  final buffers = source.activeBuffers;
  final index = source.currentBufferIndex;
  return buffers[index].dirty;
});

final astProvider = FutureProvider((ref) async {
  final source = ref.watch(sourceProvider);
  final ast = await parse(markdown: source.buffer);
  return ast?.map(ElementAdapter.from).toList();
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

// ------------------------ class definitions -----------------------------------

class Buffer {
  /// Firebase ID
  final String? id;

  /// UID of this buffer's owner
  final String? uid;

  /// Name of the buffer on Firebase and local storage
  final String value;

  /// Whether this buffer needs saving. Do not persist.
  final bool dirty;

  /// The real path of this buffer. Local only.
  final String? path;

  /// Contents from Firebase
  final String? contents;

  /// Removed from online persistence
  final bool removed;

  const Buffer(
    this.value, {
    required this.dirty,
    required this.contents,
    required this.uid,
    required this.removed,
    required this.id,
    this.path,
  })  : assert(id == null || path == null, 'Expected Firebase buffer to have no path, got $path'),
        assert(id == null || contents != null, 'Expected Firebase buffer to include content'),
        assert(id == null || uid != null, 'Expected Firebase buffer to have UID');

  Buffer copyWith({
    String? value,
    bool? dirty,
    String? path,
    String? contents,
    String? uid,
    bool? removed,
    String? id,
  }) {
    return Buffer(
      value ?? this.value,
      dirty: dirty ?? this.dirty,
      path: path ?? this.path,
      contents: contents ?? this.contents,
      uid: uid ?? this.uid,
      removed: removed ?? this.removed,
      id: id ?? this.id,
    );
  }

  Map<String, dynamic> toJson() => {
        'value': value,
        'path': path,
        'contents': contents,
        'uid': uid,
        'removed': removed,
      };

  @override
  String toString() {
    return 'Buffer { id: $id, uid: $uid, value: $value }';
  }

  static Buffer fromJson(Map<String, dynamic> json) {
    log('new buffer from json', json);
    return Buffer(
      json['value'],
      id: json['id'],
      dirty: false,
      path: json['path'],
      contents: json['contents'],
      uid: json['uid'],
      removed: json['removed'],
    );
  }

  String get title => value + (dirty ? ' •' : '');

  /// Writes to [path] the given contents if [path] is not null.
  Future<void> writeFile(String contents) async {
    if (path != null) await File(path!).writeAsString(contents, flush: true);
  }

  static Future<Buffer> persistFirebase(Buffer buf) async {
    log('buf.id=${buf.id}');
    if (buf.id == null) {
      final ref = await buffersCollection.add(buf);
      return buf.copyWith(id: ref.id);
    } else {
      await buffersCollection.doc(buf.id).update(buf.toJson());
      return buf;
    }
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

  List<String> bufferKeys() => activeBuffers.map((e) => e.value).toList(growable: false);
}

class AppNotifier extends StateNotifier<AppModel> {
  static const _activeBufferKey = '__activeBuffers__';
  static const _currentBufferIndexKey = '__currentBufferIndex__';
  static const _delay = Duration(milliseconds: 400);
  final SharedPreferences? sharedPrefs;
  final TextEditingController controller;
  final ProviderRefBase ref;

  Timer? timer;
  AppNotifier({
    required this.controller,
    required List<Buffer> activeBuffers,
    required int currentBufferIndex,
    required this.ref,
    String? buffer,
    this.sharedPrefs,
  }) : super(AppModel(
          buffer: buffer ?? '',
          activeBuffers: activeBuffers,
          currentBufferIndex: currentBufferIndex,
        ));

  /// Non-null if [loggedIn] is true.
  String? get uid => ref.watch(uidProvider);
  bool get loggedIn => uid != null;

  factory AppNotifier.fromPref(SharedPreferences? pref, ProviderRefBase ref, { List<Buffer>? seed }) {
    final buffers = seed ??
        pref?.getStringList(_activeBufferKey)?.map((source) => Buffer.fromJson(jsonDecode(source))).toList() ??
        [Buffer('source', dirty: false, contents: null, uid: ref.read(uidProvider), removed: false, id: null)];
    log(buffers);
    final active = pref?.getInt(_currentBufferIndexKey) ?? 0;
    final buffer = pref?.getString(buffers[active].value);
    return AppNotifier(
      buffer: buffer,
      currentBufferIndex: active,
      activeBuffers: buffers,
      sharedPrefs: pref,
      controller: TextEditingController(text: buffer),
      ref: ref,
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
  Future<void> newBuffer({
    String? bufferName,
    String? contents,
    String? path,
  }) async {
    contents ??= '';
    final _contents = loggedIn ? contents : null;
    state = state.copyWith(
      buffer: contents,
      currentBufferIndex: state.activeBuffers.length,
      activeBuffers: [
        ...state.activeBuffers,
        Buffer(
          bufferName ?? newBufferName,
          dirty: false,
          path: path,
          contents: _contents,
          uid: uid,
          removed: false,
          id: null,
        )
      ],
    );
    controller.text = contents;
    await persist(buffer: true, activeBuffers: true, currentBufferIndex: true);
  }

  Future<void> persist({
    bool buffer = false,
    bool activeBuffers = false,
    bool currentBufferIndex = false,
  }) async {
    final online = loggedIn;
    if (activeBuffers) {
      await sharedPrefs?.setStringList(
        _activeBufferKey,
        state.activeBuffers.map((e) => jsonEncode(e.toJson())).toList(growable: false),
      );
      if (online) {
        final bufs = await Stream.fromFutures(state.activeBuffers.map(Buffer.persistFirebase)).toList();
        state = state.copyWith(activeBuffers: bufs);
      }
    }
    if (currentBufferIndex) {
      await sharedPrefs?.setInt(_currentBufferIndexKey, state.currentBufferIndex);
    }
    if (buffer) {
      final buf = activeBuffer;
      await sharedPrefs?.setString(buf.value, state.buffer);
      await activeBuffer.writeFile(state.buffer);
      // don't persist anymore, activeBuffers branch should have covered this
      if (online && !activeBuffers) {
        final res = await Buffer.persistFirebase(buf);
        state = state.copyWith(activeBuffers: [
          for (final i in state.activeBuffers)
            if (i.value == res.value) res else i
        ]);
      }
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
    final contents = loggedIn ? buffer : '';
    state = state.copyWith(
      buffer: buffer,
      activeBuffers: [
        for (final b in state.activeBuffers)
          if (idx++ == state.currentBufferIndex) b.copyWith(dirty: true, contents: contents) else b
      ],
    );
  }

  /// Sets the buffer *and* the text controller's contents together.
  void syncControllerWithBuffer(String buffer) {
    controller.text = buffer;
    immediatelySetBuffer(buffer);
  }

  /// Saves the current buffer.
  Future<void> save() async {
    if (!activeBuffer.dirty) return;
    int idx = 0;
    state = state.copyWith(
      activeBuffers: [
        for (final b in state.activeBuffers)
          if (idx++ == state.currentBufferIndex) b.copyWith(dirty: false) else b
      ],
    );
    await persist(buffer: true);
  }

  Future<String> bufferContent(int index) async {
    final activeBuffer = state.activeBuffers[index];
    return activeBuffer.contents ?? (await bufferContentFromStorage(activeBuffer.value)) ?? '';
  }

  Future<String?> bufferContentFromStorage(String key) async {
    return await SynchronousFuture(sharedPrefs?.getString(key)) ??
        (await buffersCollection.where('value', isEqualTo: key).where('uid', isEqualTo: uid).limit(1).get())
            .docs
            .first
            .data()
            .contents;
  }

  Future<void> switchBuffer(int index) async {
    assert(0 <= index && index < state.activeBuffers.length, "Index should be in bounds");
    await save();
    controller.text = await bufferContent(index);
    state = state.copyWith(currentBufferIndex: index, buffer: controller.text);
    await persist(currentBufferIndex: true);
  }

  void nextBuffer() => switchBuffer((state.currentBufferIndex + 1) % state.activeBuffers.length);

  /// Clears all buffers.
  Future<void> clearBuffers() async {
    controller.clear();
    await Stream.fromFutures(state.activeBuffers.map(removeFromFirebase)).drain();
    final contents = loggedIn ? '' : null;
    state = state.copyWith(
      buffer: '',
      activeBuffers: [
        Buffer(
          'Untitled',
          dirty: false,
          contents: contents,
          uid: uid,
          removed: false,
          id: null,
        )
      ],
      currentBufferIndex: 0,
    );
    await persist(buffer: true, activeBuffers: true, currentBufferIndex: true);
  }

  /// Removes the buffer at [index], or clear all buffers if there is only one buffer left.
  Future<void> removeBuffer(int index) async {
    assert(0 <= index && index < state.activeBuffers.length, "Index should be in bounds");
    if (state.activeBuffers.length == 1) return await clearBuffers();
    int newIndex = max(0, index - 1);
    final activeBuffers = state.activeBuffers.toList();
    await removeFromFirebase(activeBuffers.removeAt(index));
    state = state.copyWith(
      currentBufferIndex: newIndex,
      activeBuffers: activeBuffers,
    );
    controller.text = activeBufferContent;
    state = state.copyWith(buffer: controller.text);
    await persist(activeBuffers: true, currentBufferIndex: true);
  }

  Future<void> removeFromFirebase(Buffer b) async {
    if (loggedIn && b.id != null) {
      await buffersCollection.doc(b.id).update({'removed': true});
    }
  }

  String get activeBufferContent {
    return sharedPrefs?.getString(activeBuffer.value) ?? '';
  }

  Future<void> open() async {
    final result = await FilePicker.platform.pickFiles(
      allowedExtensions: const ['md', 'txt'],
      withReadStream: true,
    );
    if (result == null) return;
    final file = result.files.single;
    final path = file.path;
    assert((file.path != null) || (file.readStream != null), "Either path or readStream has to be present");
    String contents;
    if (path == null) {
      contents = await file.readStream!.map(const Utf8Decoder().convert).single;
    } else {
      contents = await File(path).readAsString();
    }
    await newBuffer(bufferName: file.name, path: path, contents: contents);
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
    final index = pref.getInt(persistKey) ?? ThemeState.system.themeMode.index;
    return ThemeNotifier(theme: ThemeState.fromIndex(index), pref: pref);
  }

  ThemeState next() {
    pref?.setInt(persistKey, state.next.themeMode.index);
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
  set state(double _state) {
    pref?.setDouble(persistKey, _state);
    super.state = _state;
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
