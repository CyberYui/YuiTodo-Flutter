import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_schemes.dart';
import '../../core/theme/font_pairs.dart';
import '../../providers/task_provider.dart';
import '../../providers/tag_provider.dart';
import '../screens/tag_management_screen.dart';
import '../screens/recycle_bin_screen.dart';

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
          
          // Light theme
          ListTile(
            title: const Text('浅色主题'),
            subtitle: Text(_themeSchemeLabel(_lightScheme)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLightThemePicker(context, ref),
          ),
          
          // Dark theme
          ListTile(
            title: const Text('深色主题'),
            subtitle: Text(_themeSchemeLabel(_darkScheme)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showDarkThemePicker(context, ref),
          ),
          
          // Font
          ListTile(
            title: const Text('字体'),
            subtitle: Text(AppFontPairs.getPair(_fontIndex).name),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showFontPicker(context, ref),
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

  static int _lightScheme = 0;
  static int _darkScheme = 0;
  static int _fontIndex = 0;

  String _themeSchemeLabel(int index) {
    return themeSchemes.values.toList()[index].name;
  }

  void _showLightThemePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('选择浅色主题', style: Theme.of(context).textTheme.titleLarge),
            ),
            ...themeSchemes.values.map((scheme) {
              return ListTile(
                title: Text(scheme.name),
                trailing: _lightScheme == themeSchemes.values.toList().indexOf(scheme)
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  _lightScheme = themeSchemes.values.toList().indexOf(scheme);
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
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('选择深色主题', style: Theme.of(context).textTheme.titleLarge),
            ),
            ...themeSchemes.values.map((scheme) {
              return ListTile(
                title: Text(scheme.name),
                trailing: _darkScheme == themeSchemes.values.toList().indexOf(scheme)
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  _darkScheme = themeSchemes.values.toList().indexOf(scheme);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        );
      },
    );
  }

  void _showFontPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('选择字体', style: Theme.of(context).textTheme.titleLarge),
            ),
            ...AppFontPairs.pairs.asMap().entries.map((entry) {
              final index = entry.key;
              final font = entry.value;
              return ListTile(
                title: Text(font.name),
                subtitle: Text(font.description),
                trailing: _fontIndex == index ? const Icon(Icons.check) : null,
                onTap: () {
                  _fontIndex = index;
                  Navigator.pop(context);
                },
              );
            }),
          ],
        );
      },
    );
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
