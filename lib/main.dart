import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_state.dart';
import 'core/theme/theme_schemes.dart';
import 'core/theme/font_pairs.dart';
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
    final themeState = ref.watch(themeStateProvider);
    final fontIndex = ref.watch(fontIndexProvider);

    // Get font family
    final fontPair = AppFontPairs.getPair(fontIndex);
    final fontFamily = fontPair.chineseFontFamily ?? fontPair.englishFontFamily;

    // Get light/dark themes
    final lightScheme = themeSchemes[themeState.lightScheme];
    final darkScheme = themeSchemes[themeState.darkScheme];
    
    final baseLightTheme = lightScheme != null ? lightThemeForScheme(lightScheme) : lightTheme;
    final baseDarkTheme = darkScheme != null ? darkThemeForScheme(darkScheme) : darkTheme;

    // Build text theme with custom font
    TextTheme buildTextTheme(TextTheme base) {
      if (fontFamily == null) return base;
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

    return MaterialApp(
      title: 'YuiTodo',
      debugShowCheckedModeBanner: false,
      themeMode: themeState.mode,
      theme: baseLightTheme.copyWith(
        textTheme: buildTextTheme(baseLightTheme.textTheme),
      ),
      darkTheme: baseDarkTheme.copyWith(
        textTheme: buildTextTheme(baseDarkTheme.textTheme),
      ),
      home: const HomeScreen(),
    );
  }
}
