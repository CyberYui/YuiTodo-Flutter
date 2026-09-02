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
    final fontPair = FontPair(
      name: AppFontPairs.getPair(fontIndex).name,
      chineseFontFamily: AppFontPairs.getPair(fontIndex).chineseFontFamily,
      englishFontFamily: AppFontPairs.getPair(fontIndex).englishFontFamily,
      description: '',
    );

    return MaterialApp(
      title: 'YuiTodo',
      debugShowCheckedModeBanner: false,
      themeMode: themeState.mode,
      theme: (themeSchemes[themeState.lightScheme] != null 
          ? lightThemeForScheme(themeSchemes[themeState.lightScheme]!)
          : lightTheme).copyWith(
        textTheme: _buildTextTheme(fontPair),
      ),
      darkTheme: (themeSchemes[themeState.darkScheme] != null 
          ? darkThemeForScheme(themeSchemes[themeState.darkScheme]!)
          : darkTheme).copyWith(
        textTheme: _buildTextTheme(fontPair),
      ),
      home: const HomeScreen(),
    );
  }

  TextTheme _buildTextTheme(FontPair fontPair) {
    final chinese = fontPair.chineseFontFamily;
    final english = fontPair.englishFontFamily;
    
    if (chinese == null && english == null) {
      return Typography.material2021().black;
    }
    
    return Typography.material2021().black.copyWith(
      // Default body styles
      bodyLarge: TextStyle(fontFamily: chinese ?? english),
      bodyMedium: TextStyle(fontFamily: chinese ?? english),
      bodySmall: TextStyle(fontFamily: chinese ?? english),
      // Title styles
      titleLarge: TextStyle(fontFamily: chinese ?? english),
      titleMedium: TextStyle(fontFamily: chinese ?? english),
      titleSmall: TextStyle(fontFamily: chinese ?? english),
      // Headline styles
      headlineLarge: TextStyle(fontFamily: chinese ?? english),
      headlineMedium: TextStyle(fontFamily: chinese ?? english),
      headlineSmall: TextStyle(fontFamily: chinese ?? english),
      // Display styles
      displayLarge: TextStyle(fontFamily: chinese ?? english),
      displayMedium: TextStyle(fontFamily: chinese ?? english),
      displaySmall: TextStyle(fontFamily: chinese ?? english),
      // Label styles
      labelLarge: TextStyle(fontFamily: chinese ?? english),
      labelMedium: TextStyle(fontFamily: chinese ?? english),
      labelSmall: TextStyle(fontFamily: chinese ?? english),
    );
  }
}
