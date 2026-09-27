import 'package:flutter/material.dart';

class ReminderSelector extends StatelessWidget {
  final int? reminderTime; // epoch ms
  final ValueChanged<int?> onChanged;

  const ReminderSelector({
    super.key,
    this.reminderTime,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (reminderTime == null)
          TextButton.icon(
            onPressed: () => _addReminder(context),
            icon: const Icon(Icons.add),
            label: const Text('添加提醒'),
          )
        else ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.notifications_outlined),
            title: Text(_formatDateTime(reminderTime!)),
            subtitle: const Text('到期时通知提醒'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editReminder(context),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => onChanged(null),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _formatDateTime(int epochMs) {
    final dt = DateTime.fromMillisecondsSinceEpoch(epochMs);
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final isTomorrow = dt.year == now.year && dt.month == now.month && dt.day == now.day + 1;
    
    final timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    
    if (isToday) return '今天 $timeStr';
    if (isTomorrow) return '明天 $timeStr';
    return '${dt.month}月${dt.day}日 $timeStr';
  }

  Future<void> _addReminder(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (date == null) return;
    if (!context.mounted) return;
    
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: now.hour, minute: now.minute),
    );
    if (time == null) return;
    
    final reminderDt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    onChanged(reminderDt.millisecondsSinceEpoch);
  }

  Future<void> _editReminder(BuildContext context) async {
    if (reminderTime == null) return;
    final current = DateTime.fromMillisecondsSinceEpoch(reminderTime!);
    
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (date == null) return;
    if (!context.mounted) return;
    
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (time == null) return;
    
    final reminderDt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    onChanged(reminderDt.millisecondsSinceEpoch);
  }
}
