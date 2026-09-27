import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yuitodo/main.dart';

void main() {
  group('YuiTodoApp', () {
    testWidgets('renders MaterialApp with correct title', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: YuiTodoApp()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('YuiTodo'), findsOneWidget);
    });
  });
}
