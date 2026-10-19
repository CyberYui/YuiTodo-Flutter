import 'package:flutter/material.dart';

import '../../models/task.dart';

/// Primary absolute reminder plus extra "N minutes before the task" reminders.
class ReminderSelector extends StatelessWidget {
  static const int maxExtra = 5;

  final int? reminderTime; // epoch ms
  final List<TaskReminder> reminders;
  final bool isRecurring;
  final ValueChanged<int?> onReminderTimeChanged;
  final ValueChanged<List<TaskReminder>> onRemindersChanged;

  const ReminderSelector({
    super.key,
    this.reminderTime,
    this.reminders = const [],
    this.isRecurring = false,
    required this.onReminderTimeChanged,
    required this.onRemindersChanged,
  });

  static const _presets = <int>[5, 10, 15, 30, 60, 120, 1440, 2880];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (reminderTime == null)
          TextButton.icon(
            onPressed: () => _addReminder(context),
            icon: const Icon(Icons.add),
            label: const Text('添加定时提醒'),
          )
        else
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.notifications_outlined),
            title: Text(
              _formatDateTime(
                DateTime.fromMillisecondsSinceEpoch(reminderTime!),
              ),
            ),
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
                  onPressed: () => onReminderTimeChanged(null),
                ),
              ],
            ),
          ),
        for (var i = 0; i < reminders.length; i++) _extraTile(context, i),
        TextButton.icon(
          onPressed: reminderTime == null || reminders.length >= maxExtra
              ? null
              : () => _addExtra(context),
          icon: const Icon(Icons.add_alert_outlined),
          label: Text(
            reminders.isEmpty ? '添加提前提醒' : '再加一个提前提醒',
          ),
        ),
        if (reminders.isNotEmpty || isRecurring)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 2),
            child: Text(
              reminderTime == null
                  ? '先添加定时提醒，再添加提前提醒'
                  : (isRecurring
                      ? '提前提醒相对定时提醒计算，按每次发生生效'
                      : '提前提醒相对定时提醒计算'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
      ],
    );
  }

  Widget _extraTile(BuildContext context, int index) {
    final reminder = reminders[index];
    final offset = reminder.offsetMinutes;
    final primary = reminderTime == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(reminderTime!);
    final preview = (offset == null || primary == null)
        ? null
        : primary.subtract(Duration(minutes: offset));
    final String subtitle;
    if (preview == null) {
      subtitle = '相对定时提醒';
    } else if (isRecurring) {
      subtitle = '相对定时提醒';
    } else if (preview.isAfter(DateTime.now())) {
      subtitle = _formatDateTime(preview);
    } else {
      subtitle = '时间已过';
    }
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.alarm_outlined),
      title: Text(offset == null ? '额外提醒' : '提前 ${_formatOffset(offset)}'),
      subtitle: Text(isRecurring ? '$subtitle · 每次发生' : subtitle),
      trailing: IconButton(
        icon: const Icon(Icons.close),
        tooltip: '移除提醒',
        onPressed: () {
          final next = [...reminders]..removeAt(index);
          onRemindersChanged(next);
        },
      ),
    );
  }

  String _formatOffset(int minutes) {
    if (minutes % 1440 == 0) return '${minutes ~/ 1440} 天';
    if (minutes % 60 == 0) return '${minutes ~/ 60} 小时';
    return '$minutes 分钟';
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    final diff = day.difference(today).inDays;
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (diff == 0) return '今天 $time';
    if (diff == 1) return '明天 $time';
    if (diff == 2) return '后天 $time';
    return '${dt.month}月${dt.day}日 $time';
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

    final reminderDt =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    onReminderTimeChanged(reminderDt.millisecondsSinceEpoch);
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

    final reminderDt =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    onReminderTimeChanged(reminderDt.millisecondsSinceEpoch);
  }

  Future<void> _addExtra(BuildContext context) async {
    if (reminderTime == null) return;
    if (reminders.length >= maxExtra) return;
    final taken = reminders.map((r) => r.offsetMinutes).toSet();
    final choice = await showModalBottomSheet<int>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '提前多久提醒',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              for (final minutes in _presets)
                ListTile(
                  title: Text('提前 ${_formatOffset(minutes)}'),
                  enabled: !taken.contains(minutes),
                  trailing: taken.contains(minutes)
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => Navigator.pop(context, minutes),
                ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('自定义分钟数…'),
                onTap: () => Navigator.pop(context, -1),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    if (!context.mounted || choice == null) return;

    var minutes = choice;
    if (minutes == -1) {
      final controller = TextEditingController();
      final custom = await showDialog<int>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('自定义提前时间'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '提前分钟数',
              hintText: '例如 45',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                final value = int.tryParse(controller.text.trim());
                if (value != null && value > 0) {
                  Navigator.pop(context, value);
                }
              },
              child: const Text('确定'),
            ),
          ],
        ),
      );
      controller.dispose();
      if (custom == null) return;
      minutes = custom;
    }
    _addOffset(minutes);
  }

  void _addOffset(int minutes) {
    if (minutes <= 0) return;
    if (reminders.any((r) => r.offsetMinutes == minutes)) return;
    if (reminders.length >= maxExtra) return;
    final next = <TaskReminder>[
      ...reminders,
      TaskReminder(
        taskId: 0,
        offsetMinutes: minutes,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    ]..sort(
        (a, b) => (a.offsetMinutes ?? 0).compareTo(b.offsetMinutes ?? 0),
      );
    onRemindersChanged(next);
  }
}
