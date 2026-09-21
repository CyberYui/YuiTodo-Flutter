import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_state.dart';
import 'core/theme/theme_schemes.dart';
import 'services/notification_service.dart';
import 'ui/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();
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

    final lightScheme = themeSchemes[themeState.lightScheme];
    final darkScheme = themeSchemes[themeState.darkScheme];

    final baseLightTheme = lightScheme != null
        ? lightThemeForScheme(lightScheme)
        : lightTheme;
    final baseDarkTheme = darkScheme != null
        ? darkThemeForScheme(darkScheme)
        : darkTheme;

    return MaterialApp(
      title: 'YuiTodo',
      debugShowCheckedModeBanner: false,
      themeMode: themeState.mode,
      theme: baseLightTheme,
      darkTheme: baseDarkTheme,
      home: const HomeScreen(),
    );
  }
}
