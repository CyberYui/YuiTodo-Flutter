import '../../models/task.dart';

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

  // Extended statistics
  final int totalSteps;
  final int completedSteps;
  final double stepCompletionRate;
  final int starredTasks;
  final int totalTags;
  final List<TagStat> tagStats;
  final int currentStreak;
  final int longestStreak;
  final Map<int, int> weekdayDistribution; // 1=Monday, 7=Sunday
  final Map<int, int> monthlyDistribution; // 1-12
  final int appOpenCount;
  final Map<String, int> colorDistribution;

  TaskStatistics({
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
    required this.overdueTasks,
    required this.completionRate,
    required this.dailyCompletions,
    required this.weeklyCompletions,
    required this.heatmapData,
    this.totalSteps = 0,
    this.completedSteps = 0,
    this.stepCompletionRate = 0.0,
    this.starredTasks = 0,
    this.totalTags = 0,
    this.tagStats = const [],
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.weekdayDistribution = const {},
    this.monthlyDistribution = const {},
    this.appOpenCount = 0,
    this.colorDistribution = const {},
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

class TagStat {
  final String name;
  final String color;
  final int total;
  final int completed;

  TagStat({
    required this.name,
    required this.color,
    required this.total,
    required this.completed,
  });

  double get rate => total > 0 ? completed / total : 0;
}

/// Statistics calculator
class StatisticsCalculator {
  /// Calculate overview statistics
  static TaskStatistics calculate(List<Task> tasks, {int appOpenCount = 0}) {
    final now = DateTime.now();

    int completed = 0;
    int pending = 0;
    int overdue = 0;
    int starred = 0;
    int totalSteps = 0;
    int completedSteps = 0;

    // Tag stats
    final tagMap = <String, TagStat>{};
    final weekdayDist = <int, int>{};
    final monthlyDist = <int, int>{};
    final colorDist = <String, int>{};

    for (final task in tasks) {
      if (task.status == 'done') {
        completed++;
      } else {
        pending++;
        if (task.endTime != null) {
          final endDate = DateTime.fromMillisecondsSinceEpoch(task.endTime!);
          if (endDate.isBefore(now)) {
            overdue++;
          }
        }
      }

      if (task.isStarred) starred++;

      // Steps
      totalSteps += task.steps.length;
      completedSteps += task.steps.where((s) => s.status == 'completed').length;

      // Tag stats
      for (final tag in task.tags) {
        final existing = tagMap[tag.name];
        if (existing != null) {
          tagMap[tag.name] = TagStat(
            name: tag.name,
            color: tag.color,
            total: existing.total + 1,
            completed: existing.completed + (task.status == 'done' ? 1 : 0),
          );
        } else {
          tagMap[tag.name] = TagStat(
            name: tag.name,
            color: tag.color,
            total: 1,
            completed: task.status == 'done' ? 1 : 0,
          );
        }
      }

      // Weekday distribution (based on start_date or start_time)
      final taskDate = task.startDate ?? task.startTime;
      if (taskDate != null) {
        final dt = DateTime.fromMillisecondsSinceEpoch(taskDate);
        weekdayDist[dt.weekday] = (weekdayDist[dt.weekday] ?? 0) + 1;
        monthlyDist[dt.month] = (monthlyDist[dt.month] ?? 0) + 1;
      }

      // Color distribution
      colorDist[task.color] = (colorDist[task.color] ?? 0) + 1;
    }

    final total = tasks.length;
    final completionRate = total > 0 ? completed / total : 0.0;
    final stepRate = totalSteps > 0 ? completedSteps / totalSteps : 0.0;

    // Calculate daily completions (last 30 days)
    final dailyCompletions = _calculateDailyCompletions(tasks, 30);

    // Calculate weekly completions (last 12 weeks)
    final weeklyCompletions = _calculateWeeklyCompletions(tasks, 12);

    // Calculate heatmap data (last 365 days) - GitHub style
    final heatmapData = _calculateHeatmap(tasks, 365);

    // Calculate streaks
    final streaks = _calculateStreaks(tasks);

    return TaskStatistics(
      totalTasks: total,
      completedTasks: completed,
      pendingTasks: pending,
      overdueTasks: overdue,
      completionRate: completionRate,
      dailyCompletions: dailyCompletions,
      weeklyCompletions: weeklyCompletions,
      heatmapData: heatmapData,
      totalSteps: totalSteps,
      completedSteps: completedSteps,
      stepCompletionRate: stepRate,
      starredTasks: starred,
      totalTags: tagMap.length,
      tagStats: tagMap.values.toList()..sort((a, b) => b.total.compareTo(a.total)),
      currentStreak: streaks.$1,
      longestStreak: streaks.$2,
      weekdayDistribution: weekdayDist,
      monthlyDistribution: monthlyDist,
      appOpenCount: appOpenCount,
      colorDistribution: colorDist,
    );
  }

  static List<DailyCompletion> _calculateDailyCompletions(
    List<Task> tasks,
    int days,
  ) {
    final now = DateTime.now();
    final result = <DailyCompletion>[];

    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      int total = 0;
      int completed = 0;

      for (final task in tasks) {
        final taskDate = DateTime.fromMillisecondsSinceEpoch(
          task.startDate ?? task.startTime ?? 0,
        );
        if (taskDate.isAfter(dayStart) && taskDate.isBefore(dayEnd)) {
          total++;
          if (task.status == 'done') completed++;
        }
      }

      result.add(
        DailyCompletion(date: dayStart, completed: completed, total: total),
      );
    }

    return result;
  }

  static List<WeeklyCompletion> _calculateWeeklyCompletions(
    List<Task> tasks,
    int weeks,
  ) {
    final now = DateTime.now();
    final result = <WeeklyCompletion>[];

    for (int i = weeks - 1; i >= 0; i--) {
      final weekStart = now.subtract(Duration(days: 7 * i));
      final weekStartDay = weekStart.subtract(
        Duration(days: weekStart.weekday - 1),
      );
      final weekEnd = weekStartDay.add(const Duration(days: 7));

      int total = 0;
      int completed = 0;

      for (final task in tasks) {
        final taskDate = DateTime.fromMillisecondsSinceEpoch(
          task.startDate ?? task.startTime ?? 0,
        );
        if (taskDate.isAfter(weekStartDay) && taskDate.isBefore(weekEnd)) {
          total++;
          if (task.status == 'done') completed++;
        }
      }

      result.add(
        WeeklyCompletion(
          weekStart: weekStartDay,
          completed: completed,
          total: total,
        ),
      );
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

  /// Calculate current and longest completion streaks
  static (int, int) _calculateStreaks(List<Task> tasks) {
    if (tasks.isEmpty) return (0, 0);

    // Get all completion dates
    final completionDates = <DateTime>{};
    for (final task in tasks) {
      if (task.status == 'done') {
        final date = DateTime.fromMillisecondsSinceEpoch(task.updatedAt);
        completionDates.add(DateTime(date.year, date.month, date.day));
      }
    }

    if (completionDates.isEmpty) return (0, 0);

    // Sort dates
    final sortedDates = completionDates.toList()..sort();

    // Calculate current streak
    int currentStreak = 0;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // Check if today or yesterday has completions
    var checkDate = todayDate;
    if (!completionDates.contains(checkDate)) {
      checkDate = checkDate.subtract(const Duration(days: 1));
      if (!completionDates.contains(checkDate)) {
        currentStreak = 0;
      }
    }

    // Count current streak
    while (completionDates.contains(checkDate)) {
      currentStreak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    // Calculate longest streak
    int longestStreak = 0;
    int tempStreak = 1;
    for (int i = 1; i < sortedDates.length; i++) {
      final diff = sortedDates[i].difference(sortedDates[i - 1]).inDays;
      if (diff == 1) {
        tempStreak++;
      } else {
        if (tempStreak > longestStreak) longestStreak = tempStreak;
        tempStreak = 1;
      }
    }
    if (tempStreak > longestStreak) longestStreak = tempStreak;

    return (currentStreak, longestStreak);
  }

  /// Get today's progress
  static double getTodayProgress(List<Task> tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayEnd = today.add(const Duration(days: 1));

    int total = 0;
    int completed = 0;

    for (final task in tasks) {
      final taskDate = DateTime.fromMillisecondsSinceEpoch(
        task.startDate ?? task.startTime ?? 0,
      );
      if (taskDate.isAfter(today) && taskDate.isBefore(todayEnd)) {
        total++;
        if (task.status == 'done') completed++;
      }
    }

    return total > 0 ? completed / total : 0.0;
  }
}
