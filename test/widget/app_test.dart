import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yuitodo/main.dart';
import 'package:yuitodo/core/theme/app_theme.dart';

void main() {
  group('YuiTodoApp', () {
    testWidgets('renders MaterialApp with correct title', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: YuiTodoApp()));
      await tester.pumpAndSettle();

      expect(find.text('YuiTodo'), findsOneWidget);
    });

    testWidgets('theme toggle works', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: YuiTodoApp()));
      await tester.pumpAndSettle();

      // Find theme toggle button
      final themeButton = find.byIcon(Icons.light_mode);
      expect(themeButton, findsOneWidget);

      // Tap to switch to dark mode
      await tester.tap(themeButton);
      await tester.pumpAndSettle();

      // Now dark mode icon should appear
      expect(find.byIcon(Icons.dark_mode), findsOneWidget);
    });
  });

  group('Light Theme', () {
    testWidgets('has correct colors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final theme = Theme.of(context);
                expect(theme.brightness, Brightness.light);
                expect(theme.scaffoldBackgroundColor, const Color(0xFFF8FAFC));
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
    });
  });

  group('Dark Theme', () {
    testWidgets('has correct colors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final theme = Theme.of(context);
                expect(theme.brightness, Brightness.dark);
                expect(theme.scaffoldBackgroundColor, const Color(0xFF0F172A));
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
    });
  });
}
