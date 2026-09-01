import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../core/database/database.dart';

/// Backup service provider
final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(AppDatabase.instance);
});

class BackupService {
  final AppDatabase _db;

  BackupService(this._db);

  /// Export all data to JSON file
  Future<String> export() async {
    final db = await _db.database;
    
    // Get all tasks
    final taskMaps = await db.query(
      'task',
      where: 'deleted_at IS NULL OR deleted_at = 0',
    );
    
    // Get all tags
    final tagMaps = await db.query('tag');
    
    // Get all task-tag relations
    final taskTagMaps = await db.query('task_tag');
    
    // Get all steps
    final stepMaps = await db.query('task_step');
    
    // Get all recurrence rules
    final recurrenceMaps = await db.query('recurrence_rule');

    final data = {
      'version': '4.0.0',
      'exportTime': DateTime.now().toIso8601String(),
      'tasks': taskMaps,
      'tags': tagMaps,
      'taskTags': taskTagMaps,
      'steps': stepMaps,
      'recurrenceRules': recurrenceMaps,
    };

    final json = const JsonEncoder.withIndent('  ').convert(data);
    return json;
  }

  /// Import data from JSON string
  /// Returns number of tasks imported
  Future<int> import(String jsonString) async {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    final db = await _db.database;

    // Clear existing data
    await db.delete('task_tag');
    await db.delete('task_step');
    await db.delete('task');
    await db.delete('tag');
    await db.delete('recurrence_rule');

    // Import recurrence rules
    final recurrenceRules = (data['recurrenceRules'] as List?) ?? [];
    for (final rule in recurrenceRules) {
      await db.insert('recurrence_rule', rule as Map<String, dynamic>);
    }

    // Import tags
    final tags = (data['tags'] as List?) ?? [];
    for (final tag in tags) {
      await db.insert('tag', tag as Map<String, dynamic>);
    }

    // Import tasks
    final tasks = (data['tasks'] as List?) ?? [];
    for (final task in tasks) {
      await db.insert('task', task as Map<String, dynamic>);
    }

    // Import task-tag relations
    final taskTags = (data['taskTags'] as List?) ?? [];
    for (final tt in taskTags) {
      await db.insert('task_tag', tt as Map<String, dynamic>);
    }

    // Import steps
    final steps = (data['steps'] as List?) ?? [];
    for (final step in steps) {
      await db.insert('task_step', step as Map<String, dynamic>);
    }

    return tasks.length;
  }

  /// Validate backup format
  bool isValidBackup(String jsonString) {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      return data.containsKey('version') && 
             data.containsKey('tasks') && 
             data['tasks'] is List;
    } catch (_) {
      return false;
    }
  }
}
