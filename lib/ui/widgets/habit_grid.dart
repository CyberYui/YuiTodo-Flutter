import 'package:flutter/material.dart';

import '../../providers/habit_provider.dart';

/// A compact 30-day check-in grid for one habit.
class HabitGrid extends StatelessWidget {
  final List<HabitDay> days;
  final Color color;

  const HabitGrid({super.key, required this.days, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 3,
      runSpacing: 3,
      children: days.map((d) {
        final done = d.isDone;
        return Tooltip(
          message: '${d.day.month}/${d.day.day}',
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: done ? color : Colors.transparent,
              border: Border.all(
                color: done ? color : theme.colorScheme.outlineVariant,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }).toList(),
    );
  }
}
