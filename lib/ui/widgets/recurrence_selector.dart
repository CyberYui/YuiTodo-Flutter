import 'package:flutter/material.dart';
import '../../core/utils/recurrence.dart';

class RecurrenceSelector extends StatelessWidget {
  final RecurrenceType type;
  final int interval;
  final ValueChanged<RecurrenceType> onTypeChanged;
  final ValueChanged<int> onIntervalChanged;

  const RecurrenceSelector({
    super.key,
    required this.type,
    required this.interval,
    required this.onTypeChanged,
    required this.onIntervalChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('重复', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: RecurrenceType.values.map((t) {
            return ChoiceChip(
              label: Text(t.label),
              selected: type == t,
              onSelected: (_) => onTypeChanged(t),
            );
          }).toList(),
        ),
        if (type == RecurrenceType.customDays || type == RecurrenceType.customWeeks) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('每'),
              const SizedBox(width: 8),
              SizedBox(
                width: 60,
                child: TextFormField(
                  initialValue: interval.toString(),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final n = int.tryParse(v);
                    if (n != null && n > 0) onIntervalChanged(n);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text(type == RecurrenceType.customDays ? '天' : '周'),
            ],
          ),
        ],
      ],
    );
  }
}
