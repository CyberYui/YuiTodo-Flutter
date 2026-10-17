import '../../models/recurrence_rule.dart';
import 'recurrence.dart';

/// Builds the concrete reminder timestamps for a task.
///
/// - Non-recurring: a single timestamp at the task's reminder time.
/// - Recurring: the next [maxOccurrences] occurrences, each at the reminder
///   time's time-of-day, within a 60-day lookahead.
class ReminderScheduler {
  static List<DateTime> reminderTimes({
    required DateTime anchor,
    required DateTime reminderDate,
    RecurrenceRule? rule,
    required DateTime now,
    int maxOccurrences = 7,
  }) {
    final today = DateTime(now.year, now.month, now.day);

    if (rule == null) {
      return reminderDate.isAfter(now) ? [reminderDate] : const [];
    }

    final days = RecurrenceCalculator.occurrencesBetween(
      type: _typeOf(rule),
      anchor: anchor,
      from: today,
      to: today.add(const Duration(days: 60)),
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

    final times = <DateTime>[];
    for (final day in days) {
      final t = DateTime(
        day.year,
        day.month,
        day.day,
        reminderDate.hour,
        reminderDate.minute,
      );
      if (t.isAfter(now)) times.add(t);
      if (times.length >= maxOccurrences) break;
    }
    return times;
  }

  static RecurrenceType _typeOf(RecurrenceRule rule) {
    return RecurrenceType.values.firstWhere(
      (t) => t.name == rule.type,
      orElse: () => RecurrenceType.none,
    );
  }

  static List<int>? _parseDays(String? s) {
    if (s == null || s.isEmpty) return null;
    final days = <int>[];
    for (final part in s.split(',')) {
      final n = int.tryParse(part.trim());
      if (n != null) days.add(n);
    }
    return days.isEmpty ? null : days;
  }
}
