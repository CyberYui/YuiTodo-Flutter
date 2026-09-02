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
    final chineseFont = fontPair.chineseFontFamily;
    final englishFont = fontPair.englishFontFamily;

    // Build text theme with custom font
    final baseTextTheme = Typography.material2021().black;
    final customTextTheme = baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(fontFamily: chineseFont ?? englishFont),
      displayMedium: baseTextTheme.displayMedium?.copyWith(fontFamily: chineseFont ?? englishFont),
      displaySmall: baseTextTheme.displaySmall?.copyWith(fontFamily: chineseFont ?? englishFont),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(fontFamily: chineseFont ?? englishFont),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(fontFamily: chineseFont ?? englishFont),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(fontFamily: chineseFont ?? englishFont),
      titleLarge: baseTextTheme.titleLarge?.copyWith(fontFamily: chineseFont ?? englishFont),
      titleMedium: baseTextTheme.titleMedium?.copyWith(fontFamily: chineseFont ?? englishFont),
      titleSmall: baseTextTheme.titleSmall?.copyWith(fontFamily: chineseFont ?? englishFont),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontFamily: chineseFont ?? englishFont),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontFamily: chineseFont ?? englishFont),
      bodySmall: baseTextTheme.bodySmall?.copyWith(fontFamily: chineseFont ?? englishFont),
      labelLarge: baseTextTheme.labelLarge?.copyWith(fontFamily: chineseFont ?? englishFont),
      labelMedium: baseTextTheme.labelMedium?.copyWith(fontFamily: chineseFont ?? englishFont),
      labelSmall: baseTextTheme.labelSmall?.copyWith(fontFamily: chineseFont ?? englishFont),
    );

    return MaterialApp(
      title: 'YuiTodo',
      debugShowCheckedModeBanner: false,
      themeMode: themeState.mode,
      theme: (themeSchemes[themeState.lightScheme] != null 
          ? lightThemeForScheme(themeSchemes[themeState.lightScheme]!)
          : lightTheme).copyWith(
        textTheme: customTextTheme,
        appBarTheme: (themeSchemes[themeState.lightScheme] != null 
            ? lightThemeForScheme(themeSchemes[themeState.lightScheme]!).appBarTheme
            : lightTheme.appBarTheme).copyWith(
          titleTextStyle: TextStyle(
            fontFamily: chineseFont ?? englishFont,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      darkTheme: (themeSchemes[themeState.darkScheme] != null 
          ? darkThemeForScheme(themeSchemes[themeState.darkScheme]!)
          : darkTheme).copyWith(
        textTheme: customTextTheme,
        appBarTheme: (themeSchemes[themeState.darkScheme] != null 
            ? darkThemeForScheme(themeSchemes[themeState.darkScheme]!).appBarTheme
            : darkTheme.appBarTheme).copyWith(
          titleTextStyle: TextStyle(
            fontFamily: chineseFont ?? englishFont,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
