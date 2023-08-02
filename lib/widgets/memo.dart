import 'dart:math';

import 'package:flutter/material.dart';
import 'package:markdown_editor/widgets/math.dart';

class Memo extends StatefulWidget {
  final Widget? child;
  const Memo({this.child, Key? key}) : super(key: key);
  @override
  State<StatefulWidget> createState() => _MemoState();

  factory Memo.from(Widget child) => Memo(child: child);
}

class _MemoState extends State<Memo> with AutomaticKeepAliveClientMixin {
  Widget? _cache;
  @override
  bool wantKeepAlive = true;

  @override
  void initState() {
    super.initState();
    _cache = widget.child;
  }

  @override
  void didUpdateWidget(covariant Memo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (shouldUpdate(oldWidget.child, widget.child)) {
      _cache = widget.child;
      wantKeepAlive = false;
      updateKeepAlive();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _cache ?? const SizedBox(width: 1, height: 1);
  }
}

const maxDepth = 30;
bool shouldUpdate(Widget? left, Widget? right_, {int depth = 0}) {
  final dynamic right = right_;
  if (left == right) return false;
  if (left.runtimeType != right.runtimeType) return true;
  if (left is Text) return left.data != right.data;
  if (left is Icon) return left.icon != right.icon;
  if (left is Image) return left.image != right.image;
  if (left is RichText) return left.text.compareTo(right.text) != RenderComparison.identical;
  if (depth > maxDepth) {
    debugPrint('too deep!');
    return true;
  }
  if (left is Flexible) return left.flex != right.flex || shouldUpdate(left.child, right.child, depth: depth + 1);
  if (left is SizedBox) {
    return left.width != right.width ||
        left.height != right.height ||
        shouldUpdate(left.child, right.child, depth: depth + 1);
  }

  if (left is MultiChildRenderObjectWidget) return shouldUpdateChildren(left.children, right.children, depth + 1);
  if (const {
    Scrollbar,
    SingleChildScrollView,
    DecoratedBox,
    Padding,
    TableCell,
    RepaintBoundary,
    GestureDetector,
    DefaultTextStyle,
  }.contains(left.runtimeType)) {
    final dynamic left_ = left;
    return shouldUpdate(left_.child, right.child, depth: depth + 1);
  }
  if (left is Table) {
    if (left.children.length != right.children.length) return true;
    for (var i = 0; i < left.children.length; i++) {
      if (shouldUpdateChildren(left.children[i].children, right.children[i].children, depth + 1)) return true;
    }
    return false;
  }
  if (left is MathWidget) {
    return left.source != right.source || left.display != right.display || left.fontSize != right.fontSize;
  }
  debugPrint('Unhandled configuration update for\nleft= $left\nright=$right');
  return true;
}

List<Widget> mergeChildren(Widget left, Widget right) {
  final List<Widget> left_ = (left as dynamic).children;
  final List<Widget> right_ = (right as dynamic).children;
  int leftIdx = 0;
  final extent = min(left_.length, right_.length);
  while (leftIdx < extent && shouldUpdate(left_[leftIdx], right_[leftIdx])) {
    leftIdx++;
  }
  int i = left_.length;
  int j = right_.length;
  while (i > leftIdx && j > leftIdx && shouldUpdate(left_[i - 1], right_[j - 1])) {
    i--;
    j--;
  }
  return [
    ...left_.sublist(0, leftIdx),
    ...right_.sublist(leftIdx, j),
    ...left_.sublist(i),
  ];
}

bool shouldUpdateChildren(List<Widget>? left, List<Widget> right, int depth) {
  if (left == null) return true;
  if (left.length != right.length) return true;
  for (int i = 0; i < left.length; i++) {
    if (shouldUpdate(left[i], right[i], depth: depth)) return true;
  }
  return false;
}
