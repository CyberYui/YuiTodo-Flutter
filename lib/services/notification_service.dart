import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../core/notifications/reminder_sounds.dart';
import '../core/utils/reminder_scheduler.dart';
import '../models/recurrence_rule.dart';
import '../models/task.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Notification service for task reminders
class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _tzInitialized = false;
  tz.Location? _location;

  Future<void> _ensureTimezoneInitialized() async {
    if (!_tzInitialized) {
      tz_data.initializeTimeZones();
      _location = tz.getLocation('Asia/Shanghai');
      _tzInitialized = true;
    }
  }

  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone data first
    await _ensureTimezoneInitialized();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        for (final option in reminderSounds) {
          await android.createNotificationChannel(option.channel);
        }
      }
    }

    _initialized = true;
  }

  /// Check if notification permission is granted (without requesting)
  Future<bool> checkPermission() async {
    await initialize();
    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final granted = await android.areNotificationsEnabled();
        return granted ?? false;
      }
    }
    return true;
  }

  /// Request notification permission from system
  Future<bool> requestPermission() async {
    await initialize();
    if (!kIsWeb && Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        return granted ?? false;
      }
    }
    return true;
  }

  /// Get pending scheduled notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _plugin.pendingNotificationRequests();
  }

  Future<void> scheduleReminder({
    required int id,
    int? taskId,
    required String title,
    required String body,
    required DateTime scheduledTime,
    Color? color,
    String? bigText,
    String? subText,
    String? soundKey,
    int slot = 0,
  }) async {
    await initialize();

    // Ensure scheduled time is in the future (at least 5 seconds from now)
    final now = DateTime.now();
    if (scheduledTime.isBefore(now.add(const Duration(seconds: 5)))) {
      scheduledTime = now.add(const Duration(seconds: 10));
    }

    final soundOption = reminderSoundFor(soundKey);
    final androidDetails = AndroidNotificationDetails(
      soundOption.channelId,
      soundOption.channelName,
      channelDescription: '任务提醒',
      importance: Importance.max,
      priority: Priority.max,
      enableVibration: true,
      playSound: true,
      sound: soundOption.sound,
      autoCancel: true,
      color: color,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
      ticker: title,
      subText: subText,
      useCustomLayout: true,
      styleInformation: BigTextStyleInformation(
        bigText ?? body,
        contentTitle: title,
        summaryText: 'YuiTodo',
      ),
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(
          'snooze',
          '稍后 10 分钟',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails();

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final payload = jsonEncode({
      'id': id,
      'taskId': taskId,
      'slot': slot,
      'soundKey': soundKey,
      'title': title,
      'body': body,
      'big': bigText ?? body,
    });

    // Convert DateTime to TZDateTime using local timezone
    final location = _location ?? tz.getLocation('Asia/Shanghai');
    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, location);

    // Prefer exact alarms. `canScheduleExactNotifications()` checks the real
    // AlarmManager capability (USE_EXACT_ALARM or SCHEDULE_EXACT_ALARM), which
    // is more accurate than permission_handler's SCHEDULE_EXACT_ALARM check.
    AndroidScheduleMode scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final canExact = await android?.canScheduleExactNotifications() ?? false;
      if (!canExact) {
        scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
        debugPrint('Exact alarms not permitted; scheduling inexact reminder');
      }
    }

    debugPrint('Scheduling notification: id=$id, title=$title, time=$scheduledTime, tzTime=$tzScheduledTime');

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledTime,
        details,
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      debugPrint('Notification scheduled successfully');
    } catch (e) {
      debugPrint('Failed to schedule notification: $e');
      rethrow;
    }
  }

  int _taskBaseId(int taskId) => taskId * 1000;

  /// Highest notification id offset reserved for one task. Primary
  /// occurrences use base+1..base+7; extra reminders use base+100..base+149.
  static const int _idRange = 200;
  static const int _maxOccurrences = 7;
  static const int _maxExtraReminders = 5;

  /// Cancel a task's primary reminder and every extra reminder slot.
  Future<void> cancelTaskReminders(int taskId) async {
    await initialize();
    final base = _taskBaseId(taskId);
    final pending = await _plugin.pendingNotificationRequests();
    final ids = <int>{taskId};
    for (final notification in pending) {
      if (notification.id > base && notification.id <= base + _idRange) {
        ids.add(notification.id);
      }
    }
    for (final id in ids) {
      await _plugin.cancel(id);
    }
  }

  /// Schedule a task's primary reminder and extra offset reminders.
  ///
  /// Callers pass already-computed timestamps (max 7 per reminder). Extra
  /// reminder index `r` keeps a stable notification id range so a later
  /// reschedule can cancel and replace it.
  Future<void> scheduleTaskReminders({
    required int taskId,
    required String title,
    required String body,
    required List<DateTime> primaryTimes,
    required List<List<DateTime>> extraTimes,
    required bool recurring,
    String? soundKey,
    Color? color,
    String? bigText,
  }) async {
    await cancelTaskReminders(taskId);
    final base = _taskBaseId(taskId);

    final primary = primaryTimes.take(_maxOccurrences).toList();
    for (var i = 0; i < primary.length; i++) {
      await scheduleReminder(
        id: recurring ? base + i + 1 : taskId,
        taskId: taskId,
        title: title,
        body: body,
        scheduledTime: primary[i],
        subText: formatNotificationTime(primary[i]),
        soundKey: soundKey,
        color: color,
        bigText: bigText,
      );
    }

    final extras = extraTimes.take(_maxExtraReminders).toList();
    for (var r = 0; r < extras.length; r++) {
      final times = extras[r].take(_maxOccurrences).toList();
      for (var i = 0; i < times.length; i++) {
        await scheduleReminder(
          id: base + 100 + r * 10 + i,
          taskId: taskId,
          title: title,
          body: body,
          scheduledTime: times[i],
          subText: '提前提醒 · ${formatNotificationTime(times[i])}',
          soundKey: soundKey,
          color: color,
          bigText: bigText,
          slot: r + 1,
        );
      }
    }
  }

  /// Re-schedule every reminder on app start (survives app restarts and
  /// refreshes the rolling 7-day window for recurring tasks).
  Future<void> rescheduleAll(
    List<Task> tasks,
    Map<int, RecurrenceRule> rules,
    Map<int, List<TaskReminder>> extraReminders,
  ) async {
    final now = DateTime.now();
    for (final task in tasks) {
      final id = task.id;
      if (id == null) continue;

      final extras = (extraReminders[id] ?? const <TaskReminder>[])
          .where((r) => r.isEnabled && r.offsetMinutes != null)
          .toList();
      final reminder = task.reminderTime;
      // Extra reminders are offsets from the primary reminder, so without one
      // there is nothing to anchor them to.
      if (reminder == null) continue;

      final rule = rules[id];
      final anchor = DateTime.fromMillisecondsSinceEpoch(
        task.startDate ?? task.startTime ?? task.createdAt,
      );

      final reminderDate = DateTime.fromMillisecondsSinceEpoch(reminder);
      final primaryTimes = ReminderScheduler.reminderTimes(
        anchor: anchor,
        reminderDate: reminderDate,
        rule: rule,
        now: now,
      );

      final extraTimes = <List<DateTime>>[];
      for (final extra in extras) {
        extraTimes.add(
          ReminderScheduler.offsetReminderTimes(
            anchor: anchor,
            reminderDate: reminderDate,
            offsetMinutes: extra.offsetMinutes!,
            rule: rule,
            now: now,
          ),
        );
      }

      if (primaryTimes.isEmpty && extraTimes.every((times) => times.isEmpty)) {
        continue;
      }

      await scheduleTaskReminders(
        taskId: id,
        title: task.title,
        body: '任务提醒',
        primaryTimes: primaryTimes,
        extraTimes: extraTimes,
        recurring: rule != null,
        soundKey: task.reminderSound,
        color: _colorOf(task),
        bigText: task.note.isNotEmpty ? task.note : '任务提醒',
      );
    }
  }

  Color? _colorOf(Task task) {
    try {
      return Color(int.parse(task.color.replaceFirst('#', '0xFF')));
    } catch (_) {
      return null;
    }
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Show an immediate test notification
  Future<void> showTestNotification() async {
    await initialize();
    await _plugin.show(
      9999,
      '测试通知',
      '通知功能正常工作',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders',
          'Task Reminders',
          channelDescription: 'Notifications for task reminders',
          importance: Importance.max,
          priority: Priority.max,
        ),
      ),
    );
  }
}

/// Runs in a background isolate when the user taps the "稍后 10 分钟" action.
/// It schedules the same notification 10 minutes later without opening the app.
@pragma('vm:entry-point')
Future<void> notificationTapBackground(NotificationResponse response) async {
  if (response.actionId != 'snooze' || response.payload == null) return;

  final Map<String, dynamic> data;
  try {
    data = jsonDecode(response.payload!) as Map<String, dynamic>;
  } catch (_) {
    return;
  }

  final id = (data['id'] as num?)?.toInt() ??
      DateTime.now().millisecondsSinceEpoch.remainder(100000);
  final title = data['title'] as String? ?? '任务提醒';
  final body = data['body'] as String? ?? '任务提醒';
  final big = data['big'] as String? ?? body;
  final soundOption = reminderSoundFor(data['soundKey'] as String?);

  WidgetsFlutterBinding.ensureInitialized();
  ui.DartPluginRegistrant.ensureInitialized();
  tz_data.initializeTimeZones();
  final location = tz.getLocation('Asia/Shanghai');

  final plugin = FlutterLocalNotificationsPlugin();
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  await plugin.initialize(const InitializationSettings(android: android));

  // Channels usually already exist; recreating is a no-op unless missing.
  final androidPlugin = plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  await androidPlugin?.createNotificationChannel(soundOption.channel);

  final when = tz.TZDateTime.now(location).add(const Duration(minutes: 10));
  final details = AndroidNotificationDetails(
    soundOption.channelId,
    soundOption.channelName,
    channelDescription: '任务提醒',
    importance: Importance.max,
    priority: Priority.max,
    enableVibration: true,
    playSound: true,
    sound: soundOption.sound,
    autoCancel: true,
    category: AndroidNotificationCategory.reminder,
    visibility: NotificationVisibility.public,
    ticker: title,
    subText: formatNotificationTime(when),
    useCustomLayout: true,
    styleInformation: BigTextStyleInformation(
      big,
      contentTitle: title,
      summaryText: 'YuiTodo',
    ),
    actions: const <AndroidNotificationAction>[
      AndroidNotificationAction(
        'snooze',
        '稍后 10 分钟',
        showsUserInterface: false,
        cancelNotification: true,
      ),
    ],
  );
  final notificationDetails = NotificationDetails(android: details);

  try {
    await plugin.zonedSchedule(
      id,
      title,
      body,
      when,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: response.payload,
    );
  } catch (e) {
    debugPrint('Snooze exact schedule failed ($e); retrying inexact');
    await plugin.zonedSchedule(
      id,
      title,
      body,
      when,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: response.payload,
    );
  }
  final slot = (data['slot'] as num?)?.toInt() ?? 0;
  final taskId = (data['taskId'] as num?)?.toInt();
  if (taskId != null && slot == 0) {
    try {
      final dir = await getApplicationDocumentsDirectory();
      // Use a separate connection: closing the app's shared sqflite instance
      // here would close the database for the running UI/isolate.
      final db = await openDatabase(
        p.join(dir.path, 'yuitodo.db'),
        singleInstance: false,
      );
      await db.update(
        'task',
        {
          'reminder_time': when.millisecondsSinceEpoch,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [taskId],
      );
      await db.close();
      debugPrint('Snooze updated task $taskId reminder_time');
    } catch (e) {
      debugPrint('Snooze DB update failed: $e');
    }
  }
  debugPrint('Snoozed notification $id to $when');
}

/// Human-readable label used by the custom notification layout.
String formatNotificationTime(DateTime dt) {
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
