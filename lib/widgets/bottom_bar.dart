import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_editor/providers.dart';
import 'package:markdown_editor/screens/draw.dart';

const environments = [
  'aligned',
  'alignedat',
  'matrix',
  'pmatrix',
  'bmatrix',
  'vmatrix',
  'Vmatrix',
  'Bmatrix',
  'smallmatrix',
  'array',
  'subarray',
  'cases',
  'rcases',
];

class BottomBar extends ConsumerWidget {
  const BottomBar({Key? key}) : super(key: key);

  static void noop() {}

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handler = ref.read(handlerProvider);
    return Material(
      color: Theme.of(context).bottomAppBarTheme.color,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.format_bold), onPressed: handler.bold, tooltip: 'Bold'),
                  IconButton(icon: const Icon(Icons.format_italic), onPressed: handler.italic, tooltip: 'Italic'),
                  IconButton(
                    icon: const Icon(Icons.palette),
                    onPressed: () {
                      ref.read(scribbleProvider.notifier).setColor(Theme.of(context).textTheme.bodyMedium!.color!);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const DrawScreen()));
                    },
                    tooltip: 'Insert drawing',
                  ),
                  IconButton(
                    icon: const Icon(Icons.format_strikethrough),
                    onPressed: handler.strikethrough,
                    tooltip: 'Strikethrough',
                  ),
                  InkResponse(
                    onTap: handler.mathText,
                    onLongPress: () {
                      Scaffold.of(context).showBottomSheet((bc) {
                        return ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: DraggableScrollableSheet(
                            initialChildSize: 0.5,
                            maxChildSize: 0.5,
                            expand: false,
                            builder: (bc, ctl) {
                              return ListView(
                                controller: ctl,
                                children: [
                                  Wrap(
                                    children: environments.map((env) {
                                      return InkWell(
                                        onTap: () {
                                          ref.read(handlerProvider).mathEnvironment(env);
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          child: Text(env, style: const TextStyle(fontFamily: 'JetBrains Mono')),
                                        ),
                                      );
                                    }).toList(growable: false),
                                  ),
                                ],
                              );
                            },
                          ),
                        );
                      }, elevation: 5);
                    },
                    // child: Ink(padding: const EdgeInsets.all(12), child: const Icon(Icons.functions)),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.functions),
                    ),
                  ),
                  // const IconButton(icon: Icon(Icons.format_indent_increase), onPressed: noop, tooltip: 'Indent'),
                  // const IconButton(icon: Icon(Icons.format_indent_decrease), onPressed: noop, tooltip: 'Dedent'),
                  Consumer(builder: (bc, ref, _) {
                    return IconButton(
                      icon: const Icon(Icons.save),
                      tooltip: 'Save',
                      onPressed: ref.watch(dirtyProvider)
                          ? () {
                              ref.read(sourceProvider.notifier).save();
                            }
                          : null,
                    );
                  })
                  // MouseRegion(
                  // cursor: SystemMouseCursors.click,
                  // child: GestureDetector(
                  // onTap: noop,
                  // child: const Text('Spaces: NaN'),
                  // ),
                  // ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: Scaffold.of(context).openEndDrawer,
            tooltip: 'Menu',
          )
        ],
      ),
    );
  }
}
