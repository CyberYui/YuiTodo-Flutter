import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme_schemes.dart';
import '../../core/theme/theme_state.dart';
import '../../core/theme/font_pairs.dart';
import '../screens/tag_management_screen.dart';
import '../screens/recycle_bin_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeState = ref.watch(themeStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          // Theme section
          _SectionHeader(title: '外观'),
          
          // Theme mode
          ListTile(
            title: const Text('主题模式'),
            subtitle: Text(_getThemeModeLabel(themeState.mode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeModePicker(context, ref),
          ),
          
          // Light theme
          ListTile(
            title: const Text('浅色主题'),
            subtitle: Text(themeSchemes[themeState.lightScheme]?.name ?? ''),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLightThemePicker(context, ref),
          ),
          
          // Dark theme
          ListTile(
            title: const Text('深色主题'),
            subtitle: Text(themeSchemes[themeState.darkScheme]?.name ?? ''),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showDarkThemePicker(context, ref),
          ),
          
          // Auto switch by time
          SwitchListTile(
            title: const Text('定时自动切换'),
            subtitle: Text(themeState.autoSwitchByTime 
                ? '已开启: ${_formatTime(themeState.darkStartTime)} - ${_formatTime(themeState.darkEndTime)}'
                : '关闭'),
            value: themeState.autoSwitchByTime,
            onChanged: (value) {
              ref.read(themeStateProvider.notifier).setAutoSwitchByTime(value);
            },
          ),
          
          // Time pickers (only show when auto switch is enabled)
          if (themeState.autoSwitchByTime) ...[
            ListTile(
              title: const Text('深色模式开始时间'),
              subtitle: Text(_formatTime(themeState.darkStartTime ?? const TimeOfDay(hour: 18, minute: 0))),
              trailing: const Icon(Icons.access_time),
              onTap: () => _showTimePicker(context, ref, isStartTime: true),
            ),
            ListTile(
              title: const Text('深色模式结束时间'),
              subtitle: Text(_formatTime(themeState.darkEndTime ?? const TimeOfDay(hour: 8, minute: 0))),
              trailing: const Icon(Icons.access_time),
              onTap: () => _showTimePicker(context, ref, isStartTime: false),
            ),
          ],
          
          // Font
          ListTile(
            title: const Text('字体'),
            subtitle: Text('系统默认'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Implement font picker
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('字体功能开发中...')),
              );
            },
          ),
          
          const Divider(),

          // Data section
          _SectionHeader(title: '数据管理'),
          ListTile(
            title: const Text('导出数据'),
            subtitle: const Text('导出为 JSON 文件'),
            trailing: const Icon(Icons.upload),
            onTap: () => _exportData(context, ref),
          ),
          ListTile(
            title: const Text('导入数据'),
            subtitle: const Text('从 JSON 文件恢复'),
            trailing: const Icon(Icons.download),
            onTap: () => _importData(context, ref),
          ),
          ListTile(
            title: const Text('管理标签'),
            subtitle: const Text('添加、删除标签'),
            trailing: const Icon(Icons.label),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TagManagementScreen()),
            ),
          ),
          ListTile(
            title: const Text('回收站'),
            subtitle: const Text('查看已删除的任务'),
            trailing: const Icon(Icons.delete_outline),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RecycleBinScreen()),
            ),
          ),
          
          const Divider(),

          // About section
          _SectionHeader(title: '关于'),
          const ListTile(
            title: Text('版本'),
            subtitle: Text('v4.1.0'),
          ),
          ListTile(
            title: Text('数据存储', style: TextStyle(color: theme.colorScheme.outline)),
            subtitle: const Text('纯本地 SQLite，无网络请求'),
          ),
        ],
      ),
    );
  }

  String _getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return '浅色模式';
      case ThemeMode.dark:
        return '深色模式';
      case ThemeMode.system:
        return '跟随系统';
    }
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '--:--';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _showThemeModePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('主题模式', style: Theme.of(context).textTheme.titleLarge),
            ),
            ListTile(
              title: const Text('浅色模式'),
              trailing: ref.read(themeStateProvider).mode == ThemeMode.light
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                ref.read(themeStateProvider.notifier).setMode(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('深色模式'),
              trailing: ref.read(themeStateProvider).mode == ThemeMode.dark
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                ref.read(themeStateProvider.notifier).setMode(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('跟随系统'),
              trailing: ref.read(themeStateProvider).mode == ThemeMode.system
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                ref.read(themeStateProvider.notifier).setMode(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _showLightThemePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final schemes = AppThemeScheme.values;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('选择浅色主题', style: Theme.of(context).textTheme.titleLarge),
            ),
            ...schemes.map((scheme) {
              return ListTile(
                title: Text(themeSchemes[scheme]?.name ?? ''),
                trailing: ref.read(themeStateProvider).lightScheme == scheme
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  ref.read(themeStateProvider.notifier).setLightScheme(scheme);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        );
      },
    );
  }

  void _showDarkThemePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final schemes = AppThemeScheme.values;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('选择深色主题', style: Theme.of(context).textTheme.titleLarge),
            ),
            ...schemes.map((scheme) {
              return ListTile(
                title: Text(themeSchemes[scheme]?.name ?? ''),
                trailing: ref.read(themeStateProvider).darkScheme == scheme
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  ref.read(themeStateProvider.notifier).setDarkScheme(scheme);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        );
      },
    );
  }

  Future<void> _showTimePicker(BuildContext context, WidgetRef ref, {required bool isStartTime}) async {
    final currentTime = isStartTime 
        ? ref.read(themeStateProvider).darkStartTime ?? const TimeOfDay(hour: 18, minute: 0)
        : ref.read(themeStateProvider).darkEndTime ?? const TimeOfDay(hour: 8, minute: 0);
    
    final time = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );
    
    if (time != null) {
      if (isStartTime) {
        ref.read(themeStateProvider.notifier).setDarkStart(time);
      } else {
        ref.read(themeStateProvider.notifier).setDarkEnd(time);
      }
    }
  }

  void _exportData(BuildContext context, WidgetRef ref) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('开发中...')),
    );
  }

  void _importData(BuildContext context, WidgetRef ref) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('开发中...')),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
