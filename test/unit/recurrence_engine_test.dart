import 'package:flutter_test/flutter_test.dart';
import 'package:yuitodo/core/utils/recurrence.dart';

void main() {
  final jan1 = DateTime(2026, 1, 1); // Thursday

  group('occurrencesBetween', () {
    test('daily interval 2', () {
      final days = RecurrenceCalculator.occurrencesBetween(
        type: RecurrenceType.daily,
        anchor: jan1,
        from: DateTime(2026, 1, 1),
        to: DateTime(2026, 1, 11),
        interval: 2,
      );
      expect(days, [
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 3),
        DateTime(2026, 1, 5),
        DateTime(2026, 1, 7),
        DateTime(2026, 1, 9),
        DateTime(2026, 1, 11),
      ]);
    });

    test('daily skip weekends', () {
      final days = RecurrenceCalculator.occurrencesBetween(
        type: RecurrenceType.daily,
        anchor: DateTime(2026, 1, 2), // Friday
        from: DateTime(2026, 1, 2),
        to: DateTime(2026, 1, 12),
        skipWeekends: true,
      );
      expect(days, [
        DateTime(2026, 1, 2),
        DateTime(2026, 1, 5),
        DateTime(2026, 1, 6),
        DateTime(2026, 1, 7),
        DateTime(2026, 1, 8),
        DateTime(2026, 1, 9),
        DateTime(2026, 1, 12),
      ]);
    });

    test('daily workday only', () {
      final days = RecurrenceCalculator.occurrencesBetween(
        type: RecurrenceType.daily,
        anchor: jan1,
        from: DateTime(2026, 1, 1),
        to: DateTime(2026, 1, 7),
        workdayOnly: true,
      );
      expect(days, [
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 2),
        DateTime(2026, 1, 5),
        DateTime(2026, 1, 6),
        DateTime(2026, 1, 7),
      ]);
    });

    test('weekly selected weekdays (Mon/Wed/Fri)', () {
      final days = RecurrenceCalculator.occurrencesBetween(
        type: RecurrenceType.weekly,
        anchor: jan1,
        from: DateTime(2026, 1, 1),
        to: DateTime(2026, 1, 11),
        daysOfWeek: [1, 3, 5],
      );
      expect(days, [
        DateTime(2026, 1, 2),
        DateTime(2026, 1, 5),
        DateTime(2026, 1, 7),
        DateTime(2026, 1, 9),
      ]);
    });

    test('weekly every 2 weeks respects interval alignment', () {
      final days = RecurrenceCalculator.occurrencesBetween(
        type: RecurrenceType.weekly,
        anchor: DateTime(2026, 1, 5), // Monday
        from: DateTime(2026, 1, 5),
        to: DateTime(2026, 1, 26),
        interval: 2,
        daysOfWeek: [1],
      );
      expect(days, [
        DateTime(2026, 1, 5),
        DateTime(2026, 1, 19),
      ]);
    });

    test('monthly on day, clamping short months', () {
      final days = RecurrenceCalculator.occurrencesBetween(
        type: RecurrenceType.monthly,
        anchor: DateTime(2026, 1, 31),
        from: DateTime(2026, 1, 1),
        to: DateTime(2026, 3, 31),
        dayOfMonth: 31,
      );
      expect(days, [
        DateTime(2026, 1, 31),
        DateTime(2026, 2, 28),
        DateTime(2026, 3, 31),
      ]);
    });

    test('monthly on last day', () {
      final days = RecurrenceCalculator.occurrencesBetween(
        type: RecurrenceType.monthly,
        anchor: DateTime(2026, 1, 31),
        from: DateTime(2026, 1, 1),
        to: DateTime(2026, 3, 31),
        monthMode: 'last',
      );
      expect(days, [
        DateTime(2026, 1, 31),
        DateTime(2026, 2, 28),
        DateTime(2026, 3, 31),
      ]);
    });

    test('monthly on the 2nd Tuesday', () {
      final days = RecurrenceCalculator.occurrencesBetween(
        type: RecurrenceType.monthly,
        anchor: DateTime(2026, 1, 13), // 2nd Tuesday
        from: DateTime(2026, 1, 1),
        to: DateTime(2026, 3, 31),
        monthMode: 'week',
        weekIndex: 2,
      );
      expect(days, [
        DateTime(2026, 1, 13),
        DateTime(2026, 2, 10),
        DateTime(2026, 3, 10),
      ]);
    });

    test('monthly on the last Friday', () {
      final days = RecurrenceCalculator.occurrencesBetween(
        type: RecurrenceType.monthly,
        anchor: DateTime(2026, 1, 30), // last Friday
        from: DateTime(2026, 1, 1),
        to: DateTime(2026, 3, 31),
        monthMode: 'week_last',
      );
      expect(days, [
        DateTime(2026, 1, 30),
        DateTime(2026, 2, 27),
        DateTime(2026, 3, 27),
      ]);
    });

    test('yearly on a fixed date', () {
      final days = RecurrenceCalculator.occurrencesBetween(
        type: RecurrenceType.yearly,
        anchor: DateTime(2026, 6, 15),
        from: DateTime(2026, 1, 1),
        to: DateTime(2028, 12, 31),
      );
      expect(days, [
        DateTime(2026, 6, 15),
        DateTime(2027, 6, 15),
        DateTime(2028, 6, 15),
      ]);
    });

    test('end by count', () {
      final days = RecurrenceCalculator.occurrencesBetween(
        type: RecurrenceType.daily,
        anchor: jan1,
        from: DateTime(2026, 1, 1),
        to: DateTime(2026, 1, 31),
        endType: 'count',
        endCount: 3,
      );
      expect(days, [
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 2),
        DateTime(2026, 1, 3),
      ]);
    });

    test('end by date', () {
      final days = RecurrenceCalculator.occurrencesBetween(
        type: RecurrenceType.daily,
        anchor: jan1,
        from: DateTime(2026, 1, 1),
        to: DateTime(2026, 1, 31),
        endType: 'date',
        endDate: DateTime(2026, 1, 5),
      );
      expect(days, [
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 2),
        DateTime(2026, 1, 3),
        DateTime(2026, 1, 4),
        DateTime(2026, 1, 5),
      ]);
    });

    test('none returns only the anchor date', () {
      final days = RecurrenceCalculator.occurrencesBetween(
        type: RecurrenceType.none,
        anchor: DateTime(2026, 1, 15),
        from: DateTime(2026, 1, 1),
        to: DateTime(2026, 1, 31),
      );
      expect(days, [DateTime(2026, 1, 15)]);
    });

    test('range excludes occurrences before from', () {
      final days = RecurrenceCalculator.occurrencesBetween(
        type: RecurrenceType.daily,
        anchor: jan1,
        from: DateTime(2026, 1, 10),
        to: DateTime(2026, 1, 12),
      );
      expect(days, [
        DateTime(2026, 1, 10),
        DateTime(2026, 1, 11),
        DateTime(2026, 1, 12),
      ]);
    });
  });

  group('shouldAppearOnDate with weekday selection', () {
    test('weekly Mon/Wed/Fri', () {
      expect(
        RecurrenceCalculator.shouldAppearOnDate(
          type: RecurrenceType.weekly,
          taskStartDate: jan1,
          date: DateTime(2026, 1, 7), // Wednesday
          daysOfWeek: [1, 3, 5],
        ),
        isTrue,
      );
      expect(
        RecurrenceCalculator.shouldAppearOnDate(
          type: RecurrenceType.weekly,
          taskStartDate: jan1,
          date: DateTime(2026, 1, 8), // Thursday
          daysOfWeek: [1, 3, 5],
        ),
        isFalse,
      );
    });
  });
}
