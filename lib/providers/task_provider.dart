import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../repositories/task_repository.dart';

/// Task list provider
final taskListProvider = StateNotifierProvider<TaskNotifier, AsyncValue<List<Task>>>((ref) {
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
    await _repo.deleteTask(taskId);
    await loadTasks();
  }

  Future<void> restoreTask(int taskId) async {
    await _repo.restoreTask(taskId);
    await loadTasks();
  }

  Future<void> toggleComplete(Task task) async {
    final newStatus = task.status == 'done' ? 'pending' : 'done';
    await _repo.updateTask(task.copyWith(status: newStatus));
    await loadTasks();
  }

  Future<void> toggleStar(Task task) async {
    await _repo.updateTask(task.copyWith(isStarred: !task.isStarred));
    await loadTasks();
  }

  Future<void> batchDelete(List<int> taskIds) async {
    await _repo.batchDelete(taskIds);
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
}
