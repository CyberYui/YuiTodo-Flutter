import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_state.dart';
import 'core/theme/theme_schemes.dart';
import 'core/storage/app_prefs.dart';
import 'services/notification_service.dart';
import 'services/app_usage_service.dart';
import 'ui/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await AppPrefs.load();
  await NotificationService.instance.initialize();
  // Record app open
  await AppUsageService.instance.recordAppOpen();
  runApp(
    ProviderScope(
      overrides: [appPrefsProvider.overrideWithValue(prefs)],
      child: const YuiTodoApp(),
    ),
  );
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
      // Resolve system brightness + timed auto-switch into a concrete mode.
      themeMode: themeState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: baseLightTheme,
      darkTheme: baseDarkTheme,
      home: const HomeScreen(),
    );
  }
}
