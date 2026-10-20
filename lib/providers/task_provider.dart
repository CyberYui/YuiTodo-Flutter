import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task.dart';
import '../models/recurrence_rule.dart';
import '../repositories/task_repository.dart';

/// Recurrence rules provider
final recurrenceProvider =
    StateNotifierProvider<RecurrenceNotifier, AsyncValue<List<RecurrenceRule>>>((ref) {
  return RecurrenceNotifier(ref.watch(taskRepositoryProvider));
});

class RecurrenceNotifier extends StateNotifier<AsyncValue<List<RecurrenceRule>>> {
  final TaskRepository _repo;

  RecurrenceNotifier(this._repo) : super(const AsyncValue.loading()) {
    loadRecurrenceRules();
  }

  Future<void> loadRecurrenceRules() async {
    state = const AsyncValue.loading();
    try {
      final rules = await _repo.getRecurrenceRules();
      state = AsyncValue.data(rules);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createRecurrenceRule(RecurrenceRule rule) async {
    await _repo.createRecurrenceRule(rule);
    await loadRecurrenceRules();
  }

  Future<void> updateRecurrenceRule(RecurrenceRule rule) async {
    await _repo.updateRecurrenceRule(rule);
    await loadRecurrenceRules();
  }

  Future<void> deleteRecurrenceRule(int ruleId) async {
    await _repo.deleteRecurrenceRule(ruleId);
    await loadRecurrenceRules();
  }
}

/// Task list provider
final taskListProvider =
    StateNotifierProvider<TaskNotifier, AsyncValue<List<Task>>>((ref) {
      return TaskNotifier(ref.watch(taskRepositoryProvider));
    });

class TaskNotifier extends StateNotifier<AsyncValue<List<Task>>> {
  final TaskRepository _repo;

  TaskNotifier(this._repo) : super(const AsyncValue.loading()) {
    loadTasks();
  }

  Future<void> loadTasks() async {
    state = const AsyncValue.loading();
    try {
      final tasks = await _repo.getAllTasks();
      state = AsyncValue.data(tasks);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addTask(Task task) async {
    await _repo.createTask(task);
    await loadTasks();
  }

  Future<void> updateTask(Task task) async {
    await _repo.updateTask(task);
    await loadTasks();
  }

  Future<void> deleteTask(int taskId) async {
    await _repo.softDeleteTask(taskId);
    await loadTasks();
  }

  Future<void> restoreTask(int taskId) async {
    await _repo.restoreTask(taskId);
    await loadTasks();
  }

  /// Restore several tasks with a single list reload (batch undo).
  Future<void> restoreTasks(List<int> taskIds) async {
    for (final id in taskIds) {
      await _repo.restoreTask(id);
    }
    await loadTasks();
  }

  Future<void> toggleComplete(Task task) async {
    final newStatus = task.status == 'done' ? 'pending' : 'done';
    await _repo.updateTask(task.copyWith(status: newStatus));
    await loadTasks();
  }

  Future<void> batchDelete(List<int> taskIds) async {
    await _repo.batchSoftDelete(taskIds);
    await loadTasks();
  }

  Future<void> batchAddTag(List<int> taskIds, int tagId) async {
    await _repo.batchAddTag(taskIds, tagId);
    await loadTasks();
  }

  Future<void> batchRemoveTag(List<int> taskIds, int tagId) async {
    await _repo.batchRemoveTag(taskIds, tagId);
    await loadTasks();
  }

  Future<void> softDeleteTask(int taskId) async {
    await _repo.softDeleteTask(taskId);
    await loadTasks();
  }

  Future<void> batchSoftDelete(List<int> taskIds) async {
    await _repo.batchSoftDelete(taskIds);
    await loadTasks();
  }

  Future<void> updateTaskSortOrder(int taskId, int newOrder) async {
    await _repo.updateTaskSortOrder(taskId, newOrder);
    await loadTasks();
  }
}
