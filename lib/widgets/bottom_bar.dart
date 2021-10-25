import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_editor/providers.dart';

class BottomBar extends StatelessWidget {
  const BottomBar({Key? key}) : super(key: key);

  static void noop() {}

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).bottomAppBarColor,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Consumer(builder: (_, ref, __) {
                    final state = ref.watch(themeModeProvider);
                    return Tooltip(
                      message: state.message,
                      child: IconButton(
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(state.icon),
                        ),
                        onPressed: ref.read(themeModeProvider.notifier).next,
                      ),
                    );
                  }),
                  const IconButton(icon: Icon(Icons.format_bold), onPressed: noop, tooltip: 'Bold'),
                  const IconButton(icon: Icon(Icons.format_italic), onPressed: noop, tooltip: 'Italic'),
                  const IconButton(icon: Icon(Icons.format_strikethrough), onPressed: noop, tooltip: 'Strikethrough'),
                  const IconButton(icon: Icon(Icons.functions), onPressed: noop, tooltip: 'Math'),
                  const IconButton(icon: Icon(Icons.format_indent_increase), onPressed: noop, tooltip: 'Indent'),
                  const IconButton(icon: Icon(Icons.format_indent_decrease), onPressed: noop, tooltip: 'Dedent'),
                  Consumer(builder: (bc, ref, __) {
                    return IconButton(
                      icon: const Icon(Icons.save),
                      tooltip: 'Save',
                      // onPressed: ref.read(sourceProvider.notifier).save,
                      onPressed: () {
                        ref.read(sourceProvider.notifier).save();
                        ScaffoldMessenger.of(bc).showSnackBar(const SnackBar(
                          content: Text('Saved.'),
                          behavior: SnackBarBehavior.floating,
                          margin: EdgeInsets.fromLTRB(16, 0, 16, 48),
                          backgroundColor: Colors.green,
                        ));
                      },
                    );
                  }),
                  Consumer(builder: (_, ref, __) {
                    return IconButton(
                      icon: const Icon(Icons.monitor_weight),
                      tooltip: 'Stress Test',
                      onPressed: () async {
                        final file = await PlatformAssetBundle().loadString('packages/markdown_reference.md');
                        ref.read(sourceProvider.notifier).setBuffer(file);
                        ref.read(editorTextControllerProvider)?.text = file;
                      },
                    );
                  }),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: noop,
                      child: const Text('Spaces: NaN'),
                    ),
                  ),
                  if (kDebugMode)
                    IconButton(
                      icon: const Icon(Icons.format_paint),
                      tooltip: 'Toggle paint boundaries',
                      onPressed: () {
                        debugRepaintRainbowEnabled = !debugRepaintRainbowEnabled;
                      },
                    )
                  // const IconButton(icon: Icon(Icons.menu), onPressed: noop, tooltip: 'Menu'),
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
