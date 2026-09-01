import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeNotifier = ref.read(themeProvider.notifier);
    final isDark = ref.watch(themeProvider).toString().contains('dark') ||
        (ref.watch(themeProvider) == ThemeMode.system &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark);

    return Scaffold(
      appBar: AppBar(
        title: const Text('YuiTodo'),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeNotifier.toggle(),
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Color(0xFF3B82F6)),
            SizedBox(height: 16),
            Text('YuiTodo v4.0.0', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Flutter + Riverpod + SQLite', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 32),
            Text('Sprint 1: Core infrastructure complete!', style: TextStyle(color: Color(0xFF4ADE80))),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Open task editor
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
