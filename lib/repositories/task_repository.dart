import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
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

  Future<List<Task>> getTasksByDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
    final end = DateTime(date.year, date.month, date.day + 1).millisecondsSinceEpoch;

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
    await db.update(
      'task',
      {'deleted_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<void> restoreTask(int taskId) async {
    final db = await _db.database;
    await db.update(
      'task',
      {'deleted_at': null, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<void> permanentDelete(int taskId) async {
    final db = await _db.database;
    await db.delete('task', where: 'id = ?', whereArgs: [taskId]);
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
    return db.insert('task_step', step.toMap());
  }

  Future<void> updateStep(TaskStep step) async {
    final db = await _db.database;
    await db.update('task_step', step.toMap(), where: 'id = ?', whereArgs: [step.id]);
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

  Future<List<Tag>> getTagsForTask(int taskId) async {
    final db = await _db.database;
    final maps = await db.rawQuery('''
      SELECT t.* FROM tag t
      INNER JOIN task_tag tt ON t.id = tt.tag_id
      WHERE tt.task_id = ?
      ORDER BY t.name ASC
    ''', [taskId]);
    return maps.map((m) => Tag.fromMap(m)).toList();
  }

  Future<int> createTag(Tag tag) async {
    final db = await _db.database;
    return db.insert('tag', tag.toMap());
  }

  Future<void> addTagToTask(int taskId, int tagId) async {
    final db = await _db.database;
    await db.insert('task_tag', {'task_id': taskId, 'tag_id': tagId});
  }

  Future<void> removeTagFromTask(int taskId, int tagId) async {
    final db = await _db.database;
    await db.delete('task_tag', where: 'task_id = ? AND tag_id = ?', whereArgs: [taskId, tagId]);
  }

  Future<void> deleteTag(int tagId) async {
    final db = await _db.database;
    await db.delete('task_tag', where: 'tag_id = ?', whereArgs: [tagId]);
    await db.delete('tag', where: 'id = ?', whereArgs: [tagId]);
  }

  // Batch operations
  Future<void> batchDelete(List<int> taskIds) async {
    final db = await _db.database;
    final batch = db.batch();
    for (final id in taskIds) {
      batch.update(
        'task',
        {'deleted_at': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> batchAddTag(List<int> taskIds, int tagId) async {
    final db = await _db.database;
    final batch = db.batch();
    for (final taskId in taskIds) {
      batch.insert('task_tag', {'task_id': taskId, 'tag_id': tagId});
    }
    await batch.commit(noResult: true);
  }

  Future<void> batchRemoveTag(List<int> taskIds, int tagId) async {
    final db = await _db.database;
    final batch = db.batch();
    for (final taskId in taskIds) {
      batch.delete('task_tag', where: 'task_id = ? AND tag_id = ?', whereArgs: [taskId, tagId]);
    }
    await batch.commit(noResult: true);
  }
}
