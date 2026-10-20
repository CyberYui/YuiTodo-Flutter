import 'package:flutter_test/flutter_test.dart';
import 'package:yuitodo/core/date/date_utils.dart';
import 'package:yuitodo/statistics/statistics_calculator.dart';
import 'package:yuitodo/models/task.dart';

void main() {
  group('startOfWeek', () {
    test('Monday start snaps a Wednesday back to Monday', () {
      expect(
        startOfWeek(DateTime(2026, 10, 21), 0),
        DateTime(2026, 10, 19),
      );
    });

    test('Sunday start snaps a Wednesday back to Sunday', () {
      expect(
        startOfWeek(DateTime(2026, 10, 21), 1),
        DateTime(2026, 10, 18),
      );
    });

    test('Sunday itself is the week start when Sunday is configured', () {
      final sunday = DateTime(2026, 10, 18);
      expect(startOfWeek(sunday, 1), sunday);
      expect(startOfWeek(sunday, 0), DateTime(2026, 10, 12));
    });

    test('time of day is ignored', () {
      expect(
        startOfWeek(DateTime(2026, 10, 21, 23, 59), 0),
        DateTime(2026, 10, 19),
      );
    });
  });

  group('StatisticsCalculator', () {
    test('calculate - empty tasks', () {
      final stats = StatisticsCalculator.calculate([]);
      expect(stats.totalTasks, 0);
      expect(stats.completedTasks, 0);
      expect(stats.completionRate, 0.0);
    });

    test('calculate - mixed tasks', () {
      final now = DateTime.now();
      final tasks = [
        Task(
          id: 1,
          title: 'Done task',
          status: 'done',
          startTime: now.millisecondsSinceEpoch,
          startDate: now.millisecondsSinceEpoch,
          createdAt: now.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
        ),
        Task(
          id: 2,
          title: 'Pending task',
          status: 'pending',
          startTime: now.millisecondsSinceEpoch,
          startDate: now.millisecondsSinceEpoch,
          createdAt: now.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
        ),
        Task(
          id: 3,
          title: 'Another done',
          status: 'done',
          startTime: now.millisecondsSinceEpoch,
          startDate: now.millisecondsSinceEpoch,
          createdAt: now.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
        ),
      ];

      final stats = StatisticsCalculator.calculate(tasks);
      expect(stats.totalTasks, 3);
      expect(stats.completedTasks, 2);
      expect(stats.pendingTasks, 1);
      expect(stats.completionRate, closeTo(0.667, 0.01));
    });

    test('calculate - overdue tasks', () {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final tasks = [
        Task(
          id: 1,
          title: 'Overdue task',
          status: 'pending',
          startTime: yesterday.millisecondsSinceEpoch,
          endTime: yesterday.millisecondsSinceEpoch,
          startDate: yesterday.millisecondsSinceEpoch,
          createdAt: yesterday.millisecondsSinceEpoch,
          updatedAt: yesterday.millisecondsSinceEpoch,
        ),
      ];

      final stats = StatisticsCalculator.calculate(tasks);
      expect(stats.overdueTasks, 1);
    });

    test('getTodayProgress - all completed', () {
      final now = DateTime.now();
      final tasks = [
        Task(
          id: 1,
          title: 'Task 1',
          status: 'done',
          startTime: now.millisecondsSinceEpoch,
          startDate: now.millisecondsSinceEpoch,
          createdAt: now.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
        ),
        Task(
          id: 2,
          title: 'Task 2',
          status: 'done',
          startTime: now.millisecondsSinceEpoch,
          startDate: now.millisecondsSinceEpoch,
          createdAt: now.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
        ),
      ];

      final progress = StatisticsCalculator.getTodayProgress(tasks);
      expect(progress, 1.0);
    });

    test('getTodayProgress - partial completion', () {
      final now = DateTime.now();
      final tasks = [
        Task(
          id: 1,
          title: 'Task 1',
          status: 'done',
          startTime: now.millisecondsSinceEpoch,
          startDate: now.millisecondsSinceEpoch,
          createdAt: now.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
        ),
        Task(
          id: 2,
          title: 'Task 2',
          status: 'pending',
          startTime: now.millisecondsSinceEpoch,
          startDate: now.millisecondsSinceEpoch,
          createdAt: now.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
        ),
      ];

      final progress = StatisticsCalculator.getTodayProgress(tasks);
      expect(progress, 0.5);
    });
  });
}
