import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';

/// Recycle Bin Provider - tracks deleted tasks
final recycleBinProvider = StateNotifierProvider<RecycleBinNotifier, List<Task>>((ref) {
  return RecycleBinNotifier();
});

class RecycleBinNotifier extends StateNotifier<List<Task>> {
  RecycleBinNotifier() : super([]);

  void addDeleted(Task task) {
    state = [...state, task];
  }

  void restore(Task task) {
    state = state.where((t) => t.id != task.id).toList();
  }

  void permanentDelete(int taskId) {
    state = state.where((t) => t.id != taskId).toList();
  }

  void clearAll() {
    state = [];
  }
}

class RecycleBinScreen extends ConsumerWidget {
  const RecycleBinScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final deletedTasks = ref.watch(recycleBinProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('回收站'),
        actions: [
          if (deletedTasks.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.checklist),
              tooltip: '多选',
              onPressed: () => _enterSelectionMode(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: '清空回收站',
              onPressed: () => _showClearDialog(context, ref),
            ),
          ],
        ],
      ),
      body: deletedTasks.isEmpty
          ? _buildEmptyState(theme)
          : _buildTaskList(context, ref, deletedTasks),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.recycling, size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text('回收站为空', style: TextStyle(fontSize: 16, color: theme.colorScheme.outline)),
          const SizedBox(height: 8),
          Text('删除的任务会出现在这里', style: TextStyle(fontSize: 12, color: theme.colorScheme.outline)),
        ],
      ),
    );
  }

  Widget _buildTaskList(BuildContext context, WidgetRef ref, List<Task> tasks) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        final deletedTime = DateTime.fromMillisecondsSinceEpoch(task.deletedAt ?? 0);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Color(int.parse((task.color ?? '#3B82F6').replaceFirst('#', '0xFF'))),
                borderRadius: BorderRadius.circular(8),
              ),
              child: task.icon != null
                  ? Image.asset('assets/icons/${task.icon}.png', width: 32, height: 32)
                  : const Icon(Icons.task_alt, color: Colors.white, size: 24),
            ),
            title: Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              '删除于 ${deletedTime.month}/${deletedTime.day} ${deletedTime.hour}:${deletedTime.minute.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.restore),
                  tooltip: '恢复',
                  onPressed: () => _restoreTask(context, ref, task),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  tooltip: '永久删除',
                  onPressed: () => _permanentDelete(context, ref, task.id!),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _restoreTask(BuildContext context, WidgetRef ref, Task task) {
    ref.read(taskListProvider.notifier).restoreTask(task.id!);
    ref.read(recycleBinProvider.notifier).restore(task);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已恢复 "${task.title}"')),
    );
  }

  void _permanentDelete(BuildContext context, WidgetRef ref, int taskId) {
    ref.read(recycleBinProvider.notifier).permanentDelete(taskId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已永久删除')),
    );
  }

  void _enterSelectionMode(BuildContext context, WidgetRef ref) {
    // TODO: Implement multi-select mode
  }

  void _showClearDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空回收站'),
        content: const Text('确定要永久删除所有任务吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref.read(recycleBinProvider.notifier).clearAll();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('回收站已清空')),
              );
            },
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
