import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/task.dart';
import '../../repositories/task_repository.dart';

/// Recycle Bin Provider - tracks deleted tasks (DB-backed)
final recycleBinProvider =
    StateNotifierProvider<RecycleBinNotifier, AsyncValue<List<Task>>>((ref) {
  return RecycleBinNotifier(ref.watch(taskRepositoryProvider));
});

class RecycleBinNotifier extends StateNotifier<AsyncValue<List<Task>>> {
  final TaskRepository _repo;

  RecycleBinNotifier(this._repo) : super(const AsyncValue.loading()) {
    loadDeletedTasks();
  }

  Future<void> loadDeletedTasks() async {
    state = const AsyncValue.loading();
    try {
      final tasks = await _repo.getDeletedTasks();
      state = AsyncValue.data(tasks);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void addDeleted(Task task) {
    state.whenData((tasks) {
      // Avoid duplicates
      if (tasks.any((t) => t.id == task.id)) return;
      state = AsyncValue.data([task, ...tasks]);
    });
  }

  Future<void> restore(Task task) async {
    await _repo.restoreTask(task.id!);
    await loadDeletedTasks();
  }

  /// Restore several tasks in one pass (used by the recycle bin batch mode).
  Future<void> restoreMany(List<Task> tasks) async {
    for (final task in tasks) {
      if (task.id != null) {
        await _repo.restoreTask(task.id!);
      }
    }
    await loadDeletedTasks();
  }

  Future<void> permanentDelete(int taskId) async {
    await _repo.deleteTask(taskId);
    await loadDeletedTasks();
  }

  Future<void> permanentDeleteMany(List<int> taskIds) async {
    for (final id in taskIds) {
      await _repo.deleteTask(id);
    }
    await loadDeletedTasks();
  }

  Future<void> clearAll() async {
    final tasks = state.valueOrNull ?? [];
    if (tasks.isEmpty) return;
    final ids = tasks.map((t) => t.id!).toList();
    for (final id in ids) {
      await _repo.deleteTask(id);
    }
    await loadDeletedTasks();
  }
}
