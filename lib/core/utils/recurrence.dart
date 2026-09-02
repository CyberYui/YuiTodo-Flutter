/// Recurrence types
enum RecurrenceType {
  none,
  daily,
  weekly,
  monthly,
  yearly,
  customDays,
  customWeeks,
}

extension RecurrenceTypeLabel on RecurrenceType {
  String get label {
    switch (this) {
      case RecurrenceType.none:
        return '不重复';
      case RecurrenceType.daily:
        return '每天';
      case RecurrenceType.weekly:
        return '每周';
      case RecurrenceType.monthly:
        return '每月';
      case RecurrenceType.yearly:
        return '每年';
      case RecurrenceType.customDays:
        return '每 N 天';
      case RecurrenceType.customWeeks:
        return '每 N 周';
    }
  }
}

/// Recurrence calculation utilities
class RecurrenceCalculator {
  /// Calculate next occurrence based on recurrence rule
  static DateTime? calculateNextOccurrence({
    required RecurrenceType type,
    required DateTime baseDate,
    int interval = 1,
    List<int>? daysOfWeek,
    int? dayOfMonth,
    int? monthOfYear,
    DateTime? endDate,
  }) {
    if (type == RecurrenceType.none) return null;
    if (endDate != null && baseDate.isAfter(endDate)) return null;

    DateTime next;

    switch (type) {
      case RecurrenceType.daily:
        next = baseDate.add(Duration(days: interval));
        break;
      case RecurrenceType.weekly:
        next = baseDate.add(Duration(days: 7 * interval));
        break;
      case RecurrenceType.monthly:
        next = DateTime(baseDate.year, baseDate.month + interval, baseDate.day);
        break;
      case RecurrenceType.yearly:
        next = DateTime(baseDate.year + interval, baseDate.month, baseDate.day);
        break;
      case RecurrenceType.customDays:
        next = baseDate.add(Duration(days: interval));
        break;
      case RecurrenceType.customWeeks:
        next = baseDate.add(Duration(days: 7 * interval));
        break;
      default:
        return null;
    }

    if (endDate != null && next.isAfter(endDate)) return null;
    return next;
  }

  /// Generate occurrences within a date range
  static List<DateTime> generateOccurrences({
    required RecurrenceType type,
    required DateTime startDate,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    int interval = 1,
    List<int>? daysOfWeek,
    int? dayOfMonth,
    int? monthOfYear,
    DateTime? recurrenceEndDate,
  }) {
    final occurrences = <DateTime>[];
    DateTime? current = startDate;

    while (current != null && current.isBefore(rangeEnd)) {
      if (current.isAfter(rangeStart) || current.isAtSameMomentAs(rangeStart)) {
        occurrences.add(current);
      }
      current = calculateNextOccurrence(
        type: type,
        baseDate: current,
        interval: interval,
        daysOfWeek: daysOfWeek,
        dayOfMonth: dayOfMonth,
        monthOfYear: monthOfYear,
        endDate: recurrenceEndDate,
      );
    }

    return occurrences;
  }

  /// Check if a task should appear on a specific date
  static bool shouldAppearOnDate({
    required RecurrenceType type,
    required DateTime taskStartDate,
    required DateTime date,
    int interval = 1,
    List<int>? daysOfWeek,
    int? dayOfMonth,
    int? monthOfYear,
    DateTime? endDate,
  }) {
    if (type == RecurrenceType.none) {
      return taskStartDate.year == date.year &&
             taskStartDate.month == date.month &&
             taskStartDate.day == date.day;
    }

    final occurrences = generateOccurrences(
      type: type,
      startDate: taskStartDate,
      rangeStart: DateTime(date.year, date.month, date.day),
      rangeEnd: DateTime(date.year, date.month, date.day + 1),
      interval: interval,
      daysOfWeek: daysOfWeek,
      dayOfMonth: dayOfMonth,
      monthOfYear: monthOfYear,
      recurrenceEndDate: endDate,
    );

    return occurrences.isNotEmpty;
  }
}
