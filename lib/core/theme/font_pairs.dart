import 'package:flutter/material.dart';

/// ============================================================================
/// 字体配对系统（Font Pairing System）
/// ============================================================================
/// 
/// 本文件定义了所有可用的字体配对方案。
/// 字体来源：本地嵌入字体文件（assets/fonts/）
/// 
/// 字体列表：
///   - 华康少女文字W5：可爱少女风
///   - 恋星圆体：圆润可爱风
///   - LOGO圆体：标题圆体风
///   - 萌神手写体：手写涂鸦风
///   - 字体家AI造字福楷：AI生成楷书
///   - MapleMono：等宽代码字体
///   - FiraCodeNerdFontMono：Nerd Font 图标字体
///   - ArkPixel：像素字体
/// ============================================================================

/// 单个字体配对方案
class FontPair {
  final String name;                    // 显示名称
  final String? chineseFontFamily;      // 中文字体名称（嵌入字体用 family 名称）
  final String? englishFontFamily;      // 英文字体名称
  final String description;             // 风格描述
  
  const FontPair({
    required this.name,
    this.chineseFontFamily,
    this.englishFontFamily,
    required this.description,
  });
}

/// 所有可用的字体配对列表
class AppFontPairs {
  static const List<FontPair> pairs = [
    FontPair(
      name: '系统默认',
      description: '使用系统默认字体（不指定 fontFamily）',
    ),
    FontPair(
      name: '华康少女',
      chineseFontFamily: '华康少女文字W5',
      englishFontFamily: '华康少女文字W5',
      description: '可爱少女风，圆润甜美',
    ),
    FontPair(
      name: '恋星圆体',
      chineseFontFamily: '恋星圆体',
      englishFontFamily: '恋星圆体',
      description: '圆润可爱，星星般闪耀',
    ),
    FontPair(
      name: 'LOGO圆体',
      chineseFontFamily: 'LOGO圆体',
      englishFontFamily: 'LOGO圆体',
      description: '标题圆体，设计感强',
    ),
    FontPair(
      name: '萌神手写',
      chineseFontFamily: '萌神手写体',
      englishFontFamily: '萌神手写体',
      description: '手写涂鸦，萌趣十足',
    ),
    FontPair(
      name: 'AI造字福楷',
      chineseFontFamily: '字体家AI造字福楷',
      englishFontFamily: '字体家AI造字福楷',
      description: 'AI生成楷书，传统与现代融合',
    ),
    FontPair(
      name: 'MapleMono',
      chineseFontFamily: 'MapleMono',
      englishFontFamily: 'MapleMono',
      description: '等宽代码字体，适合技术阅读',
    ),
    FontPair(
      name: 'FiraCode',
      chineseFontFamily: 'FiraCodeNerdFontMono',
      englishFontFamily: 'FiraCodeNerdFontMono',
      description: 'Nerd Font，支持编程图标',
    ),
    FontPair(
      name: 'ArkPixel',
      chineseFontFamily: 'ArkPixel',
      englishFontFamily: 'ArkPixel',
      description: '像素字体，复古游戏风',
    ),
  ];
  
  /// 根据索引获取字体配对
  static FontPair getPair(int index) {
    if (index < 0 || index >= pairs.length) return pairs.first;
    return pairs[index];
  }
}
