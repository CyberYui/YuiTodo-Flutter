import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/task.dart';

/// Recycle Bin Notifier
class RecycleBinNotifier extends StateNotifier<List<Task>> {
  RecycleBinNotifier() : super([]);

  void addDeleted(Task task) {
    state = [...state, task];
  }

  void restore(Task task) {
    state = state.where((t) => t.id != task.id).toList();
  }

  void permanentDelete(int taskId) {
    state = state.where((t) => t.id != taskId).toList();
  }

  void clearAll() {
    state = [];
  }
}

/// Recycle bin provider
final recycleBinProvider = StateNotifierProvider<RecycleBinNotifier, List<Task>>((ref) {
  return RecycleBinNotifier();
});
