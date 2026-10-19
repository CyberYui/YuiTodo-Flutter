import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../models/task.dart';
import '../models/recurrence_rule.dart';
import '../models/focus_session.dart';
import '../core/database/database.dart';
import '../core/date/date_utils.dart';

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
      {'deleted_at': null, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<void> updateTaskSortOrder(int taskId, int newOrder) async {
    final db = await _db.database;
    await db.update(
      'task',
      {
        'sort_order': newOrder,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
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
    // Hard delete: remove child reminder rows too (SQLite foreign keys are
    // not enforced by default, so ON DELETE CASCADE does not fire).
    await db.transaction((txn) async {
      await txn.delete(
        'task_reminder',
        where: 'task_id = ?',
        whereArgs: [taskId],
      );
      await txn.delete('task', where: 'id = ?', whereArgs: [taskId]);
    });
  }

  /// Load one base task (not an occurrence) with its steps and tags.
  /// Used by the editor so per-occurrence step statuses are never written back
  /// to the template.
  Future<Task?> getTaskById(int taskId) async {
    final db = await _db.database;
    final maps = await db.query(
      'task',
      where: 'id = ? AND (deleted_at IS NULL OR deleted_at = 0)',
      whereArgs: [taskId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    final task = Task.fromMap(maps.first);
    final steps = await getStepsForTask(taskId);
    final tags = await getTagsForTask(taskId);
    return task.copyWith(steps: steps, tags: tags);
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

  // ---------------------------------------------------------------------------
  // Occurrence exceptions (virtual recurrence instances)
  // ---------------------------------------------------------------------------

  /// Map of taskId -> rule for all recurring tasks.
  Future<Map<int, RecurrenceRule>> getRecurrenceRuleMap() async {
    final rules = await getRecurrenceRules();
    return {for (final r in rules) r.taskId: r};
  }

  /// Map of taskId -> (yyyyMMdd -> state) for occurrences in `[from, to]`.
  Future<Map<int, Map<int, String>>> getOccurrencesInRange(
    DateTime from,
    DateTime to,
  ) async {
    final db = await _db.database;
    final maps = await db.query(
      'task_occurrence',
      columns: ['task_id', 'occurrence_day', 'state'],
      where: 'occurrence_day >= ? AND occurrence_day <= ?',
      whereArgs: [ymdKey(from), ymdKey(to)],
    );
    final result = <int, Map<int, String>>{};
    for (final m in maps) {
      final taskId = m['task_id'] as int;
      final day = m['occurrence_day'] as int;
      final state = m['state'] as String;
      (result[taskId] ??= {})[day] = state;
    }
    return result;
  }

  Future<String?> getOccurrenceState(int taskId, DateTime day) async {
    final db = await _db.database;
    final maps = await db.query(
      'task_occurrence',
      columns: ['state'],
      where: 'task_id = ? AND occurrence_day = ?',
      whereArgs: [taskId, ymdKey(day)],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return maps.first['state'] as String;
  }

  Future<void> setOccurrenceState(
    int taskId,
    DateTime day,
    String state, {
    int? completedAt,
  }) async {
    final db = await _db.database;
    await db.insert(
      'task_occurrence',
      {
        'task_id': taskId,
        'occurrence_day': ymdKey(day),
        'state': state,
        'completed_at': completedAt ??
            (state == 'done'
                ? DateTime.now().millisecondsSinceEpoch
                : null),
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearOccurrence(int taskId, DateTime day) async {
    final db = await _db.database;
    await db.delete(
      'task_occurrence',
      where: 'task_id = ? AND occurrence_day = ?',
      whereArgs: [taskId, ymdKey(day)],
    );
  }

  /// All occurrence states for one task (yyyyMMdd -> state).
  Future<Map<int, String>> getOccurrencesForTask(int taskId) async {
    final db = await _db.database;
    final maps = await db.query(
      'task_occurrence',
      columns: ['occurrence_day', 'state'],
      where: 'task_id = ?',
      whereArgs: [taskId],
    );
    return {
      for (final m in maps) m['occurrence_day'] as int: m['state'] as String,
    };
  }

  // ---------------------------------------------------------------------------
  // Per-occurrence subtask state
  // ---------------------------------------------------------------------------

  /// Map of stepId -> (yyyyMMdd -> status) for step occurrences in a range.
  Future<Map<int, Map<int, String>>> getStepOccurrencesInRange(
    DateTime from,
    DateTime to,
  ) async {
    final db = await _db.database;
    final maps = await db.query(
      'task_step_occurrence',
      columns: ['step_id', 'occurrence_day', 'status'],
      where: 'occurrence_day >= ? AND occurrence_day <= ?',
      whereArgs: [ymdKey(from), ymdKey(to)],
    );
    final result = <int, Map<int, String>>{};
    for (final m in maps) {
      final stepId = m['step_id'] as int;
      final day = m['occurrence_day'] as int;
      final status = m['status'] as String;
      (result[stepId] ??= {})[day] = status;
    }
    return result;
  }

  Future<void> setStepOccurrenceStatus(
    int stepId,
    int taskId,
    DateTime day,
    String status,
  ) async {
    final db = await _db.database;
    await db.insert(
      'task_step_occurrence',
      {
        'step_id': stepId,
        'task_id': taskId,
        'occurrence_day': ymdKey(day),
        'status': status,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }


  // ---------------------------------------------------------------------------
  // Focus sessions
  // ---------------------------------------------------------------------------

  Future<int> createFocusSession(FocusSession session) async {
    final db = await _db.database;
    final data = session.toMap()..remove('id');
    return db.insert('focus_session', data);
  }

  Future<void> updateFocusSession(FocusSession session) async {
    final db = await _db.database;
    await db.update(
      'focus_session',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<List<FocusSession>> getFocusSessions({int limit = 50}) async {
    final db = await _db.database;
    final maps = await db.query(
      'focus_session',
      orderBy: 'start_time DESC',
      limit: limit,
    );
    return maps.map(FocusSession.fromMap).toList();
  }

  Future<FocusSession?> getActiveFocusSession() async {
    final db = await _db.database;
    final maps = await db.query(
      'focus_session',
      where: 'status = ?',
      whereArgs: [FocusStatus.focusing],
      orderBy: 'start_time DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return FocusSession.fromMap(maps.first);
  }

  Future<void> addFocusRestSegment(
    int sessionId,
    int start,
    int? end,
    int duration,
  ) async {
    final db = await _db.database;
    await db.insert('focus_rest_segment', {
      'session_id': sessionId,
      'start_time': start,
      'end_time': end,
      'duration': duration,
    });
  }


  // ---------------------------------------------------------------------------
  // Habits
  // ---------------------------------------------------------------------------

  Future<List<Task>> getHabitTasks() async {
    final db = await _db.database;
    final maps = await db.query(
      'task',
      where: 'is_habit = 1 AND (deleted_at IS NULL OR deleted_at = 0)',
      orderBy: 'sort_order ASC',
    );
    return maps.map(Task.fromMap).toList();
  }


  /// Lightweight task list for reminder re-scheduling.
  Future<List<Task>> getTasksForReminders() async {
    final db = await _db.database;
    final maps = await db.query(
      'task',
      columns: [
        'id',
        'title',
        'note',
        'color',
        'reminder_time',
        'start_date',
        'start_time',
        'created_at',
        'updated_at',
      ],
      where:
          '(reminder_time IS NOT NULL OR EXISTS (SELECT 1 FROM task_reminder r WHERE r.task_id = task.id AND r.is_enabled = 1))'
          ' AND (deleted_at IS NULL OR deleted_at = 0)',
    );
    return maps.map(Task.fromMap).toList();
  }

  /// Extra reminders for one task, ordered by offset.
  Future<List<TaskReminder>> getRemindersForTask(int taskId) async {
    final db = await _db.database;
    final maps = await db.query(
      'task_reminder',
      where: 'task_id = ? AND is_enabled = 1',
      whereArgs: [taskId],
      orderBy: 'offset_minutes ASC, id ASC',
    );
    return maps.map(TaskReminder.fromMap).toList();
  }

  /// Enabled extra reminders grouped by task, for app-start rescheduling.
  Future<Map<int, List<TaskReminder>>> getEnabledRemindersByTask() async {
    final db = await _db.database;
    final maps = await db.query(
      'task_reminder',
      where: 'is_enabled = 1',
      orderBy: 'task_id ASC, offset_minutes ASC, id ASC',
    );
    final grouped = <int, List<TaskReminder>>{};
    for (final map in maps) {
      final reminder = TaskReminder.fromMap(map);
      grouped.putIfAbsent(reminder.taskId, () => []).add(reminder);
    }
    return grouped;
  }

  /// Replace all extra reminders for a task in one transaction.
  Future<void> replaceTaskReminders(
    int taskId,
    List<TaskReminder> reminders,
  ) async {
    final db = await _db.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      await txn.delete(
        'task_reminder',
        where: 'task_id = ?',
        whereArgs: [taskId],
      );
      for (final reminder in reminders) {
        final data = reminder.copyWith(taskId: taskId, createdAt: now).toMap()
          ..remove('id');
        await txn.insert('task_reminder', data);
      }
    });
  }

}
