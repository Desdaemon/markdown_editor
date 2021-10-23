import 'core/core.dart';
import 'package:markdown/markdown.dart' as md;

class ElementAdapter extends md.Element {
  final Element elm;
  final _attributes = <String, String>{};
  late List<md.Node> _children;
  ElementAdapter(this.elm) : super.empty('') {
    if (elm.attributes != null) {
      for (final attr in elm.attributes!) {
        _attributes[attr.key] = attr.value;
      }
    }
    if (elm.children != null) {
      _children = elm.children!.map(ElementAdapter.from).toList();
    } else {
      _children = [md.Text(elm.tag)];
    }
  }

  static md.Node from(Element elm) {
    if (elm.attributes == null && elm.children == null) {
      return md.Text(elm.tag);
    } else {
      return ElementAdapter(elm);
    }
  }

  @override
  String get tag => elm.tag;

  @override
  Map<String, String> get attributes => _attributes;

  @override
  List<md.Node>? get children => _children;
}
