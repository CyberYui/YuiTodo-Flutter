import 'package:flutter_test/flutter_test.dart';
import 'package:yuitodo/core/utils/reminder_scheduler.dart';
import 'package:yuitodo/models/recurrence_rule.dart';

void main() {
  group('offsetReminderTimes', () {
    test('non-recurring offsets before the task start', () {
      final start = DateTime(2026, 10, 20, 9, 0);
      final times = ReminderScheduler.offsetReminderTimes(
        anchor: start,
        reminderDate: start,
        offsetMinutes: 10,
        now: DateTime(2026, 10, 19, 8, 0),
      );
      expect(times, [DateTime(2026, 10, 20, 8, 50)]);
    });

    test('non-recurring reminder in the past is dropped', () {
      final start = DateTime(2026, 10, 20, 9, 0);
      final times = ReminderScheduler.offsetReminderTimes(
        anchor: start,
        reminderDate: start,
        offsetMinutes: 10,
        now: DateTime(2026, 10, 20, 9, 0),
      );
      expect(times, isEmpty);
    });

    test('recurring one-day offset lands on the previous day', () {
      final rule = RecurrenceRule(taskId: 1, type: 'daily', createdAt: 0);
      final times = ReminderScheduler.offsetReminderTimes(
        anchor: DateTime(2026, 10, 19, 9, 0),
        reminderDate: DateTime(2026, 10, 19, 9, 0),
        offsetMinutes: 1440,
        rule: rule,
        now: DateTime(2026, 10, 19, 8, 0),
      );
      expect(times.first, DateTime(2026, 10, 19, 9, 0));
      expect(times.length, 7);
      expect(times[1], DateTime(2026, 10, 20, 9, 0));
    });

    test('recurring short offset keeps the occurrence day', () {
      final rule = RecurrenceRule(taskId: 1, type: 'daily', createdAt: 0);
      final times = ReminderScheduler.offsetReminderTimes(
        anchor: DateTime(2026, 10, 19, 9, 0),
        reminderDate: DateTime(2026, 10, 19, 9, 0),
        offsetMinutes: 30,
        rule: rule,
        now: DateTime(2026, 10, 19, 8, 0),
      );
      expect(times.first, DateTime(2026, 10, 19, 8, 30));
      expect(times.length, 7);
    });
  });

  group('reminderTimes (primary)', () {
    test('non-recurring uses the absolute reminder', () {
      final reminder = DateTime(2026, 10, 20, 10, 15);
      final times = ReminderScheduler.reminderTimes(
        anchor: DateTime(2026, 10, 20, 9, 0),
        reminderDate: reminder,
        now: DateTime(2026, 10, 19, 8, 0),
      );
      expect(times, [reminder]);
    });

    test('recurring repeats the reminder time-of-day', () {
      final rule = RecurrenceRule(taskId: 1, type: 'daily', createdAt: 0);
      final times = ReminderScheduler.reminderTimes(
        anchor: DateTime(2026, 10, 19, 9, 0),
        reminderDate: DateTime(2026, 10, 19, 8, 45),
        rule: rule,
        now: DateTime(2026, 10, 19, 8, 0),
      );
      expect(times.first, DateTime(2026, 10, 19, 8, 45));
      expect(times.length, 7);
    });
  });
}
