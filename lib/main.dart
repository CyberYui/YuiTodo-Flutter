import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_state.dart';
import 'core/theme/theme_schemes.dart';
import 'core/theme/font_pairs.dart';  // ← 导入字体配对系统
import 'ui/screens/home_screen.dart';
import 'ui/screens/settings_screen.dart';

void main() {
  runApp(const ProviderScope(child: YuiTodoApp()));
}

class YuiTodoApp extends ConsumerStatefulWidget {
  const YuiTodoApp({super.key});

  @override
  ConsumerState<YuiTodoApp> createState() => _YuiTodoAppState();
}

class _YuiTodoAppState extends ConsumerState<YuiTodoApp> {
  @override
  Widget build(BuildContext context) {
    // ==================== 读取当前主题和字体状态 ====================
    final themeState = ref.watch(themeStateProvider);  // 主题状态（模式、浅色/深色方案）
    final fontIndex = ref.watch(fontIndexProvider);     // 字体索引（用户选择的字体编号）

    // ==================== 获取字体配对 ====================
    // 根据索引获取对应的字体配对方案
    final fontPair = AppFontPairs.getPair(fontIndex);
    // 优先使用中文字体，如果中文字体为 null 则使用英文字体
    final fontFamily = fontPair.chineseFontFamily ?? fontPair.englishFontFamily;
    // 如果 fontFamily 也为 null（系统默认），则不应用自定义字体

    // ==================== 获取当前主题方案 ====================
    final lightScheme = themeSchemes[themeState.lightScheme];  // 当前浅色主题方案
    final darkScheme = themeSchemes[themeState.darkScheme];     // 当前深色主题方案
    
    // 构建基础主题（不包含字体）
    final baseLightTheme = lightScheme != null ? lightThemeForScheme(lightScheme) : lightTheme;
    final baseDarkTheme = darkScheme != null ? darkThemeForScheme(darkScheme) : darkTheme;

    // ==================== 构建带字体的 TextTheme ====================
    // 将 fontFamily 应用到所有文字样式
    // 注意：这里只应用中文字体，英文字体需要更复杂的逻辑（如根据字符判断）
    TextTheme buildTextTheme(TextTheme base) {
      // 如果 fontFamily 为 null（系统默认），直接返回原主题
      if (fontFamily == null) return base;
      
      // 否则，将所有文字样式的 fontFamily 设置为用户选择的字体
      return base.copyWith(
        displayLarge: base.displayLarge?.copyWith(fontFamily: fontFamily),
        displayMedium: base.displayMedium?.copyWith(fontFamily: fontFamily),
        displaySmall: base.displaySmall?.copyWith(fontFamily: fontFamily),
        headlineLarge: base.headlineLarge?.copyWith(fontFamily: fontFamily),
        headlineMedium: base.headlineMedium?.copyWith(fontFamily: fontFamily),
        headlineSmall: base.headlineSmall?.copyWith(fontFamily: fontFamily),
        titleLarge: base.titleLarge?.copyWith(fontFamily: fontFamily),
        titleMedium: base.titleMedium?.copyWith(fontFamily: fontFamily),
        titleSmall: base.titleSmall?.copyWith(fontFamily: fontFamily),
        bodyLarge: base.bodyLarge?.copyWith(fontFamily: fontFamily),
        bodyMedium: base.bodyMedium?.copyWith(fontFamily: fontFamily),
        bodySmall: base.bodySmall?.copyWith(fontFamily: fontFamily),
        labelLarge: base.labelLarge?.copyWith(fontFamily: fontFamily),
        labelMedium: base.labelMedium?.copyWith(fontFamily: fontFamily),
        labelSmall: base.labelSmall?.copyWith(fontFamily: fontFamily),
      );
    }

    // ==================== 构建 MaterialApp ====================
    return MaterialApp(
      title: 'YuiTodo',
      debugShowCheckedModeBanner: false,
      themeMode: themeState.mode,  // 主题模式（light/dark/system）
      // 应用带字体的浅色主题
      theme: baseLightTheme.copyWith(
        textTheme: buildTextTheme(baseLightTheme.textTheme),
      ),
      // 应用带字体的深色主题
      darkTheme: baseDarkTheme.copyWith(
        textTheme: buildTextTheme(baseDarkTheme.textTheme),
      ),
      home: const HomeScreen(),
    );
  }
}
