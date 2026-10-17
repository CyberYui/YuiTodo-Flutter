import '../../models/recurrence_rule.dart';
import '../../models/task.dart';
import '../../models/task_occurrence.dart';
import '../../repositories/task_repository.dart';
import '../utils/recurrence.dart';
import 'date_utils.dart';

/// Turns recurring templates + occurrence exceptions into a flat list of
/// virtual occurrences for a date range.
///
/// Read path: templates are stored once; occurrences are computed on demand.
/// Write path: completing/skipping writes a single `task_occurrence` row.
class TaskDateQueryEngine {
  final TaskRepository repo;

  TaskDateQueryEngine(this.repo);

  Future<List<TaskOccurrence>> queryRange(
    DateTime from,
    DateTime to, {
    bool includeAllNonRecurring = true,
  }) async {
    final fromDay = dateOnly(from);
    final toDay = dateOnly(to);

    final tasks = await repo.getAllTasks();
    final rules = await repo.getRecurrenceRuleMap();
    final occMap = await repo.getOccurrencesInRange(fromDay, toDay);

    final out = <TaskOccurrence>[];

    for (final task in tasks) {
      final rule = rules[task.id];

      if (rule == null) {
        // Non-recurring task: a single occurrence on its anchor date.
        final anchor = _anchorOf(task);
        if (anchor == null) continue;
        if (!includeAllNonRecurring &&
            (anchor.isBefore(fromDay) || anchor.isAfter(toDay))) {
          continue;
        }
        final state = task.status == 'done' ? 'done' : 'pending';
        out.add(TaskOccurrence(task: task, day: anchor, state: state));
        continue;
      }

      if (rule.isPaused == 1) continue;

      final anchor = _anchorOf(task) ??
          dateOnly(DateTime.fromMillisecondsSinceEpoch(rule.createdAt));
      final days = RecurrenceCalculator.occurrencesBetween(
        type: _typeOf(rule),
        anchor: anchor,
        from: fromDay,
        to: toDay,
        interval: rule.interval,
        daysOfWeek: _parseDays(rule.daysOfWeek),
        dayOfMonth: rule.dayOfMonth,
        monthOfYear: rule.monthOfYear,
        monthMode: rule.monthMode,
        weekIndex: rule.weekIndex,
        endType: rule.endType,
        endDate: rule.endDate != null
            ? DateTime.fromMillisecondsSinceEpoch(rule.endDate!)
            : null,
        endCount: rule.endCount,
        skipWeekends: rule.skipWeekends == 1,
        workdayOnly: rule.workdayOnly == 1,
      );

      final states = occMap[task.id!] ?? const <int, String>{};
      for (final day in days) {
        out.add(TaskOccurrence(
          task: task,
          day: day,
          state: states[ymdKey(day)] ?? 'pending',
        ));
      }
    }

    out.sort((a, b) {
      final byDay = a.day.compareTo(b.day);
      if (byDay != 0) return byDay;
      return a.task.sortOrder.compareTo(b.task.sortOrder);
    });
    return out;
  }

  /// Complete one occurrence. Recurring tasks write an exception row;
  /// non-recurring tasks flip the task status.
  Future<void> complete(Task task, DateTime day) async {
    final rules = await repo.getRecurrenceRuleMap();
    if (rules.containsKey(task.id)) {
      await repo.setOccurrenceState(task.id!, day, 'done');
    } else {
      await repo.updateTask(task.copyWith(status: 'done'));
    }
  }

  /// Undo completion for one occurrence.
  Future<void> uncomplete(Task task, DateTime day) async {
    final rules = await repo.getRecurrenceRuleMap();
    if (rules.containsKey(task.id)) {
      await repo.clearOccurrence(task.id!, day);
    } else {
      await repo.updateTask(task.copyWith(status: 'pending'));
    }
  }

  Future<void> skipOccurrence(TaskOccurrence occ) {
    return repo.setOccurrenceState(occ.task.id!, occ.day, 'skipped');
  }

  Future<void> clearOccurrence(TaskOccurrence occ) {
    return repo.clearOccurrence(occ.task.id!, occ.day);
  }

  DateTime? _anchorOf(Task task) {
    final ts = task.startDate ?? task.startTime ?? task.createdAt;
    return dateOnly(DateTime.fromMillisecondsSinceEpoch(ts));
  }

  RecurrenceType _typeOf(RecurrenceRule rule) {
    return RecurrenceType.values.firstWhere(
      (t) => t.name == rule.type,
      orElse: () => RecurrenceType.none,
    );
  }

  List<int>? _parseDays(String? s) {
    if (s == null || s.isEmpty) return null;
    final days = <int>[];
    for (final part in s.split(',')) {
      final n = int.tryParse(part.trim());
      if (n != null) days.add(n);
    }
    return days.isEmpty ? null : days;
  }
}
