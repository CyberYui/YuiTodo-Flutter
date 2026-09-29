import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task.dart';
import '../models/recurrence_rule.dart';
import '../core/database/database.dart';

/// Task repository provider
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(AppDatabase.instance);
});

class TaskRepository {
  final AppDatabase _db;

  TaskRepository(this._db);

  Future<List<Task>> getAllTasks() async {
    final db = await _db.database;
    final maps = await db.query(
      'task',
      where: 'deleted_at IS NULL OR deleted_at = 0',
      orderBy: 'sort_order ASC, start_date ASC',
    );
    final tasks = maps.map((m) => Task.fromMap(m)).toList();

    // Load relations for each task
    for (var i = 0; i < tasks.length; i++) {
      final steps = await getStepsForTask(tasks[i].id!);
      final tags = await getTagsForTask(tasks[i].id!);
      tasks[i] = tasks[i].copyWith(steps: steps, tags: tags);
    }
    return tasks;
  }

  Future<List<Task>> getDeletedTasks() async {
    final db = await _db.database;
    final maps = await db.query(
      'task',
      where: 'deleted_at IS NOT NULL AND deleted_at != 0',
      orderBy: 'deleted_at DESC',
    );
    return maps.map((m) => Task.fromMap(m)).toList();
  }

  Future<void> softDeleteTask(int taskId) async {
    final db = await _db.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'task',
      {'deleted_at': now},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<void> batchSoftDelete(List<int> taskIds) async {
    final db = await _db.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final batch = db.batch();
    for (final id in taskIds) {
      batch.update(
        'task',
        {'deleted_at': now},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    await batch.commit();
  }

  Future<void> restoreTask(int taskId) async {
    final db = await _db.database;
    await db.update(
      'task',
      {'deleted_at': 0, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<void> updateTaskSortOrder(int taskId, int newOrder) async {
    final db = await _db.database;
    await db.update(
      'task',
      {'sort_order': newOrder},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<List<Task>> getTasksByDate(DateTime date) async {
    final start = DateTime(
      date.year,
      date.month,
      date.day,
    ).millisecondsSinceEpoch;
    final end = DateTime(
      date.year,
      date.month,
      date.day + 1,
    ).millisecondsSinceEpoch;

    final db = await _db.database;
    final maps = await db.query(
      'task',
      where: '(start_date >= ? AND start_date < ?) AND (deleted_at IS NULL OR deleted_at = 0)',
      whereArgs: [start, end],
      orderBy: 'sort_order ASC',
    );
    return maps.map((m) => Task.fromMap(m)).toList();
  }

  Future<int> createTask(Task task) async {
    final db = await _db.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final data = task.toMap()
      ..['created_at'] = now
      ..['updated_at'] = now;
    data.remove('id');
    return db.insert('task', data);
  }

  Future<void> updateTask(Task task) async {
    final db = await _db.database;
    final data = task.toMap()
      ..['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    await db.update('task', data, where: 'id = ?', whereArgs: [task.id]);
  }

  Future<void> deleteTask(int taskId) async {
    final db = await _db.database;
    await db.delete('task', where: 'id = ?', whereArgs: [taskId]);
  }

  Future<Task?> getTaskById(int taskId) async {
    final db = await _db.database;
    final maps = await db.query('task', where: 'id = ?', whereArgs: [taskId], limit: 1);
    if (maps.isEmpty) return null;
    return Task.fromMap(maps.first);
  }

  // Steps
  Future<List<TaskStep>> getStepsForTask(int taskId) async {
    final db = await _db.database;
    final maps = await db.query(
      'task_step',
      where: 'task_id = ?',
      whereArgs: [taskId],
      orderBy: 'sort_order ASC',
    );
    return maps.map((m) => TaskStep.fromMap(m)).toList();
  }

  Future<int> createStep(TaskStep step) async {
    final db = await _db.database;
    final data = step.toMap();
    data.remove('id');
    return db.insert('task_step', data);
  }

  Future<void> updateStepStatus(int stepId, String status) async {
    final db = await _db.database;
    await db.update(
      'task_step',
      {'status': status},
      where: 'id = ?',
      whereArgs: [stepId],
    );
  }

  Future<void> updateStep(TaskStep step) async {
    final db = await _db.database;
    await db.update(
      'task_step',
      step.toMap(),
      where: 'id = ?',
      whereArgs: [step.id],
    );
  }

  Future<void> deleteStep(int stepId) async {
    final db = await _db.database;
    await db.delete('task_step', where: 'id = ?', whereArgs: [stepId]);
  }

  // Tags
  Future<List<Tag>> getAllTags() async {
    final db = await _db.database;
    final maps = await db.query('tag', orderBy: 'name ASC');
    return maps.map((m) => Tag.fromMap(m)).toList();
  }

  Future<int> createTag(Tag tag) async {
    final db = await _db.database;
    final data = tag.toMap();
    data.remove('id');
    return db.insert('tag', data);
  }

  Future<void> updateTag(Tag tag) async {
    final db = await _db.database;
    await db.update('tag', tag.toMap(), where: 'id = ?', whereArgs: [tag.id]);
  }

  Future<void> deleteTag(int tagId) async {
    final db = await _db.database;
    await db.delete('tag', where: 'id = ?', whereArgs: [tagId]);
  }

  Future<List<Tag>> getTagsForTask(int taskId) async {
    final db = await _db.database;
    final maps = await db.rawQuery(
      '''
      SELECT t.* FROM tag t
      INNER JOIN task_tag tt ON t.id = tt.tag_id
      WHERE tt.task_id = ?
    ''',
      [taskId],
    );
    return maps.map((m) => Tag.fromMap(m)).toList();
  }

  Future<void> addTagToTask(int taskId, int tagId) async {
    final db = await _db.database;
    await db.insert('task_tag', {'task_id': taskId, 'tag_id': tagId});
  }

  Future<void> removeTagFromTask(int taskId, int tagId) async {
    final db = await _db.database;
    await db.delete(
      'task_tag',
      where: 'task_id = ? AND tag_id = ?',
      whereArgs: [taskId, tagId],
    );
  }

  Future<void> batchAddTag(List<int> taskIds, int tagId) async {
    final db = await _db.database;
    final batch = db.batch();
    for (final taskId in taskIds) {
      batch.insert('task_tag', {'task_id': taskId, 'tag_id': tagId});
    }
    await batch.commit();
  }

  Future<void> batchRemoveTag(List<int> taskIds, int tagId) async {
    final db = await _db.database;
    final batch = db.batch();
    for (final taskId in taskIds) {
      batch.delete(
        'task_tag',
        where: 'task_id = ? AND tag_id = ?',
        whereArgs: [taskId, tagId],
      );
    }
    await batch.commit();
  }

  // Recurrence rules
  Future<List<RecurrenceRule>> getRecurrenceRules() async {
    final db = await _db.database;
    final maps = await db.query('recurrence_rule', orderBy: 'created_at DESC');
    return maps.map((m) => RecurrenceRule.fromMap(m)).toList();
  }

  Future<int> createRecurrenceRule(RecurrenceRule rule) async {
    final db = await _db.database;
    final data = rule.toMap();
    data.remove('id');
    return db.insert('recurrence_rule', data);
  }

  Future<void> updateRecurrenceRule(RecurrenceRule rule) async {
    final db = await _db.database;
    await db.update('recurrence_rule', rule.toMap(), where: 'id = ?', whereArgs: [rule.id]);
  }

  Future<void> deleteRecurrenceRule(int ruleId) async {
    final db = await _db.database;
    await db.delete('recurrence_rule', where: 'id = ?', whereArgs: [ruleId]);
  }

  // Duplicate a recurring task for a specific date
  Future<int> duplicateTaskForDate(int originalTaskId, DateTime date) async {
    final db = await _db.database;
    final original = await db.query('task', where: 'id = ?', whereArgs: [originalTaskId]);
    if (original.isEmpty) throw Exception('Task not found');

    final taskMap = Map<String, dynamic>.from(original.first);
    taskMap.remove('id');
    taskMap['start_date'] = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
    taskMap['end_time'] = DateTime(date.year, date.month, date.day, 23, 59, 59).millisecondsSinceEpoch;
    taskMap['status'] = 'pending';
    taskMap['created_at'] = DateTime.now().millisecondsSinceEpoch;
    taskMap['updated_at'] = DateTime.now().millisecondsSinceEpoch;

    final newId = await db.insert('task', taskMap);

    // Copy steps
    final steps = await getStepsForTask(originalTaskId);
    for (final step in steps) {
      await createStep(TaskStep(
        taskId: newId,
        title: step.title,
        sortOrder: step.sortOrder,
        status: 'pending',
      ));
    }

    // Copy tags
    final tags = await getTagsForTask(originalTaskId);
    for (final tag in tags) {
      await addTagToTask(newId, tag.id!);
    }

    return newId;
  }

  // Check if a task instance already exists for a given recurrence rule and date
  Future<Task?> getTaskForDate(int originalTaskId, DateTime date) async {
    final db = await _db.database;
    final dayStart = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
    final dayEnd = DateTime(date.year, date.month, date.day + 1).millisecondsSinceEpoch;

    final maps = await db.query(
      'task',
      where: 'recurrence_id = ? AND start_date >= ? AND start_date < ? AND (deleted_at IS NULL OR deleted_at = 0)',
      whereArgs: [originalTaskId, dayStart, dayEnd],
      limit: 1,
    );
    return maps.isEmpty ? null : Task.fromMap(maps.first);
  }
}
