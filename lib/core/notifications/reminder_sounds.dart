import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// A selectable notification sound for task reminders.
///
/// Android channels are immutable once created, so each sound gets its own
/// channel id. The default option keeps the original `task_reminders` channel
/// and uses the system notification sound.
class ReminderSoundOption {
  final String? key;
  final String label;
  final String? rawName;
  final String channelId;
  final String channelName;

  const ReminderSoundOption({
    required this.key,
    required this.label,
    required this.rawName,
    required this.channelId,
    required this.channelName,
  });

  RawResourceAndroidNotificationSound? get sound =>
      rawName == null ? null : RawResourceAndroidNotificationSound(rawName!);

  AndroidNotificationChannel get channel => AndroidNotificationChannel(
        channelId,
        channelName,
        description: '任务提醒',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        sound: sound,
      );
}

/// Order is used by the picker; the first entry is the default.
const List<ReminderSoundOption> reminderSounds = <ReminderSoundOption>[
  ReminderSoundOption(
    key: null,
    label: '跟随系统',
    rawName: null,
    channelId: 'task_reminders',
    channelName: '任务提醒',
  ),
  ReminderSoundOption(
    key: 'chime',
    label: '清脆',
    rawName: 'yuitodo_chime',
    channelId: 'task_reminders_chime',
    channelName: '任务提醒 · 清脆',
  ),
  ReminderSoundOption(
    key: 'pop',
    label: '弹跳',
    rawName: 'yuitodo_pop',
    channelId: 'task_reminders_pop',
    channelName: '任务提醒 · 弹跳',
  ),
  ReminderSoundOption(
    key: 'bell',
    label: '铃铛',
    rawName: 'yuitodo_bell',
    channelId: 'task_reminders_bell',
    channelName: '任务提醒 · 铃铛',
  ),
  ReminderSoundOption(
    key: 'digital',
    label: '电子',
    rawName: 'yuitodo_digital',
    channelId: 'task_reminders_digital',
    channelName: '任务提醒 · 电子',
  ),
  ReminderSoundOption(
    key: 'soft',
    label: '轻柔',
    rawName: 'yuitodo_soft',
    channelId: 'task_reminders_soft',
    channelName: '任务提醒 · 轻柔',
  ),
];

ReminderSoundOption reminderSoundFor(String? key) {
  for (final option in reminderSounds) {
    if (option.key == key) return option;
  }
  return reminderSounds.first;
}
