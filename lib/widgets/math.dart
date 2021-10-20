import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class MathWidget extends StatefulWidget {
  final String source;
  final bool display;
  final double? fontSize;
  const MathWidget({required this.source, required this.display, this.fontSize, Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MathWidgetState();
}

class _MathWidgetState extends State<MathWidget> {
  Widget? child;

  @override
  void didUpdateWidget(covariant MathWidget old) {
    super.didUpdateWidget(old);
    if (old.source != widget.source || old.display != widget.display || old.fontSize != widget.fontSize) {
      child = _build();
    }
  }

  @override
  Widget build(BuildContext context) {
    child ??= _build();
    return child!;
  }

  Widget _build() {
    child = Math.tex(
      widget.source,
      options: MathOptions(
        style: widget.display ? MathStyle.display : MathStyle.text,
        fontSize: widget.fontSize,
      ),
      onErrorFallback: (ex) {
        return Tooltip(
          message: ex.message,
          child: Text(
            widget.source,
            style: const TextStyle(color: Colors.red),
          ),
        );
      },
    );
    if (widget.display) {
      return Align(alignment: Alignment.center, child: child);
    } else {
      return child!;
    }
  }
}
