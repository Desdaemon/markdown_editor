import 'package:flutter/material.dart';
import 'package:markdown_editor/widgets/math.dart';

class ThunkWidget extends StatefulWidget {
  final Widget? child;
  final dynamic config;
  const ThunkWidget({this.child, Key? key, this.config}) : super(key: key);
  @override
  State<StatefulWidget> createState() => _ThunkWidgetState();
}

class _ThunkWidgetState extends State<ThunkWidget> with AutomaticKeepAliveClientMixin {
  Widget? cache;
  bool _wantKeepAlive = true;
  @override
  bool get wantKeepAlive => _wantKeepAlive;

  @override
  void didUpdateWidget(covariant ThunkWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (configurationUpdated(oldWidget.child, widget.child)) {
      cache = widget.child;
      _wantKeepAlive = false;
      updateKeepAlive();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    cache ??= widget.child;
    return cache ?? const SizedBox(width: 1, height: 1);
  }

  static const maxDepth = 30;

  bool configurationUpdated(dynamic left, dynamic right, {int depth = 0}) {
    if (depth > maxDepth) {
      debugPrint('too deep!');
      return true;
    }
    if (left == right) return false;
    if (left.runtimeType != right.runtimeType) return true;
    switch (left.runtimeType) {
      case Text:
        return left.data != right.data;
      case RichText:
        return left.text.compareTo(right.text) != RenderComparison.identical;
      case Expanded:
        return left.flex != right.flex || configurationUpdated(left.child, right.child, depth: depth + 1);
      case Column:
      case Row:
      case Wrap:
      case Table:
      case TableRow:
        // A regrettable consequence of immutable widgets is that we cannot
        // update each cell of a table, only entire tables at once and this makes
        // any kind of table-updating way more expensive than necessary.
        // If we start nesting ThunkWidgets, it's the fastest way to drain all the
        // performance out of the system.
        if (left.children.length != right.children.length) return true;
        for (var i = 0; i < left.children.length; i++) {
          if (configurationUpdated(left.children[i], right.children[i], depth: depth + 1)) {
            return true;
          }
        }
        return false;
      case SizedBox:
        return left.width != right.width ||
            left.height != right.height ||
            configurationUpdated(left.child, right.child, depth: depth + 1);
      case DecoratedBox:
      case Padding:
      case Scrollbar:
      case DefaultTextStyle:
      case SingleChildScrollView:
      case TableCell:
      case RepaintBoundary:
        return configurationUpdated(left.child, right.child, depth: depth + 1);
      case Icon:
        return left.icon != right.icon;
      case Image:
        return left.image.toString() != right.image.toString();
      case ThunkWidget:
        return left.config != right.config || configurationUpdated(left.child, right.child, depth: depth + 1);
      case GestureDetector:
        return left.onTap != right.onTap || configurationUpdated(left.child, right.child, depth: depth + 1);
      case MathWidget:
        return left.source != right.source || left.display != right.display || left.fontSize != right.fontSize;
      default:
        debugPrint('Unhandled configuration update for ${left.runtimeType}');
        return true;
    }
  }
}
