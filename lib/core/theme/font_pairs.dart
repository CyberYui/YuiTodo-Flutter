import 'package:flutter/material.dart';

/// Font pairing system
class FontPair {
  final String name;
  final String? chineseFontFamily;
  final String? englishFontFamily;
  final String description;
  
  const FontPair({
    required this.name,
    this.chineseFontFamily,
    this.englishFontFamily,
    required this.description,
  });
}

/// Available font pairings
class AppFontPairs {
  static const List<FontPair> pairs = [
    FontPair(
      name: '系统默认',
      description: '使用系统默认字体',
    ),
    FontPair(
      name: '优雅黑体',
      chineseFontFamily: 'PingFang SC',
      englishFontFamily: 'SF Pro Display',
      description: '苹方 + SF Pro，现代简洁',
    ),
    FontPair(
      name: '经典宋体',
      chineseFontFamily: 'Songti SC',
      englishFontFamily: 'Georgia',
      description: '宋体 + Georgia，传统正式',
    ),
    FontPair(
      name: '可爱圆体',
      chineseFontFamily: 'Yuanti SC',
      englishFontFamily: 'Nunito',
      description: '圆体 + Nunito，活泼可爱',
    ),
    FontPair(
      name: '手写风格',
      chineseFontFamily: 'HanziPen SC',
      englishFontFamily: 'Maple Mono',
      description: '翩翩体 + Maple Mono，个性手写',
    ),
    FontPair(
      name: '等宽代码',
      chineseFontFamily: 'Heiti SC',
      englishFontFamily: 'SF Mono',
      description: '黑体 + SF Mono，技术感',
    ),
  ];
  
  static FontPair getPair(int index) {
    if (index < 0 || index >= pairs.length) return pairs.first;
    return pairs[index];
  }
}
