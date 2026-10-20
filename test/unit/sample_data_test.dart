import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:yuitodo/core/database/database.dart';
import 'package:yuitodo/core/database/sample_data.dart';

/// Guards the first-install sample data: it doubles as the in-app manual, so it
/// must demonstrate every feature — including the recurring-only 「跳过」 swipe
/// action, which requires a recurrence rule.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;

  setUp(() async {
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 14,
      onCreate: (db, version) => AppDatabase.instance.createTables(db, version),
    );
    await SampleData.seedIfNeeded(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('welcome task is daily-recurring so it exposes the 跳过 action', () async {
    final tasks = await db.query(
      'task',
      columns: ['id', 'title'],
      where: 'title LIKE ?',
      whereArgs: ['%欢迎使用%'],
    );
    expect(tasks, isNotEmpty);

    final taskId = tasks.first['id'] as int;
    final rules = await db.query(
      'recurrence_rule',
      where: 'task_id = ?',
      whereArgs: [taskId],
    );
    expect(rules, isNotEmpty,
        reason: 'welcome task must be recurring to demonstrate 跳过');
    expect(rules.first['type'], 'daily');
  });

  test('every sample task carries an icon', () async {
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM task WHERE icon IS NULL',
    );
    expect(rows.first['c'], 0, reason: 'sample tasks should demonstrate icons');
  });

  test('sample data demonstrates reminders and focus sessions', () async {
    final reminders = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM task WHERE reminder_time IS NOT NULL',
    );
    expect(reminders.first['c'], greaterThan(0));

    final focus = await db.rawQuery('SELECT COUNT(*) AS c FROM focus_session');
    expect(focus.first['c'], greaterThan(0));
  });

  test('seeding is idempotent and only runs on an empty task table', () async {
    final before = await db.rawQuery('SELECT COUNT(*) AS c FROM task');
    await SampleData.seedIfNeeded(db);
    final after = await db.rawQuery('SELECT COUNT(*) AS c FROM task');
    expect(after.first['c'], before.first['c']);
  });
}
