import 'package:flutter/material.dart';

/// Font pairing system with system fonts
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
      name: '苹方无衬线',
      chineseFontFamily: 'PingFang SC',
      englishFontFamily: 'SF Pro Display',
      description: '现代简洁，适合阅读',
    ),
    FontPair(
      name: '黑体商务',
      chineseFontFamily: 'Heiti SC',
      englishFontFamily: 'Helvetica Neue',
      description: '专业稳重，适合工作',
    ),
    FontPair(
      name: '宋体衬线',
      chineseFontFamily: 'Songti SC',
      englishFontFamily: 'Georgia',
      description: '传统正式，适合长文',
    ),
    FontPair(
      name: '圆体可爱',
      chineseFontFamily: 'Yuanti SC',
      englishFontFamily: 'Nunito',
      description: '活泼可爱，适合笔记',
    ),
    FontPair(
      name: '翩翩手写',
      chineseFontFamily: 'HanziPen SC',
      englishFontFamily: 'Maple Mono',
      description: '个性手写，适合日记',
    ),
    FontPair(
      name: '隶变古典',
      chineseFontFamily: 'Libian SC',
      englishFontFamily: 'Ma Shan Zheng',
      description: '古典书法，适合标题',
    ),
    FontPair(
      name: '娃娃童趣',
      chineseFontFamily: 'Wawati SC',
      englishFontFamily: 'Baloo 2',
      description: '童趣活泼，适合轻松',
    ),
    FontPair(
      name: '雅痞时尚',
      chineseFontFamily: 'Yuppy SC',
      englishFontFamily: 'Vibur',
      description: '时尚潮流，适合个性',
    ),
    FontPair(
      name: '等宽代码',
      chineseFontFamily: 'Heiti SC',
      englishFontFamily: 'SF Mono',
      description: '技术感，适合代码',
    ),
  ];
  
  static FontPair getPair(int index) {
    if (index < 0 || index >= pairs.length) return pairs.first;
    return pairs[index];
  }
}
