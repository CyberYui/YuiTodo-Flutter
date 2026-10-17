import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/date/task_date_query_engine.dart';
import '../models/task_occurrence.dart';
import '../repositories/task_repository.dart';

final taskDateQueryEngineProvider = Provider<TaskDateQueryEngine>((ref) {
  return TaskDateQueryEngine(ref.watch(taskRepositoryProvider));
});

/// Virtual occurrences for the home screen (1 year back / 1 year forward,
/// plus all non-recurring tasks).
final occurrenceListProvider =
    StateNotifierProvider<OccurrenceNotifier, AsyncValue<List<TaskOccurrence>>>(
        (ref) {
  return OccurrenceNotifier(ref.watch(taskDateQueryEngineProvider));
});

class OccurrenceNotifier
    extends StateNotifier<AsyncValue<List<TaskOccurrence>>> {
  final TaskDateQueryEngine _engine;

  OccurrenceNotifier(this._engine) : super(const AsyncValue.loading()) {
    load();
  }

  static DateTime get windowStart =>
      DateTime.now().subtract(const Duration(days: 365));
  static DateTime get windowEnd =>
      DateTime.now().add(const Duration(days: 365));

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final list = await _engine.queryRange(windowStart, windowEnd);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<List<TaskOccurrence>> queryRange(
    DateTime from,
    DateTime to, {
    bool includeAllNonRecurring = false,
  }) {
    return _engine.queryRange(
      from,
      to,
      includeAllNonRecurring: includeAllNonRecurring,
    );
  }

  Future<void> setDone(TaskOccurrence occ, bool done) async {
    if (done) {
      await _engine.complete(occ.task, occ.day);
    } else {
      await _engine.uncomplete(occ.task, occ.day);
    }
    await load();
  }

  Future<void> skip(TaskOccurrence occ) async {
    await _engine.skipOccurrence(occ);
    await load();
  }

  Future<void> clear(TaskOccurrence occ) async {
    await _engine.clearOccurrence(occ);
    await load();
  }
}
