import 'package:flutter/material.dart';

class BottomBar extends StatelessWidget {
  const BottomBar({this.scaffoldKey, Key? key}) : super(key: key);

  static void noop() {}

  final GlobalKey<ScaffoldState>? scaffoldKey;

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
                  const IconButton(
                    icon: AnimatedSwitcher(duration: Duration(milliseconds: 200), child: Icon(Icons.call_end)),
                    onPressed: noop,
                    tooltip: 'Stuff',
                  ),
                  const IconButton(icon: Icon(Icons.format_bold), onPressed: noop, tooltip: 'Bold'),
                  const IconButton(icon: Icon(Icons.format_italic), onPressed: noop, tooltip: 'Italic'),
                  const IconButton(icon: Icon(Icons.format_strikethrough), onPressed: noop, tooltip: 'Strikethrough'),
                  const IconButton(icon: Icon(Icons.functions), onPressed: noop, tooltip: 'Math'),
                  const IconButton(icon: Icon(Icons.format_indent_increase), onPressed: noop, tooltip: 'Indent'),
                  const IconButton(icon: Icon(Icons.format_indent_decrease), onPressed: noop, tooltip: 'Dedent'),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: noop,
                      child: const Text('Spaces: NaN'),
                    ),
                  ),
                  // const IconButton(icon: Icon(Icons.menu), onPressed: noop, tooltip: 'Menu'),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: scaffoldKey?.currentState?.openEndDrawer,
            tooltip: 'Menu',
          )
        ],
      ),
    );
  }
}
