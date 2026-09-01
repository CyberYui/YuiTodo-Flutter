import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../repositories/task_repository.dart';

/// Tag list provider
final tagListProvider = StateNotifierProvider<TagNotifier, AsyncValue<List<Tag>>>((ref) {
  return TagNotifier(ref.watch(taskRepositoryProvider));
});

class TagNotifier extends StateNotifier<AsyncValue<List<Tag>>> {
  final TaskRepository _repo;

  TagNotifier(this._repo) : super(const AsyncValue.loading()) {
    loadTags();
  }

  Future<void> loadTags() async {
    state = const AsyncValue.loading();
    try {
      final tags = await _repo.getAllTags();
      state = AsyncValue.data(tags);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addTag(Tag tag) async {
    await _repo.createTag(tag);
    await loadTags();
  }

  Future<void> deleteTag(int tagId) async {
    await _repo.deleteTag(tagId);
    await loadTags();
  }

  Future<void> addTagToTask(int taskId, int tagId) async {
    await _repo.addTagToTask(taskId, tagId);
    await loadTags();
  }

  Future<void> removeTagFromTask(int taskId, int tagId) async {
    await _repo.removeTagFromTask(taskId, tagId);
    await loadTags();
  }
}

/// Selection mode provider for multi-select
final selectionProvider = StateNotifierProvider<SelectionNotifier, List<int>>((ref) {
  return SelectionNotifier();
});

class SelectionNotifier extends StateNotifier<List<int>> {
  SelectionNotifier() : super([]);

  void toggle(int taskId) {
    if (state.contains(taskId)) {
      state = state.where((id) => id != taskId).toList();
    } else {
      state = [...state, taskId];
    }
  }

  void clear() {
    state = [];
  }

  void selectAll(List<int> ids) {
    state = ids;
  }

  bool get isSelectionMode => state.isNotEmpty;
}
