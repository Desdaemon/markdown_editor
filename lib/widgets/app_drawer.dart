import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../providers.dart';

// final customButtonStyle = ButtonStyle(
// backgroundColor: MaterialStateProperty.all(const Color(0x5539bae6)),
// side: MaterialStateProperty.all(
// const BorderSide(
// color: Color(0xff39bae6),
// width: 2,
// ),
// ),
// );

class AppDrawer extends ConsumerWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: CustomScrollView(slivers: [
        const SliverList(
          delegate: SliverChildListDelegate.fixed([
            SizedBox(height: 48),
            Center(child: Text('Menu')),
            Divider(),
          ]),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3.0,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            delegate: SliverChildListDelegate.fixed([
              Consumer(builder: (_, ref, __) {
                final state = ref.watch(visibiiltyProvider);
                return OutlinedButton.icon(
                  icon: Icon(state.icon),
                  onPressed: ref.read(visibiiltyProvider.notifier).next,
                  label: Text(state.message),
                );
              }),
              Consumer(builder: (_, ref, __) {
                final state = ref.watch(themeModeProvider);
                return OutlinedButton.icon(
                  icon: Icon(state.icon),
                  onPressed: ref.read(themeModeProvider.notifier).next,
                  label: Text(state.message),
                );
              }),
              OutlinedButton.icon(
                icon: const Icon(Icons.monitor_weight),
                onPressed: () async {
                  final file = await PlatformAssetBundle().loadString('packages/markdown_reference.md');
                  ref.read(sourceProvider.notifier).setBuffer(file);
                  ref.read(editorTextControllerProvider)?.text = file;
                },
                label: const Text('Stress Test'),
              ),
              if (kDebugMode)
                OutlinedButton.icon(
                  icon: const Icon(Icons.format_paint),
                  onPressed: () {
                    debugRepaintRainbowEnabled = !debugRepaintRainbowEnabled;
                  },
                  label: const Text('Repaint rainbows'),
                )
            ]),
          ),
        )
      ]),
    );
  }
}
