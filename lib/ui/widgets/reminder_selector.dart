import 'package:flutter/material.dart';

class ReminderSelector extends StatelessWidget {
  final List<String> times;
  final ValueChanged<List<String>> onChanged;

  const ReminderSelector({
    super.key,
    required this.times,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('提醒', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            TextButton.icon(
              onPressed: () => _addTime(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('添加'),
            ),
          ],
        ),
        ...times.asMap().entries.map((entry) {
          final index = entry.key;
          final time = entry.value;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.notifications_outlined),
            title: Text(time),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                final newTimes = List<String>.from(times)..removeAt(index);
                onChanged(newTimes);
              },
            ),
          );
        }),
      ],
    );
  }

  Future<void> _addTime(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      final newTimes = List<String>.from(times)..add(timeStr);
      onChanged(newTimes);
    }
  }
}
