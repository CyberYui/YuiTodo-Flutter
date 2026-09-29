import 'package:flutter/material.dart';
import '../../statistics/statistics_calculator.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final double height;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.height = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact stat card for single number display
class CompactStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const CompactStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MiniBarChart extends StatelessWidget {
  final List<double> values;
  final Color color;

  const MiniBarChart({super.key, required this.values, required this.color});

  @override
  Widget build(BuildContext context) {
    final maxValue = values.isEmpty
        ? 1.0
        : values.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 80,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: values.map((v) {
          final height = maxValue > 0 ? (v / maxValue) * 60 : 0.0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Container(
                height: height + 4,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// GitHub-style contribution heatmap
class ContributionHeatmap extends StatelessWidget {
  final Map<DateTime, int> data;
  final Color baseColor;

  const ContributionHeatmap({
    super.key,
    required this.data,
    required this.baseColor,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weeks = <List<_HeatmapDay>>[];

    // Calculate start date (52 weeks ago, aligned to Monday)
    final startDate = now.subtract(const Duration(days: 364));
    final monday = startDate.subtract(Duration(days: startDate.weekday - 1));
    var currentWeek = <_HeatmapDay>[];

    // Pad the first week
    final firstWeekday = monday.weekday;
    for (int i = 1; i < firstWeekday; i++) {
      currentWeek.add(
        _HeatmapDay(
          date: monday.subtract(Duration(days: firstWeekday - i)),
          count: -1,
        ),
      );
    }

    for (int i = 0; i < 364; i++) {
      final date = monday.add(Duration(days: i));
      final day = DateTime(date.year, date.month, date.day);
      final count = data[day] ?? 0;
      currentWeek.add(_HeatmapDay(date: day, count: count));

      if (currentWeek.length == 7) {
        weeks.add(currentWeek);
        currentWeek = <_HeatmapDay>[];
      }
    }

    if (currentWeek.isNotEmpty) {
      weeks.add(currentWeek);
    }

    // Find max count for color scaling
    final maxCount = data.values.isEmpty
        ? 1
        : data.values.reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: weeks.asMap().entries.map((entry) {
          final weekIndex = entry.key;
          final week = entry.value;
          return Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Column(
              children: [
                // Week label (month name on first week of month)
                if (weekIndex % 4 == 0 && week.isNotEmpty)
                  SizedBox(
                    height: 14,
                    child: Text(
                      _getMonthLabel(week.first.date),
                      style: TextStyle(
                        fontSize: 8,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 14),
                ...week.map((day) {
                  if (day.count < 0) {
                    return const SizedBox(width: 10, height: 10);
                  }
                  final intensity = maxCount > 0 ? day.count / maxCount : 0.0;
                  return Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: day.count == 0
                          ? baseColor.withOpacity(0.08)
                          : baseColor.withOpacity(0.2 + intensity * 0.8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getMonthLabel(DateTime date) {
    const months = ['1月', '3月', '5月', '7月', '9月', '11月'];
    if (date.day <= 7 && months.contains('${date.month}月')) {
      return '${date.month}月';
    }
    return '';
  }
}

/// Horizontal bar chart for tag distribution
class TagDistributionChart extends StatelessWidget {
  final List<TagStat> tagStats;
  final Color baseColor;

  const TagDistributionChart({
    super.key,
    required this.tagStats,
    required this.baseColor,
  });

  @override
  Widget build(BuildContext context) {
    if (tagStats.isEmpty) {
      return const Center(child: Text('暂无标签数据'));
    }

    final maxTotal = tagStats.map((t) => t.total).reduce((a, b) => a > b ? a : b);

    return Column(
      children: tagStats.take(5).map((tag) {
        final percentage = maxTotal > 0 ? tag.total / maxTotal : 0.0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  tag.name,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: baseColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: percentage,
                      child: Container(
                        height: 20,
                        decoration: BoxDecoration(
                          color: _parseColor(tag.color),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 40,
                child: Text(
                  '${tag.total}',
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _parseColor(String colorStr) {
    try {
      return Color(int.parse(colorStr.replaceFirst('#', '0xFF')));
    } catch (_) {
      return baseColor;
    }
  }
}

/// Weekday distribution chart
class WeekdayDistributionChart extends StatelessWidget {
  final Map<int, int> weekdayDistribution;
  final Color baseColor;

  const WeekdayDistributionChart({
    super.key,
    required this.weekdayDistribution,
    required this.baseColor,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = weekdayDistribution.values.isEmpty
        ? 1
        : weekdayDistribution.values.reduce((a, b) => a > b ? a : b);

    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];

    return SizedBox(
      height: 100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final weekday = index + 1;
          final count = weekdayDistribution[weekday] ?? 0;
          final height = maxValue > 0 ? (count / maxValue) * 80 : 0.0;
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '$count',
                style: const TextStyle(fontSize: 10),
              ),
              const SizedBox(height: 4),
              Container(
                width: 24,
                height: height + 4,
                decoration: BoxDecoration(
                  color: baseColor.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                weekdays[index],
                style: const TextStyle(fontSize: 12),
              ),
            ],
          );
        }),
      ),
    );
  }
}

/// Streak display card
class StreakCard extends StatelessWidget {
  final int currentStreak;
  final int longestStreak;
  final Color color;

  const StreakCard({
    super.key,
    required this.currentStreak,
    required this.longestStreak,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Icon(Icons.local_fire_department, color: color, size: 32),
                const SizedBox(height: 4),
                Text(
                  '$currentStreak',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const Text(
                  '当前连续',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            Container(
              height: 40,
              width: 1,
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
            Column(
              children: [
                Icon(Icons.emoji_events, color: color, size: 32),
                const SizedBox(height: 4),
                Text(
                  '$longestStreak',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const Text(
                  '最长连续',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeatmapDay {
  final DateTime date;
  final int count;

  _HeatmapDay({required this.date, required this.count});
}
