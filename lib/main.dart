import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:markdown_editor/color_schemes.dart';
import 'package:markdown_editor/providers.dart';
import 'package:markdown_editor/screens/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:statsfl/statsfl.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (_, ref, child) {
        return MaterialApp(
          title: 'Flutter Demo',
          debugShowCheckedModeBanner: false,
          theme: ThemeData.from(colorScheme: ayuLight),
          darkTheme: ThemeData.from(colorScheme: ayuDark),
          themeMode: ref.watch(themeModeProvider).themeMode,
          home: child!,
        );
      },
      child: StatsFl(isEnabled: !kReleaseMode, align: Alignment.topRight, child: const Main()),
    );
  }
}
