/// Font pairing system for open source version
/// Only system default font is available
class FontPair {
  final String name;
  final String description;
  
  const FontPair({
    required this.name,
    required this.description,
  });
}

class AppFontPairs {
  static const List<FontPair> pairs = [
    FontPair(
      name: '系统默认',
      description: '使用系统默认字体',
    ),
  ];
  
  static FontPair getPair(int index) {
    return pairs.first;
  }
}
