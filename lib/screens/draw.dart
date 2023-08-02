import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_editor/providers.dart';
import 'package:scribble/scribble.dart';

class DrawScreen extends StatelessWidget {
  const DrawScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drawing'),
      ),
      endDrawer: Drawer(
        child: ListView(
          children: [
            const Text('Settings', textAlign: TextAlign.center),
            const Divider(),
            ListTile(
              title: const Text('Stroke width'),
              subtitle: Consumer(
                builder: (bc, ref, _) {
                  final value = ref.watch(scribbleProvider).selectedWidth;
                  return Slider(
                    value: value,
                    min: 0,
                    max: 20,
                    onChanged: ref.read(scribbleProvider.notifier).setStrokeWidth,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Consumer(
        builder: (bc, ref, _) {
          return FloatingActionButton(
            onPressed: () {
              ref.read(scribbleProvider.notifier)
                ..clear()
                ..setColor(Theme.of(bc).textTheme.bodyMedium!.color!);
            },
            child: const Icon(Icons.cancel),
          );
        },
      ),
      body: Consumer(
        builder: (bc, ref, _) {
          return InteractiveViewer(
            child: Scribble(
              notifier: ref.watch(scribbleProvider.notifier),
            ),
          );
        },
      ),
    );
  }
}
