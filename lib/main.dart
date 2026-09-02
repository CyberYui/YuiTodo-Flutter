import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_state.dart';
import 'core/theme/theme_schemes.dart';
import 'ui/screens/home_screen.dart';

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

    return MaterialApp(
      title: 'YuiTodo',
      debugShowCheckedModeBanner: false,
      themeMode: themeState.mode,
      theme: themeSchemes[themeState.lightScheme] != null 
          ? lightThemeForScheme(themeSchemes[themeState.lightScheme]!)
          : lightTheme,
      darkTheme: themeSchemes[themeState.darkScheme] != null 
          ? darkThemeForScheme(themeSchemes[themeState.darkScheme]!)
          : darkTheme,
      home: const HomeScreen(),
    );
  }
}
