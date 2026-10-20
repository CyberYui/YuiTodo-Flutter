import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/task.dart';
import '../../providers/occurrence_provider.dart';
import '../../providers/recycle_bin_provider.dart';
import '../../providers/task_provider.dart';
import '../../core/utils/app_banner.dart';

class RecycleBinScreen extends ConsumerStatefulWidget {
  const RecycleBinScreen({super.key});

  @override
  ConsumerState<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends ConsumerState<RecycleBinScreen> {
  bool _selectionMode = false;
  final Set<int> _selectedIds = <int>{};

  @override
  void initState() {
    super.initState();
    // The provider is long-lived, so refresh from disk whenever the screen is
    // opened. This keeps the bin in sync after batch deletes elsewhere.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(recycleBinProvider.notifier).loadDeletedTasks();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deletedTasksAsync = ref.watch(recycleBinProvider);

    return deletedTasksAsync.when(
      data: (tasks) {
        // Drop selections that no longer exist (e.g. after a restore).
        _selectedIds.removeWhere((id) => tasks.every((t) => t.id != id));
        if (tasks.isEmpty && _selectionMode) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectionMode = false;
                _selectedIds.clear();
              });
            }
          });
        }

        return Scaffold(
          appBar: _buildAppBar(tasks),
          body: tasks.isEmpty
              ? _buildEmptyState(theme)
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(recycleBinProvider.notifier).loadDeletedTasks(),
                  child: _buildTaskList(context, tasks),
                ),
          bottomNavigationBar: _selectionMode
              ? _buildSelectionBar(tasks)
              : null,
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('回收站')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('回收站')),
        body: Center(child: Text('加载回收站失败: $e')),
      ),
    );
  }

  AppBar _buildAppBar(List<Task> tasks) {
    if (_selectionMode) {
      final allSelected =
          tasks.isNotEmpty && _selectedIds.length == tasks.length;
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: '退出多选',
          onPressed: _exitSelectionMode,
        ),
        title: Text('已选 ${_selectedIds.length} 项'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                if (allSelected) {
                  _selectedIds.clear();
                } else {
                  _selectedIds
                    ..clear()
                    ..addAll(tasks.map((t) => t.id!));
                }
              });
            },
            child: Text(allSelected ? '取消全选' : '全选'),
          ),
        ],
      );
    }

    return AppBar(
      title: const Text('回收站'),
      actions: [
        if (tasks.isNotEmpty)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: '更多操作',
            onSelected: (value) {
              switch (value) {
                case 'select':
                  setState(() {
                    _selectionMode = true;
                    _selectedIds.clear();
                  });
                  break;
                case 'restore_all':
                  _restoreAll(tasks);
                  break;
                case 'clear':
                  _showClearDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              _menuItem(
                value: 'select',
                icon: Icons.checklist,
                title: '批量选择',
                subtitle: '选中后批量恢复或永久删除',
              ),
              _menuItem(
                value: 'restore_all',
                icon: Icons.restore,
                title: '全部恢复',
                subtitle: '把回收站里的任务全部放回列表',
              ),
              _menuItem(
                value: 'clear',
                icon: Icons.delete_forever,
                title: '清空回收站',
                subtitle: '永久删除全部任务',
                destructive: true,
              ),
            ],
          ),
      ],
    );
  }

  PopupMenuItem<String> _menuItem({
    required String value,
    required IconData icon,
    required String title,
    required String subtitle,
    bool destructive = false,
  }) {
    final theme = Theme.of(context);
    final color = destructive ? theme.colorScheme.error : null;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color)),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionBar(List<Task> tasks) {
    final hasSelection = _selectedIds.isNotEmpty;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: hasSelection ? () => _restoreSelected(tasks) : null,
                icon: const Icon(Icons.restore),
                label: Text('恢复（${_selectedIds.length}）'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                onPressed:
                    hasSelection ? () => _confirmDeleteSelected(tasks) : null,
                icon: const Icon(Icons.delete_forever),
                label: Text('删除（${_selectedIds.length}）'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.recycling, size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            '回收站为空',
            style: TextStyle(fontSize: 16, color: theme.colorScheme.outline),
          ),
          const SizedBox(height: 8),
          Text(
            '删除的任务会出现在这里',
            style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(BuildContext context, List<Task> tasks) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        final deletedTime = DateTime.fromMillisecondsSinceEpoch(
          task.deletedAt ?? 0,
        );
        final selected = _selectedIds.contains(task.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: selected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.10)
              : null,
          child: ListTile(
            onTap: _selectionMode ? () => _toggleSelected(task.id!) : null,
            onLongPress: _selectionMode
                ? null
                : () {
                    setState(() {
                      _selectionMode = true;
                      _selectedIds.add(task.id!);
                    });
                  },
            leading: _selectionMode
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: selected,
                        onChanged: (_) => _toggleSelected(task.id!),
                      ),
                      _buildTaskIcon(context, task),
                    ],
                  )
                : _buildTaskIcon(context, task),
            title: Text(
              task.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '删除于 ${deletedTime.month}/${deletedTime.day} ${deletedTime.hour}:${deletedTime.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            trailing: _selectionMode
                ? null
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.restore),
                        tooltip: '恢复',
                        onPressed: () => _restoreTask(task),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_forever,
                          color: Colors.red,
                        ),
                        tooltip: '永久删除',
                        onPressed: () => _permanentDelete(task.id!),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildTaskIcon(BuildContext context, Task task) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Color(int.parse(task.color.replaceFirst('#', '0xFF'))),
        borderRadius: BorderRadius.circular(8),
      ),
      child: task.icon != null
          ? Image.asset('assets/icons/${task.icon}.png', width: 32, height: 32)
          : const Icon(Icons.task_alt, color: Colors.white, size: 24),
    );
  }

  void _toggleSelected(int taskId) {
    setState(() {
      if (!_selectedIds.add(taskId)) {
        _selectedIds.remove(taskId);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  Future<void> _restoreTask(Task task) async {
    await ref.read(recycleBinProvider.notifier).restore(task);
    await _reloadTaskViews();
    if (!mounted) return;
    context.showTopBanner('已恢复 "${task.title}"');
  }

  Future<void> _restoreSelected(List<Task> tasks) async {
    final selected =
        tasks.where((t) => _selectedIds.contains(t.id)).toList(growable: false);
    if (selected.isEmpty) return;
    await ref.read(recycleBinProvider.notifier).restoreMany(selected);
    await _reloadTaskViews();
    if (!mounted) return;
    _exitSelectionMode();
    context.showTopBanner('已恢复 ${selected.length} 个任务');
  }

  Future<void> _restoreAll(List<Task> tasks) async {
    if (tasks.isEmpty) return;
    await ref.read(recycleBinProvider.notifier).restoreMany(tasks);
    await _reloadTaskViews();
    if (!mounted) return;
    context.showTopBanner('已恢复全部 ${tasks.length} 个任务');
  }

  Future<void> _reloadTaskViews() async {
    await ref.read(taskListProvider.notifier).loadTasks();
    await ref.read(occurrenceListProvider.notifier).load();
  }

  void _permanentDelete(int taskId) {
    ref.read(recycleBinProvider.notifier).permanentDelete(taskId);
    if (!mounted) return;
    context.showTopBanner('已永久删除');
  }

  void _confirmDeleteSelected(List<Task> tasks) {
    final selected =
        tasks.where((t) => _selectedIds.contains(t.id)).toList(growable: false);
    if (selected.isEmpty) return;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('永久删除'),
        content: Text('确定永久删除选中的 ${selected.length} 个任务吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref
                  .read(recycleBinProvider.notifier)
                  .permanentDeleteMany(selected.map((t) => t.id!).toList());
              if (!mounted) return;
              _exitSelectionMode();
              context.showTopBanner('已永久删除 ${selected.length} 个任务');
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('清空回收站'),
        content: const Text('确定要永久删除所有任务吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref.read(recycleBinProvider.notifier).clearAll();
              if (!mounted) return;
              _exitSelectionMode();
              context.showTopBanner('回收站已清空');
            },
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
