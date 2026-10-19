import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/database.dart';

/// Backup service provider
final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(AppDatabase.instance);
});

class BackupService {
  /// Bump when the JSON shape changes in a backwards-incompatible way.
  static const int formatVersion = 2;

  final AppDatabase _db;

  BackupService(this._db);

  /// Export all data (including recycle-bin tasks) to a pretty JSON string.
  Future<String> export() async {
    final db = await _db.database;

    final data = <String, dynamic>{
      'formatVersion': formatVersion,
      'version': '$formatVersion',
      'exportTime': DateTime.now().toIso8601String(),
      'tasks': await db.query('task'),
      'tags': await db.query('tag'),
      'taskTags': await db.query('task_tag'),
      'steps': await db.query('task_step'),
      'stepOccurrences': await db.query('task_step_occurrence'),
      'occurrences': await db.query('task_occurrence'),
      'recurrenceRules': await db.query('recurrence_rule'),
      'taskReminders': await db.query('task_reminder'),
      'focusSessions': await db.query('focus_session'),
      'focusRestSegments': await db.query('focus_rest_segment'),
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Import data from JSON, replacing everything in one transaction.
  /// Returns the number of tasks imported.
  Future<int> import(String jsonString) async {
    final dynamic decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('备份文件格式不正确');
    }
    final data = decoded;
    final db = await _db.database;
    final tasks = (data['tasks'] as List?) ?? const <dynamic>[];

    await db.transaction((txn) async {
      // Child tables first; foreign keys are not enforced but this order keeps
      // the data logically consistent if they ever are.
      await txn.delete('focus_rest_segment');
      await txn.delete('focus_session');
      await txn.delete('task_step_occurrence');
      await txn.delete('task_occurrence');
      await txn.delete('task_reminder');
      await txn.delete('task_tag');
      await txn.delete('task_step');
      await txn.delete('recurrence_rule');
      await txn.delete('task');
      await txn.delete('tag');

      // Parents, then children.
      for (final task in tasks) {
        await txn.insert('task', task as Map<String, dynamic>);
      }
      for (final tag in (data['tags'] as List? ?? const <dynamic>[])) {
        await txn.insert('tag', tag as Map<String, dynamic>);
      }
      for (final step in (data['steps'] as List? ?? const <dynamic>[])) {
        await txn.insert('task_step', step as Map<String, dynamic>);
      }
      for (final rule in (data['recurrenceRules'] as List? ?? const <dynamic>[])) {
        await txn.insert('recurrence_rule', rule as Map<String, dynamic>);
      }
      for (final reminder
          in (data['taskReminders'] as List? ?? const <dynamic>[])) {
        await txn.insert('task_reminder', reminder as Map<String, dynamic>);
      }
      for (final occurrence
          in (data['occurrences'] as List? ?? const <dynamic>[])) {
        await txn.insert('task_occurrence', occurrence as Map<String, dynamic>);
      }
      for (final stepOccurrence
          in (data['stepOccurrences'] as List? ?? const <dynamic>[])) {
        await txn.insert(
          'task_step_occurrence',
          stepOccurrence as Map<String, dynamic>,
        );
      }
      for (final relation
          in (data['taskTags'] as List? ?? const <dynamic>[])) {
        await txn.insert('task_tag', relation as Map<String, dynamic>);
      }
      for (final session
          in (data['focusSessions'] as List? ?? const <dynamic>[])) {
        await txn.insert('focus_session', session as Map<String, dynamic>);
      }
      for (final segment
          in (data['focusRestSegments'] as List? ?? const <dynamic>[])) {
        await txn.insert(
          'focus_rest_segment',
          segment as Map<String, dynamic>,
        );
      }
    });

    return tasks.length;
  }

  /// Validate backup format (older backups without the new tables are fine).
  bool isValidBackup(String jsonString) {
    try {
      final dynamic decoded = jsonDecode(jsonString);
      return decoded is Map<String, dynamic> &&
          decoded.containsKey('version') &&
          decoded['tasks'] is List;
    } catch (_) {
      return false;
    }
  }
}
