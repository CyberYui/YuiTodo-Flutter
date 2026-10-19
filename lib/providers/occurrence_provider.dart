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
    if (!state.hasValue) {
      state = const AsyncValue.loading();
    }
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
    _applyState(occ, done ? 'done' : 'pending');
  }

  Future<void> skip(TaskOccurrence occ) async {
    await _engine.skipOccurrence(occ);
    _applyState(occ, 'skipped');
  }

  Future<void> clear(TaskOccurrence occ) async {
    await _engine.clearOccurrence(occ);
    _applyState(occ, 'pending');
  }

  /// Update one step in memory after a step toggle, avoiding a full reload.
  void updateStep(TaskOccurrence occ, int stepId, String status) {
    final current = state.valueOrNull;
    if (current == null) {
      load();
      return;
    }
    state = AsyncValue.data(
      applyStepState(current, occ.task.id!, occ.dayKey, stepId, status),
    );
  }

  void _applyState(TaskOccurrence occ, String newState) {
    final current = state.valueOrNull;
    if (current == null) {
      load();
      return;
    }
    state = AsyncValue.data(
      applyOccurrenceState(current, occ.task.id!, occ.dayKey, newState),
    );
  }
}

/// Pure in-memory update used after completing/skipping an occurrence.
List<TaskOccurrence> applyOccurrenceState(
  List<TaskOccurrence> occurrences,
  int taskId,
  int dayKey,
  String state,
) {
  return [
    for (final occ in occurrences)
      if (occ.task.id == taskId && occ.dayKey == dayKey)
        occ.copyWith(
          state: state,
          task: occ.isRecurring
              ? occ.task
              : occ.task.copyWith(
                  status: state == 'done' ? 'done' : 'pending',
                ),
        )
      else
        occ,
  ];
}

/// Pure in-memory update used after toggling a subtask.
List<TaskOccurrence> applyStepState(
  List<TaskOccurrence> occurrences,
  int taskId,
  int dayKey,
  int stepId,
  String status,
) {
  return [
    for (final occ in occurrences)
      if (occ.task.id == taskId && occ.dayKey == dayKey)
        occ.copyWith(
          task: occ.task.copyWith(
            steps: [
              for (final step in occ.task.steps)
                if (step.id == stepId) step.copyWith(status: status) else step,
            ],
          ),
        )
      else
        occ,
  ];
}
