abstract class IRustMdDart {
  Future<List<Element>?> parse({required String markdown, dynamic hint});
}

class Attribute {
  final String key;

  final String value;

  Attribute({
    required this.key,
    required this.value,
  });
}

class Element {
  /// Tags a la HTML tags.
  final String tag;

  /// Attributes.
  final List<Attribute>? attributes;

  /// Children of this element.
  final List<Element>? children;

  Element({
    required this.tag,
    this.attributes,
    this.children,
  });
}
