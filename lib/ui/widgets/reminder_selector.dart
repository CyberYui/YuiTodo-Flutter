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
        if (times.isEmpty)
          TextButton.icon(
            onPressed: () => _addTime(context),
            icon: const Icon(Icons.add),
            label: const Text('添加提醒'),
          )
        else
          ...times.asMap().entries.map((entry) {
            final index = entry.key;
            final time = entry.value;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.notifications_outlined),
              title: Text(time),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editTime(context, index),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      final newTimes = List<String>.from(times)..removeAt(index);
                      onChanged(newTimes);
                    },
                  ),
                ],
              ),
            );
          }),
        if (times.isNotEmpty)
          TextButton.icon(
            onPressed: () => _addTime(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('添加提醒'),
          ),
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

  Future<void> _editTime(BuildContext context, int index) async {
    final timeParts = times[index].split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(timeParts[0]) ?? 0,
      minute: int.tryParse(timeParts[1]) ?? 0,
    );
    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (time != null) {
      final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      final newTimes = List<String>.from(times);
      newTimes[index] = timeStr;
      onChanged(newTimes);
    }
  }
}
