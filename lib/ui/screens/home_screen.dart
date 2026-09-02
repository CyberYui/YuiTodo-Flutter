import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../providers/tag_provider.dart';
import '../ui/screens/task_editor_screen.dart';
import '../ui/screens/settings_screen.dart';
import '../ui/widgets/task_card.dart';
import '../core/utils/undo_manager.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _searchQuery = '';
  String _smartFilter = 'all';
  bool _showSearch = false;
  int? _filterTagId;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Task> _filterTasks(List<Task> tasks) {
    var filtered = tasks;
    
    // Smart filter
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayEnd = today.add(const Duration(days: 1));
    final tomorrowEnd = today.add(const Duration(days: 2));

    switch (_smartFilter) {
      case 'today':
        filtered = filtered.where((t) {
          final date = DateTime.fromMillisecondsSinceEpoch(t.startDate ?? t.startTime ?? 0);
          return date.isAfter(today) && date.isBefore(todayEnd);
        }).toList();
        break;
      case 'tomorrow':
        filtered = filtered.where((t) {
          final date = DateTime.fromMillisecondsSinceEpoch(t.startDate ?? t.startTime ?? 0);
          return date.isAfter(todayEnd) && date.isBefore(tomorrowEnd);
        }).toList();
        break;
      case 'future':
        filtered = filtered.where((t) {
          final date = DateTime.fromMillisecondsSinceEpoch(t.startDate ?? t.startTime ?? 0);
          return date.isAfter(tomorrowEnd);
        }).toList();
        break;
      case 'completed':
        filtered = filtered.where((t) => t.status == 'done').toList();
        break;
    }

    // Tag filter
    if (_filterTagId != null) {
      filtered = filtered.where((t) => t.tags.any((tag) => tag.id == _filterTagId)).toList();
    }

    // Search
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((t) {
        return t.title.toLowerCase().contains(query) || 
               t.note.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  void _openTaskEditor(Task? task) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskEditorScreen(task: task)),
    );
  }

  void _enterSelectionMode(int taskId) {
    ref.read(selectionProvider.notifier).toggle(taskId);
  }

  void _deleteTaskWithUndo(Task task) {
    ref.read(taskListProvider.notifier).deleteTask(task.id!);
    context.showUndoSnackBar('任务已删除', () {
      ref.read(taskListProvider.notifier).restoreTask(task.id!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tasksAsync = ref.watch(taskListProvider);
    final tagsAsync = ref.watch(tagListProvider);
    final selection = ref.watch(selectionProvider);
    final isSelectionMode = selection.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '搜索任务...',
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              )
            : const Text('YuiTodo'),
        actions: [
          if (isSelectionMode) ...[
            Text('已选 ${selection.length}'),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                ref.read(taskListProvider.notifier).batchDelete(selection);
                ref.read(selectionProvider.notifier).clear();
              },
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => setState(() => _showSearch = !_showSearch),
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Smart filter bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _filterChip('all', '全部'),
                const SizedBox(width: 8),
                _filterChip('today', '今天'),
                const SizedBox(width: 8),
                _filterChip('tomorrow', '明天'),
                const SizedBox(width: 8),
                _filterChip('future', '未来'),
                const SizedBox(width: 8),
                _filterChip('completed', '已完成'),
              ],
            ),
          ),
          // Tag filter bar
          if (tagsAsync.hasValue && tagsAsync.value!.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('全部标签'),
                    selected: _filterTagId == null,
                    onSelected: (_) => setState(() => _filterTagId = null),
                  ),
                  const SizedBox(width: 8),
                  ...tagsAsync.value!.map((tag) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(tag.name),
                        selected: _filterTagId == tag.id,
                        onSelected: (_) => setState(() => _filterTagId = tag.id),
                      ),
                    );
                  }),
                ],
              ),
            ),
          // Task list
          Expanded(
            child: tasksAsync.when(
              data: (tasks) {
                final filtered = _filterTasks(tasks);
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.task_alt, size: 64, color: theme.colorScheme.outline),
                        const SizedBox(height: 16),
                        Text('暂无任务', style: TextStyle(color: theme.colorScheme.outline)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final task = filtered[index];
                    return Dismissible(
                      key: Key('task-${task.id}'),
                      background: Container(
                        color: theme.colorScheme.primary,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 16),
                        child: const Icon(Icons.check, color: Colors.white),
                      ),
                      secondaryBackground: Container(
                        color: theme.colorScheme.error,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          // Swipe right: complete
                          ref.read(taskListProvider.notifier).toggleComplete(task);
                          return false;
                        } else {
                          // Swipe left: delete with undo
                          _deleteTaskWithUndo(task);
                          return false;
                        }
                      },
                      child: TaskCard(
                        task: task,
                        isSelected: selection.contains(task.id),
                        onTap: () {
                          if (isSelectionMode) {
                            ref.read(selectionProvider.notifier).toggle(task.id!);
                          } else {
                            _openTaskEditor(task);
                          }
                        },
                        onLongPress: () => _enterSelectionMode(task.id!),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('加载失败: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openTaskEditor(null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _filterChip(String id, String label) {
    final isSelected = _smartFilter == id;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _smartFilter = id),
    );
  }
}
