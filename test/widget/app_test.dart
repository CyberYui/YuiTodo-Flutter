import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yuitodo/main.dart';
import 'package:yuitodo/core/storage/app_prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('YuiTodoApp', () {
    testWidgets('renders MaterialApp with correct title', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await AppPrefs.load();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appPrefsProvider.overrideWithValue(prefs)],
          child: const YuiTodoApp(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('YuiTodo'), findsOneWidget);
    });
  });
}
