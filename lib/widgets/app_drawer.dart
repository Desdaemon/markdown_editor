import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../providers.dart';

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
                  final file = await PlatformAssetBundle().loadString('assets/markdown_reference.md');
                  ref.read(sourceProvider.notifier).syncControllerWithBuffer(file);
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
                ),
              OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('New buffer'),
                onPressed: () {
                  ref.read(sourceProvider.notifier).newBuffer();
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.folder_open),
                label: const Text('Open'),
                onPressed: () {
                  ref.read(sourceProvider.notifier).open();
                },
              ),
            ]),
          ),
        ),
        const SliverPadding(
          padding: EdgeInsets.only(top: 8),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed([
              Center(child: Text('Buffers')),
              Divider(),
            ]),
          ),
        ),
        Consumer(builder: (bc, ref, _) {
          final prov = ref.watch(sourceProvider);
          final buffers = prov.activeBuffers;
          final activeIndex = prov.currentBufferIndex;
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (bc, idx) {
                final buffer = buffers[idx];
                return ListTile(
                  title: Text(buffer.title),
                  selected: idx == activeIndex,
                  onTap: () {
                    ref.read(sourceProvider.notifier).switchBuffer(idx);
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      ref.read(sourceProvider.notifier).removeBuffer(idx);
                    },
                  ),
                );
              },
              childCount: buffers.length,
            ),
          );
        }),
      ]),
    );
  }
}
