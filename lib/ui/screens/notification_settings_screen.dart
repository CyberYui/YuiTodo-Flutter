import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../services/notification_service.dart';

/// Permissions and system settings needed for reminders to fire while the app
/// is backgrounded or the screen is locked.
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool? _notifications;
  bool? _exactAlarm;
  PermissionStatus? _battery;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final notifications = await NotificationService.instance.checkPermission();
    bool? exact;
    final android = FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      exact = await android.canScheduleExactNotifications();
    }
    final battery = await Permission.ignoreBatteryOptimizations.status;
    if (!mounted) return;
    setState(() {
      _notifications = notifications;
      _exactAlarm = exact;
      _battery = battery;
    });
  }

  Future<void> _requestNotifications() async {
    await NotificationService.instance.requestPermission();
    await _refresh();
  }

  Future<void> _requestExactAlarm() async {
    await Permission.scheduleExactAlarm.request();
    await _refresh();
  }

  Future<void> _requestBattery() async {
    await Permission.ignoreBatteryOptimizations.request();
    await _refresh();
  }

  Future<void> _openAppSettings() async {
    await openAppSettings();
    await _refresh();
  }

  Future<void> _sendTest() async {
    await NotificationService.instance.scheduleReminder(
      id: 424243,
      title: '后台提醒测试',
      body: '如果你看到这条通知，后台提醒正常',
      scheduledTime: DateTime.now().add(const Duration(seconds: 30)),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已安排 30 秒后的提醒，请立即退到桌面或锁屏')),
    );
  }

  Widget _statusTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool? ok,
    required VoidCallback onRequest,
  }) {
    final granted = ok == true;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: granted
            ? const Icon(Icons.check_circle, color: Colors.green)
            : TextButton(
                onPressed: onRequest,
                child: const Text('去允许'),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final batteryGranted = _battery == PermissionStatus.granted;

    return Scaffold(
      appBar: AppBar(title: const Text('提醒与后台')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '后台提醒需要系统放行。ColorOS / OnePlus 请同时允许「自启动」和「后台运行」，'
              '并关闭电池优化；否则锁屏或后台时提醒可能被系统拦截。\n\n'
              '建议在系统设置中允许「闹钟和提醒」，并把本应用加入电池优化白名单。',
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 14),
          _statusTile(
            icon: Icons.notifications_outlined,
            title: '通知权限',
            subtitle: _notifications == true ? '已允许' : '未允许，无法显示提醒',
            ok: _notifications,
            onRequest: _requestNotifications,
          ),
          _statusTile(
            icon: Icons.alarm_outlined,
            title: '精确闹钟',
            subtitle: _exactAlarm == true
                ? '已允许，提醒更准时'
                : '未允许，提醒可能延迟',
            ok: _exactAlarm,
            onRequest: _requestExactAlarm,
          ),
          _statusTile(
            icon: Icons.battery_saver_outlined,
            title: '电池优化',
            subtitle: batteryGranted
                ? '已忽略（推荐）'
                : '未忽略，后台/锁屏可能收不到提醒',
            ok: batteryGranted,
            onRequest: _requestBattery,
          ),
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.settings_applications_outlined),
              title: const Text('自启动 / 后台运行'),
              subtitle: const Text('打开应用设置，手动允许自启动与后台运行'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _openAppSettings,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _sendTest,
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('发送测试提醒（30 秒后）'),
          ),
          const SizedBox(height: 8),
          Text(
            '测试方法：点击后立即退到桌面或锁屏，等待 30 秒。若收不到，请逐项允许上面的权限后重试。',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}
