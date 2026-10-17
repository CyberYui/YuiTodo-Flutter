import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/utils/reminder_scheduler.dart';
import '../models/recurrence_rule.dart';
import '../models/task.dart';
import 'package:permission_handler/permission_handler.dart';
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

    await _plugin.initialize(settings);

    // Create notification channel for Android
    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        await android.createNotificationChannel(
          const AndroidNotificationChannel(
            'task_reminders',
            'Task Reminders',
            description: 'Notifications for task reminders',
            importance: Importance.max,
            enableVibration: true,
            playSound: true,
          ),
        );
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
    required String title,
    required String body,
    required DateTime scheduledTime,
    Color? color,
    String? bigText,
  }) async {
    await initialize();

    // Ensure scheduled time is in the future (at least 5 seconds from now)
    final now = DateTime.now();
    if (scheduledTime.isBefore(now.add(const Duration(seconds: 5)))) {
      scheduledTime = now.add(const Duration(seconds: 10));
    }

    final androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      channelDescription: 'Notifications for task reminders',
      importance: Importance.max,
      priority: Priority.max,
      enableVibration: true,
      playSound: true,
      autoCancel: true,
      color: color,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
      ticker: title,
      styleInformation: BigTextStyleInformation(
        bigText ?? body,
        contentTitle: title,
        summaryText: 'YuiTodo',
      ),
    );

    const iosDetails = DarwinNotificationDetails();

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

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
      );
      debugPrint('Notification scheduled successfully');
    } catch (e) {
      debugPrint('Failed to schedule notification: $e');
      rethrow;
    }
  }

  int _taskBaseId(int taskId) => taskId * 1000;

  /// Cancel a task's single reminder and its occurrence slots.
  Future<void> cancelTaskReminders(int taskId, {int count = 7}) async {
    await _plugin.cancel(taskId);
    final base = _taskBaseId(taskId);
    for (var i = 1; i <= count; i++) {
      await _plugin.cancel(base + i);
    }
  }

  /// Schedule up to 7 occurrence reminders for a recurring task.
  Future<void> scheduleTaskOccurrences({
    required int taskId,
    required String title,
    required String body,
    required List<DateTime> times,
    Color? color,
    String? bigText,
  }) async {
    await cancelTaskReminders(taskId);
    final base = _taskBaseId(taskId);
    final capped = times.take(7).toList();
    for (var i = 0; i < capped.length; i++) {
      await scheduleReminder(
        id: base + i + 1,
        title: title,
        body: body,
        scheduledTime: capped[i],
        color: color,
        bigText: bigText,
      );
    }
  }

  /// Re-schedule every reminder on app start (survives app restarts and
  /// refreshes the rolling 7-day window for recurring tasks).
  Future<void> rescheduleAll(
    List<Task> tasks,
    Map<int, RecurrenceRule> rules,
  ) async {
    final now = DateTime.now();
    for (final task in tasks) {
      final id = task.id;
      final reminder = task.reminderTime;
      if (id == null || reminder == null) continue;
      final reminderDate = DateTime.fromMillisecondsSinceEpoch(reminder);
      final rule = rules[id];
      final color = _colorOf(task);
      final bigText = task.note.isNotEmpty ? task.note : '任务提醒';
      if (rule == null) {
        if (reminderDate.isAfter(now)) {
          await scheduleReminder(
            id: id,
            title: task.title,
            body: '任务提醒',
            scheduledTime: reminderDate,
            color: color,
            bigText: bigText,
          );
        }
        continue;
      }
      final anchor = DateTime.fromMillisecondsSinceEpoch(
        task.startDate ?? task.startTime ?? task.createdAt,
      );
      final times = ReminderScheduler.reminderTimes(
        anchor: anchor,
        reminderDate: reminderDate,
        rule: rule,
        now: now,
      );
      await scheduleTaskOccurrences(
        taskId: id,
        title: task.title,
        body: '任务提醒',
        times: times,
        color: color,
        bigText: bigText,
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

  Future<void> cancelReminder(int id) async {
    await _plugin.cancel(id);
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
