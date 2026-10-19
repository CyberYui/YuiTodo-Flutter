import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/date/date_utils.dart';
import '../models/task.dart';
import '../models/task_occurrence.dart';
import '../repositories/task_repository.dart';
import 'occurrence_provider.dart';

class HabitDay {
  final DateTime day;
  final String state; // done | pending | skipped

  const HabitDay(this.day, this.state);

  bool get isDone => state == 'done';
}

class HabitData {
  final Task task;
  final bool todayDone;
  final int streak;
  final int totalDays;
  final int weekDone;
  final List<HabitDay> days; // last 30 days, oldest first

  const HabitData({
    required this.task,
    required this.todayDone,
    required this.streak,
    required this.totalDays,
    required this.weekDone,
    required this.days,
  });
}

/// Habits derived from `is_habit = 1` tasks + their daily occurrences.
final habitProvider = FutureProvider<List<HabitData>>((ref) async {
  final repo = ref.watch(taskRepositoryProvider);
  final engine = ref.watch(taskDateQueryEngineProvider);

  final habits = await repo.getHabitTasks();
  if (habits.isEmpty) return const [];

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final from = today.subtract(const Duration(days: 89));
  final occs = await engine.queryRange(
    from,
    today,
    includeAllNonRecurring: false,
  );

  final byTask = <int, List<TaskOccurrence>>{};
  for (final o in occs) {
    final id = o.task.id;
    if (id == null) continue;
    (byTask[id] ??= []).add(o);
  }

  final result = <HabitData>[];
  for (final habit in habits) {
    final list = byTask[habit.id] ?? const <TaskOccurrence>[];
    final stateByDay = <int, String>{
      for (final o in list) ymdKey(o.day): o.state,
    };
    final todayDone = stateByDay[ymdKey(today)] == 'done';

    // Streak: consecutive done days ending today (or yesterday when today is
    // not done yet).
    var streak = 0;
    var cursor = todayDone ? today : today.subtract(const Duration(days: 1));
    while (stateByDay[ymdKey(cursor)] == 'done') {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    final totalDays = stateByDay.values.where((s) => s == 'done').length;

    final monday = today.subtract(Duration(days: today.weekday - 1));
    var weekDone = 0;
    for (var i = 0; i < 7; i++) {
      final d = monday.add(Duration(days: i));
      if (d.isAfter(today)) break;
      if (stateByDay[ymdKey(d)] == 'done') weekDone++;
    }

    final days = <HabitDay>[];
    for (var i = 89; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      days.add(HabitDay(d, stateByDay[ymdKey(d)] ?? 'pending'));
    }

    result.add(HabitData(
      task: habit,
      todayDone: todayDone,
      streak: streak,
      totalDays: totalDays,
      weekDone: weekDone,
      days: days,
    ));
  }
  return result;
});

/// Selected history window for the habit grid (7 / 30 / 90 days).
final habitRangeProvider = StateProvider<int>((ref) => 30);
