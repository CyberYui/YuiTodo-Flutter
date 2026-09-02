import 'package:flutter_test/flutter_test.dart';
import 'package:yuitodo/core/utils/recurrence.dart';

void main() {
  group('RecurrenceCalculator', () {
    test('calculateNextOccurrence - daily', () {
      final base = DateTime(2026, 1, 1);
      final next = RecurrenceCalculator.calculateNextOccurrence(
        type: RecurrenceType.daily,
        baseDate: base,
      );
      expect(next, DateTime(2026, 1, 2));
    });

    test('calculateNextOccurrence - weekly', () {
      final base = DateTime(2026, 1, 1);
      final next = RecurrenceCalculator.calculateNextOccurrence(
        type: RecurrenceType.weekly,
        baseDate: base,
      );
      expect(next, DateTime(2026, 1, 8));
    });

    test('calculateNextOccurrence - monthly', () {
      final base = DateTime(2026, 1, 15);
      final next = RecurrenceCalculator.calculateNextOccurrence(
        type: RecurrenceType.monthly,
        baseDate: base,
      );
      expect(next, DateTime(2026, 2, 15));
    });

    test('calculateNextOccurrence - yearly', () {
      final base = DateTime(2026, 6, 15);
      final next = RecurrenceCalculator.calculateNextOccurrence(
        type: RecurrenceType.yearly,
        baseDate: base,
      );
      expect(next, DateTime(2027, 6, 15));
    });

    test('calculateNextOccurrence - custom interval', () {
      final base = DateTime(2026, 1, 1);
      final next = RecurrenceCalculator.calculateNextOccurrence(
        type: RecurrenceType.daily,
        baseDate: base,
        interval: 3,
      );
      expect(next, DateTime(2026, 1, 4));
    });

    test('calculateNextOccurrence - none returns null', () {
      final base = DateTime(2026, 1, 1);
      final next = RecurrenceCalculator.calculateNextOccurrence(
        type: RecurrenceType.none,
        baseDate: base,
      );
      expect(next, isNull);
    });

    test('calculateNextOccurrence - after end date returns null', () {
      final base = DateTime(2026, 1, 1);
      final next = RecurrenceCalculator.calculateNextOccurrence(
        type: RecurrenceType.daily,
        baseDate: base,
        endDate: DateTime(2025, 12, 31),
      );
      expect(next, isNull);
    });

    test('shouldAppearOnDate - non-recurring task', () {
      final taskDate = DateTime(2026, 1, 15);
      final result = RecurrenceCalculator.shouldAppearOnDate(
        type: RecurrenceType.none,
        taskStartDate: taskDate,
        date: DateTime(2026, 1, 15),
      );
      expect(result, isTrue);
    });

    test('shouldAppearOnDate - non-recurring task different date', () {
      final taskDate = DateTime(2026, 1, 15);
      final result = RecurrenceCalculator.shouldAppearOnDate(
        type: RecurrenceType.none,
        taskStartDate: taskDate,
        date: DateTime(2026, 1, 16),
      );
      expect(result, isFalse);
    });

    test('shouldAppearOnDate - daily recurring', () {
      final taskDate = DateTime(2026, 1, 1);
      final result = RecurrenceCalculator.shouldAppearOnDate(
        type: RecurrenceType.daily,
        taskStartDate: taskDate,
        date: DateTime(2026, 1, 5),
      );
      expect(result, isTrue);
    });
  });
}
