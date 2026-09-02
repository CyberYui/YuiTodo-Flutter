import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
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
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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

  const MiniBarChart({
    super.key,
    required this.values,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);
    
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

class AnnualHeatmap extends StatelessWidget {
  final Map<DateTime, int> data;
  final Color baseColor;

  const AnnualHeatmap({
    super.key,
    required this.data,
    required this.baseColor,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weeks = <List<_HeatmapDay>>[];
    
    // Calculate start date (52 weeks ago)
    final startDate = now.subtract(const Duration(days: 365));
    var currentWeek = <_HeatmapDay>[];
    
    // Pad the first week
    final firstWeekday = startDate.weekday;
    for (int i = 1; i < firstWeekday; i++) {
      currentWeek.add(_HeatmapDay(date: startDate.subtract(Duration(days: firstWeekday - i)), count: -1));
    }
    
    for (int i = 0; i < 365; i++) {
      final date = startDate.add(Duration(days: i));
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
    final maxCount = data.values.isEmpty ? 1 : data.values.reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: weeks.map((week) {
          return Column(
            children: week.map((day) {
              if (day.count < 0) {
                return const SizedBox(width: 12, height: 12);
              }
              final intensity = maxCount > 0 ? day.count / maxCount : 0.0;
              return Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: day.count == 0
                      ? baseColor.withOpacity(0.1)
                      : baseColor.withOpacity(0.2 + intensity * 0.8),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}

class _HeatmapDay {
  final DateTime date;
  final int count;

  _HeatmapDay({required this.date, required this.count});
}
