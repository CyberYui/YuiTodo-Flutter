
/// ============================================================================
/// Font pairing catalog
/// ============================================================================
///
/// Open-source fonts (SIL OFL 1.1) are listed first so the opensource build
/// keeps the same indices. Proprietary fonts are appended and only exist in
/// the full build; `tool/strip_fonts.py` removes the marked block when deriving
/// the opensource branch.
///
/// Open fonts:
///   - Source Han Sans SC（思源黑体）
///   - Smiley Sans（得意黑）
///   - LXGW WenKai Lite（霞鹜文楷）
///   - IBM Plex Sans SC
///   - IBM Plex Mono
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

/// All available font pairings.
class AppFontPairs {
  static const List<FontPair> pairs = [
    FontPair(
      name: '系统默认',
      description: '使用系统默认字体（不指定 fontFamily）',
    ),

    // ---- Open-source fonts (SIL OFL 1.1) ----
    FontPair(
      name: '思源黑体',
      chineseFontFamily: 'SourceHanSansSC',
      englishFontFamily: 'SourceHanSansSC',
      description: '开源黑体，干净通用（SIL OFL 1.1）',
    ),
    FontPair(
      name: '得意黑',
      chineseFontFamily: 'SmileySans',
      englishFontFamily: 'SmileySans',
      description: '开源展示黑体，适合标题/鼓励语（SIL OFL 1.1）',
    ),
    FontPair(
      name: '霞鹜文楷',
      chineseFontFamily: 'LXGWWenKaiLite',
      englishFontFamily: 'LXGWWenKaiLite',
      description: '开源楷体，温暖阅读（SIL OFL 1.1）',
    ),
    FontPair(
      name: 'IBM Plex Sans SC',
      chineseFontFamily: 'IBMPlexSansSC',
      englishFontFamily: 'IBMPlexSansSC',
      description: '开源企业级黑体（SIL OFL 1.1）',
    ),
    FontPair(
      name: 'IBM Plex Mono',
      chineseFontFamily: 'IBMPlexMono',
      englishFontFamily: 'IBMPlexMono',
      description: '等宽西文/数字，中文自动回退（SIL OFL 1.1）',
    ),

    // ---- Proprietary fonts (full build only) ----
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

  /// Get a font pair by index, falling back to the system default.
  static FontPair getPair(int index) {
    if (index < 0 || index >= pairs.length) return pairs.first;
    return pairs[index];
  }
}
