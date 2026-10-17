import '../date/date_utils.dart';

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

/// Recurrence calculation utilities.
///
/// The authoritative API is [occurrencesBetween]: it expands a rule into the
/// list of local dates that fall inside a range, respecting weekday selection,
/// monthly modes, end conditions and weekend/workday filters.
///
/// [calculateNextOccurrence] is kept for backward compatibility and simple
/// intervals; callers that need full rule semantics should use
/// [occurrencesBetween].
class RecurrenceCalculator {
  /// Calculate the next occurrence after [baseDate] for simple intervals.
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
      case RecurrenceType.customDays:
        next = baseDate.add(Duration(days: interval));
        break;
      case RecurrenceType.weekly:
      case RecurrenceType.customWeeks:
        next = baseDate.add(Duration(days: 7 * interval));
        break;
      case RecurrenceType.monthly:
        next = DateTime(baseDate.year, baseDate.month + interval, baseDate.day);
        break;
      case RecurrenceType.yearly:
        next = DateTime(baseDate.year + interval, baseDate.month, baseDate.day);
        break;
      case RecurrenceType.none:
        return null;
    }

    if (endDate != null && next.isAfter(endDate)) return null;
    return next;
  }

  /// Expand [type] starting at [anchor] into every local date inside
  /// `[from, to]` (both inclusive).
  ///
  /// - [daysOfWeek] uses 1=Monday .. 7=Sunday.
  /// - Monthly rules use [monthMode]:
  ///   - `day`      : the [dayOfMonth] (or anchor day), clamped to month length
  ///   - `last`     : the last day of the month
  ///   - `week`     : the [weekIndex]-th weekday (anchor weekday) of the month
  ///   - `week_last`: the last weekday (anchor weekday) of the month
  /// - [endType] is `none`, `date` or `count`.
  static List<DateTime> occurrencesBetween({
    required RecurrenceType type,
    required DateTime anchor,
    required DateTime from,
    required DateTime to,
    int interval = 1,
    List<int>? daysOfWeek,
    int? dayOfMonth,
    int? monthOfYear,
    String monthMode = 'day',
    int? weekIndex,
    String endType = 'none',
    DateTime? endDate,
    int? endCount,
    bool skipWeekends = false,
    bool workdayOnly = false,
  }) {
    final a = dateOnly(anchor);
    final rangeStart = dateOnly(from);
    final rangeEnd = dateOnly(to);
    if (rangeEnd.isBefore(rangeStart)) return const [];

    if (type == RecurrenceType.none) {
      return (!a.isBefore(rangeStart) && !a.isAfter(rangeEnd)) ? [a] : const [];
    }

    final step = interval < 1 ? 1 : interval;
    final countLimited = endType == 'count' && endCount != null;

    // For count-limited rules we must count from the anchor; otherwise we can
    // start at the requested range for efficiency.
    final start = countLimited
        ? a
        : (a.isAfter(rangeStart) ? a : rangeStart);
    final effectiveEndDate = endType == 'date' && endDate != null
        ? dateOnly(endDate)
        : null;

    final results = <DateTime>[];
    var matched = 0;
    var cursor = start;
    // Hard safety cap: 50 years from the anchor.
    final hardLimit = a.add(const Duration(days: 366 * 50));

    while (!cursor.isAfter(rangeEnd) && !cursor.isAfter(hardLimit)) {
      if (_matches(
        cursor,
        a,
        type,
        step,
        daysOfWeek,
        dayOfMonth,
        monthOfYear,
        monthMode,
        weekIndex,
        skipWeekends,
        workdayOnly,
      )) {
        if (effectiveEndDate != null && cursor.isAfter(effectiveEndDate)) {
          break;
        }
        matched++;
        if (countLimited && matched > endCount) break;
        if (!cursor.isBefore(rangeStart)) results.add(cursor);
      }
      cursor = cursor.add(const Duration(days: 1));
    }

    return results;
  }

  /// Generate occurrences within `[rangeStart, rangeEnd)` (legacy API).
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
    return occurrencesBetween(
      type: type,
      anchor: startDate,
      from: rangeStart,
      to: rangeEnd.subtract(const Duration(seconds: 1)),
      interval: interval,
      daysOfWeek: daysOfWeek,
      dayOfMonth: dayOfMonth,
      monthOfYear: monthOfYear,
      endType: recurrenceEndDate != null ? 'date' : 'none',
      endDate: recurrenceEndDate,
    );
  }

  /// Whether a task occurs on [date].
  static bool shouldAppearOnDate({
    required RecurrenceType type,
    required DateTime taskStartDate,
    required DateTime date,
    int interval = 1,
    List<int>? daysOfWeek,
    int? dayOfMonth,
    int? monthOfYear,
    DateTime? endDate,
    String monthMode = 'day',
    int? weekIndex,
    bool skipWeekends = false,
    bool workdayOnly = false,
  }) {
    if (type == RecurrenceType.none) {
      return dateOnly(taskStartDate) == dateOnly(date);
    }
    return occurrencesBetween(
      type: type,
      anchor: taskStartDate,
      from: date,
      to: date,
      interval: interval,
      daysOfWeek: daysOfWeek,
      dayOfMonth: dayOfMonth,
      monthOfYear: monthOfYear,
      monthMode: monthMode,
      weekIndex: weekIndex,
      endType: endDate != null ? 'date' : 'none',
      endDate: endDate,
      skipWeekends: skipWeekends,
      workdayOnly: workdayOnly,
    ).isNotEmpty;
  }

  static bool _matches(
    DateTime d,
    DateTime anchor,
    RecurrenceType type,
    int interval,
    List<int>? daysOfWeek,
    int? dayOfMonth,
    int? monthOfYear,
    String monthMode,
    int? weekIndex,
    bool skipWeekends,
    bool workdayOnly,
  ) {
    if (d.isBefore(anchor)) return false;

    final isWeekend =
        d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;
    if ((skipWeekends || workdayOnly) && isWeekend) return false;

    switch (type) {
      case RecurrenceType.none:
        return false;

      case RecurrenceType.daily:
      case RecurrenceType.customDays:
        return daysBetween(anchor, d) % interval == 0;

      case RecurrenceType.weekly:
      case RecurrenceType.customWeeks:
        if (type == RecurrenceType.weekly &&
            daysOfWeek != null &&
            daysOfWeek.isNotEmpty) {
          if (!daysOfWeek.contains(d.weekday)) return false;
          return _weekIndexBetween(anchor, d) % interval == 0;
        }
        return daysBetween(anchor, d) % (7 * interval) == 0;

      case RecurrenceType.monthly:
        final months =
            (d.year - anchor.year) * 12 + (d.month - anchor.month);
        if (months < 0 || months % interval != 0) return false;
        final lastDay = DateTime(d.year, d.month + 1, 0).day;
        switch (monthMode) {
          case 'last':
            return d.day == lastDay;
          case 'week':
            final indexInMonth = ((d.day - 1) ~/ 7) + 1;
            return d.weekday == anchor.weekday &&
                indexInMonth == (weekIndex ?? 1);
          case 'week_last':
            final last = DateTime(d.year, d.month + 1, 0);
            final offset = (last.weekday - anchor.weekday) % 7;
            return d.day == last.day - offset;
          case 'day':
          default:
            final target = dayOfMonth ?? anchor.day;
            final effective = target > lastDay ? lastDay : target;
            return d.day == effective;
        }

      case RecurrenceType.yearly:
        final years = d.year - anchor.year;
        if (years < 0 || years % interval != 0) return false;
        return d.month == (monthOfYear ?? anchor.month) &&
            d.day == (dayOfMonth ?? anchor.day);
    }
  }

  /// Number of Monday-based weeks between [anchor] and [d].
  static int _weekIndexBetween(DateTime anchor, DateTime d) {
    final anchorMonday = anchor.subtract(Duration(days: anchor.weekday - 1));
    final dMonday = d.subtract(Duration(days: d.weekday - 1));
    return dMonday.difference(anchorMonday).inDays ~/ 7;
  }
}
