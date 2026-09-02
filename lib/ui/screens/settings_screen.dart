import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme/app_theme.dart';
import '../providers/task_provider.dart';
import '../providers/tag_provider.dart';
import '../services/backup_service.dart';
import '../ui/screens/tag_management_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          // Theme section
          _SectionHeader(title: '外观'),
          ListTile(
            title: const Text('主题模式'),
            subtitle: Text(_themeModeLabel(themeMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemePicker(context, ref),
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
          const Divider(),

          // About section
          _SectionHeader(title: '关于'),
          const ListTile(
            title: Text('版本'),
            subtitle: Text('v4.0.0'),
          ),
          ListTile(
            title: Text('数据存储', style: TextStyle(color: theme.colorScheme.outline)),
            subtitle: const Text('纯本地 SQLite，无网络请求'),
          ),
        ],
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return '浅色模式';
      case ThemeMode.dark:
        return '深色模式';
      case ThemeMode.system:
        return '跟随系统';
    }
  }

  void _showThemePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('浅色模式'),
            leading: const Icon(Icons.light_mode),
            onTap: () {
              ref.read(themeProvider.notifier).setTheme(ThemeMode.light);
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('深色模式'),
            leading: const Icon(Icons.dark_mode),
            onTap: () {
              ref.read(themeProvider.notifier).setTheme(ThemeMode.dark);
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('跟随系统'),
            leading: const Icon(Icons.brightness_auto),
            onTap: () {
              ref.read(themeProvider.notifier).setTheme(ThemeMode.system);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    try {
      final json = await ref.read(backupServiceProvider).export();
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/yuitodo-backup-${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(json);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已导出到: ${file.path}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }

  Future<void> _importData(BuildContext context, WidgetRef ref) async {
    try {
      final picker = ImagePicker();
      // Note: image_picker doesn't support JSON, we need file_picker
      // For now, use a simple approach with a text input dialog
      
      final controller = TextEditingController();
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('导入数据'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: '粘贴 JSON 数据或输入文件路径',
            ),
            maxLines: 5,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('导入'),
            ),
          ],
        ),
      );

      if (result == null || result.trim().isEmpty) return;

      // Try to parse as JSON directly
      final count = await ref.read(backupServiceProvider).import(result);
      
      // Reload tasks
      await ref.read(taskListProvider.notifier).loadTasks();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已导入 $count 个任务')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e')),
        );
      }
    }
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
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
