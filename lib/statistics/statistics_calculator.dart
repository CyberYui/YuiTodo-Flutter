import '../models/task.dart';

/// Statistics data models
class TaskStatistics {
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final int overdueTasks;
  final double completionRate;
  final List<DailyCompletion> dailyCompletions;
  final List<WeeklyCompletion> weeklyCompletions;
  final Map<DateTime, int> heatmapData;

  TaskStatistics({
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
    required this.overdueTasks,
    required this.completionRate,
    required this.dailyCompletions,
    required this.weeklyCompletions,
    required this.heatmapData,
  });
}

class DailyCompletion {
  final DateTime date;
  final int completed;
  final int total;

  DailyCompletion({
    required this.date,
    required this.completed,
    required this.total,
  });

  double get rate => total > 0 ? completed / total : 0;
}

class WeeklyCompletion {
  final DateTime weekStart;
  final int completed;
  final int total;

  WeeklyCompletion({
    required this.weekStart,
    required this.completed,
    required this.total,
  });

  double get rate => total > 0 ? completed / total : 0;
}

/// Statistics calculator
class StatisticsCalculator {
  /// Calculate overview statistics
  static TaskStatistics calculate(List<Task> tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int completed = 0;
    int pending = 0;
    int overdue = 0;

    for (final task in tasks) {
      if (task.status == 'done') {
        completed++;
      } else {
        pending++;
        // Check if overdue
        if (task.endTime != null) {
          final endDate = DateTime.fromMillisecondsSinceEpoch(task.endTime!);
          if (endDate.isBefore(now)) {
            overdue++;
          }
        }
      }
    }

    final total = tasks.length;
    final completionRate = total > 0 ? completed / total : 0.0;

    // Calculate daily completions (last 30 days)
    final dailyCompletions = _calculateDailyCompletions(tasks, 30);

    // Calculate weekly completions (last 12 weeks)
    final weeklyCompletions = _calculateWeeklyCompletions(tasks, 12);

    // Calculate heatmap data (last 365 days)
    final heatmapData = _calculateHeatmap(tasks, 365);

    return TaskStatistics(
      totalTasks: total,
      completedTasks: completed,
      pendingTasks: pending,
      overdueTasks: overdue,
      completionRate: completionRate,
      dailyCompletions: dailyCompletions,
      weeklyCompletions: weeklyCompletions,
      heatmapData: heatmapData,
    );
  }

  static List<DailyCompletion> _calculateDailyCompletions(List<Task> tasks, int days) {
    final now = DateTime.now();
    final result = <DailyCompletion>[];

    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      int total = 0;
      int completed = 0;

      for (final task in tasks) {
        final taskDate = DateTime.fromMillisecondsSinceEpoch(task.startDate ?? task.startTime ?? 0);
        if (taskDate.isAfter(dayStart) && taskDate.isBefore(dayEnd)) {
          total++;
          if (task.status == 'done') completed++;
        }
      }

      result.add(DailyCompletion(date: dayStart, completed: completed, total: total));
    }

    return result;
  }

  static List<WeeklyCompletion> _calculateWeeklyCompletions(List<Task> tasks, int weeks) {
    final now = DateTime.now();
    final result = <WeeklyCompletion>[];

    for (int i = weeks - 1; i >= 0; i--) {
      final weekStart = now.subtract(Duration(days: 7 * i));
      final weekStartDay = weekStart.subtract(Duration(days: weekStart.weekday - 1));
      final weekEnd = weekStartDay.add(const Duration(days: 7));

      int total = 0;
      int completed = 0;

      for (final task in tasks) {
        final taskDate = DateTime.fromMillisecondsSinceEpoch(task.startDate ?? task.startTime ?? 0);
        if (taskDate.isAfter(weekStartDay) && taskDate.isBefore(weekEnd)) {
          total++;
          if (task.status == 'done') completed++;
        }
      }

      result.add(WeeklyCompletion(weekStart: weekStartDay, completed: completed, total: total));
    }

    return result;
  }

  static Map<DateTime, int> _calculateHeatmap(List<Task> tasks, int days) {
    final now = DateTime.now();
    final result = <DateTime, int>{};

    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      int count = 0;
      for (final task in tasks) {
        if (task.status == 'done') {
          final taskDate = DateTime.fromMillisecondsSinceEpoch(task.updatedAt);
          if (taskDate.isAfter(dayStart) && taskDate.isBefore(dayEnd)) {
            count++;
          }
        }
      }

      if (count > 0) {
        result[dayStart] = count;
      }
    }

    return result;
  }

  /// Get today's progress
  static double getTodayProgress(List<Task> tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayEnd = today.add(const Duration(days: 1));

    int total = 0;
    int completed = 0;

    for (final task in tasks) {
      final taskDate = DateTime.fromMillisecondsSinceEpoch(task.startDate ?? task.startTime ?? 0);
      if (taskDate.isAfter(today) && taskDate.isBefore(todayEnd)) {
        total++;
        if (task.status == 'done') completed++;
      }
    }

    return total > 0 ? completed / total : 0.0;
  }
}
