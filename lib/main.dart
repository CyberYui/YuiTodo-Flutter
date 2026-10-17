import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_state.dart';
import 'core/theme/theme_schemes.dart';
import 'core/storage/app_prefs.dart';
import 'core/database/database.dart';
import 'core/database/sample_data.dart';
import 'repositories/task_repository.dart';
import 'services/notification_service.dart';
import 'services/app_usage_service.dart';
import 'ui/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_CN');
  final prefs = await AppPrefs.load();
  await NotificationService.instance.initialize();
  try {
    final db = await AppDatabase.instance.database;
    await SampleData.seedIfNeeded(db);
  } catch (e) {
    // Sample data must never block startup.
  }
  try {
    final repo = TaskRepository(AppDatabase.instance);
    final reminderTasks = await repo.getTasksForReminders();
    final rules = await repo.getRecurrenceRuleMap();
    await NotificationService.instance.rescheduleAll(reminderTasks, rules);
  } catch (e) {
    // Reminder re-scheduling must never block startup.
  }
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
      theme: baseLightTheme.copyWith(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      darkTheme: baseDarkTheme.copyWith(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
