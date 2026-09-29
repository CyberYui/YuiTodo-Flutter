import 'package:intl/intl.dart';
import '../core/database/database.dart';

/// Service to track app usage statistics
class AppUsageService {
  static final AppUsageService instance = AppUsageService._();
  AppUsageService._();

  /// Record an app open event
  Future<void> recordAppOpen() async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(now);
    
    await db.insert('app_usage', {
      'open_time': now.millisecondsSinceEpoch,
      'date': dateStr,
    });
  }

  /// Get total app open count
  Future<int> getTotalOpenCount() async {
    final db = await AppDatabase.instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM app_usage');
    return result.first['count'] as int? ?? 0;
  }

  /// Get today's app open count
  Future<int> getTodayOpenCount() async {
    final db = await AppDatabase.instance.database;
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM app_usage WHERE date = ?',
      [dateStr],
    );
    return result.first['count'] as int? ?? 0;
  }

  /// Get app open count for last N days
  Future<Map<String, int>> getOpenCountLastNDays(int days) async {
    final db = await AppDatabase.instance.database;
    final result = await db.rawQuery('''
      SELECT date, COUNT(*) as count 
      FROM app_usage 
      GROUP BY date 
      ORDER BY date DESC 
      LIMIT ?
    ''', [days]);
    
    final map = <String, int>{};
    for (final row in result) {
      map[row['date'] as String] = row['count'] as int;
    }
    return map;
  }
}
