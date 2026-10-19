import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/theme/theme_schemes.dart';
import '../../core/theme/theme_state.dart';
import '../../core/theme/font_pairs.dart';
import '../../core/theme/font_state.dart';
import '../screens/tag_management_screen.dart';
import '../screens/recycle_bin_screen.dart';
import '../screens/habit_screen.dart';
import '../widgets/sun_moon_icon.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeState = ref.watch(themeStateProvider);
    final fontIndex = ref.watch(fontIndexProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('设置', style: TextStyle(color: theme.colorScheme.onSurface)),
        backgroundColor: theme.appBarTheme.backgroundColor,
      ),
      body: ListView(
        children: [
          // Theme section
          _SectionHeader(title: '外观'),
          
          // Theme mode
          ListTile(
            leading: SunMoonIcon(
              isDark: themeState.isDarkMode,
              size: 24,
              color: theme.colorScheme.primary,
            ),
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
          // 字体选择入口：点击打开字体选择器弹窗
          ListTile(
            title: const Text('字体'),
            subtitle: Text(AppFontPairs.getPair(fontIndex).name),  // 显示当前选中的字体名称
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showFontPicker(context, ref),  // 打开字体选择器
          ),

          // 开源字体许可（两个版本都保留）
          ListTile(
            leading: const Icon(Icons.verified_outlined),
            title: const Text('开源字体'),
            subtitle: const Text('思源黑体 / 得意黑 / 霞鹜文楷 / IBM Plex · SIL OFL 1.1'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showOpenFontCredits(context),
          ),
          
          const Divider(),

          // Data section
          _SectionHeader(title: '功能'),
          ListTile(
            leading: const Icon(Icons.check_circle_outline),
            title: const Text('习惯打卡'),
            subtitle: const Text('每日习惯与连续记录'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HabitScreen()),
            ),
          ),

          const Divider(),
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
          _VersionTile(),
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
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('选择浅色主题', style: Theme.of(context).textTheme.titleLarge),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: schemes.length,
                  itemBuilder: (context, index) {
                    final scheme = schemes[index];
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
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDarkThemePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final schemes = AppThemeScheme.values;
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('选择深色主题', style: Theme.of(context).textTheme.titleLarge),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: schemes.length,
                  itemBuilder: (context, index) {
                    final scheme = schemes[index];
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
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showOpenFontCredits(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('开源字体许可'),
        content: const SingleChildScrollView(
          child: Text(
            '思源黑体 Source Han Sans SC · Adobe\n'
            '得意黑 Smiley Sans · atelier-anchor\n'
            '霞鹜文楷 LXGW WenKai Lite · LXGW\n'
            'IBM Plex Sans SC / IBM Plex Mono · IBM\n\n'
            '许可：SIL Open Font License 1.1\n'
            '字体文件仅用于界面显示，遵循 OFL 1.1 许可；'
            '完整许可文本见 assets/fonts/open/ 目录。',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 字体选择器弹窗
  /// 显示所有可用的字体配对方案
  /// 用户选择后更新 fontIndexProvider，触发整个应用的字体刷新
  /// Switch fonts behind a full-screen loading mask.
  ///
  /// Rebuilding the TextTheme makes every screen reflow at once; the mask
  /// hides that transition and blocks taps until the layout settles.
  Future<void> _applyFont(
    BuildContext context,
    WidgetRef ref,
    int index,
  ) async {
    final overlay = Overlay.of(context, rootOverlay: true);
    final navigator = Navigator.of(context, rootNavigator: true);
    final entry = OverlayEntry(builder: (_) => const _FontApplyOverlay());
    overlay.insert(entry);
    navigator.pop(); // close the picker sheet
    // Let the mask paint before the TextTheme rebuild.
    await Future<void>.delayed(const Duration(milliseconds: 70));
    ref.read(fontIndexProvider.notifier).setIndex(index);
    // Keep the mask until the new layout has settled.
    await Future<void>.delayed(const Duration(milliseconds: 520));
    entry.remove();
  }

  void _showFontPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '选择字体',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      TextButton(
                        onPressed: () => _applyFont(context, ref, 0),
                        child: const Text('恢复默认'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: AppFontPairs.pairs.length,  // 字体配对总数
                    itemBuilder: (context, index) {
                      final font = AppFontPairs.pairs[index];  // 当前字体配对
                      final currentIndex = ref.watch(fontIndexProvider);  // 当前选中的字体索引
                      return ListTile(
                        // 字体名称（使用对应字体显示预览）
                        title: Text(font.name, style: TextStyle(fontFamily: font.chineseFontFamily)),
                        // 字体风格描述 + 中英数字预览
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(font.description),
                            const SizedBox(height: 2),
                            Text(
                              '任务 今天 08:00 · 123 ABC',
                              style: TextStyle(
                                fontFamily: font.chineseFontFamily,
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                        // 选中标记
                        trailing: currentIndex == index
                            ? const Icon(Icons.check)
                            : null,
                        // 点击选中字体：loading 遮罩掩盖全局重排
                        onTap: () => _applyFont(context, ref, index),
                      );
                    },
                  ),
                ),
              ],
            );
          },
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

/// Version display tile - reads version from PackageInfo (set in pubspec.yaml)
class _VersionTile extends ConsumerStatefulWidget {
  @override
  ConsumerState<_VersionTile> createState() => _VersionTileState();
}

class _VersionTileState extends ConsumerState<_VersionTile> {
  String _version = '未知';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _version = 'v${info.version}');
      }
    } catch (_) {
      if (mounted) setState(() => _version = '未知');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('版本'),
      subtitle: Text(_version),
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

class _FontApplyOverlay extends StatelessWidget {
  const _FontApplyOverlay();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned.fill(
      child: AbsorbPointer(
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.45),
          child: Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
