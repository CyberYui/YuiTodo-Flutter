import '../../models/recurrence_rule.dart';
import 'recurrence.dart';

/// Builds the concrete reminder timestamps for a task.
///
/// - [reminderTimes] handles the primary absolute reminder.
/// - [offsetReminderTimes] handles "N minutes before the task starts" extras.
/// - Recurring tasks expand to the next [maxOccurrences] occurrences within a
///   60-day lookahead.
class ReminderScheduler {
  static List<DateTime> reminderTimes({
    required DateTime anchor,
    required DateTime reminderDate,
    RecurrenceRule? rule,
    required DateTime now,
    int maxOccurrences = 7,
  }) {
    if (rule == null) {
      return reminderDate.isAfter(now) ? [reminderDate] : const [];
    }

    final times = <DateTime>[];
    for (final day in _occurrenceDays(anchor: anchor, rule: rule, now: now)) {
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

  /// Reminder timestamps for an offset reminder (minutes before the primary
  /// reminder). Offsets of hours or days land before the occurrence day
  /// instead of being pinned to the occurrence day's time-of-day.
  static List<DateTime> offsetReminderTimes({
    required DateTime anchor,
    required DateTime reminderDate,
    required int offsetMinutes,
    RecurrenceRule? rule,
    required DateTime now,
    int maxOccurrences = 7,
  }) {
    final offset = Duration(minutes: offsetMinutes);
    if (rule == null) {
      final t = reminderDate.subtract(offset);
      return t.isAfter(now) ? [t] : const [];
    }

    final times = <DateTime>[];
    for (final day in _occurrenceDays(anchor: anchor, rule: rule, now: now)) {
      final occurrenceReminder = DateTime(
        day.year,
        day.month,
        day.day,
        reminderDate.hour,
        reminderDate.minute,
      );
      final t = occurrenceReminder.subtract(offset);
      if (t.isAfter(now)) times.add(t);
      if (times.length >= maxOccurrences) break;
    }
    return times;
  }

  static List<DateTime> _occurrenceDays({
    required DateTime anchor,
    required RecurrenceRule rule,
    required DateTime now,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    return RecurrenceCalculator.occurrencesBetween(
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
