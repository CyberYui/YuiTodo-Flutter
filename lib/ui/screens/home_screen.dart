import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../providers/tag_provider.dart';
import '../../providers/filter_provider.dart';
import '../../providers/recycle_bin_provider.dart';
import '../../repositories/task_repository.dart';
import '../screens/task_editor_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/statistics_screen.dart';
import '../widgets/task_card.dart';
import '../../core/utils/undo_manager.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  bool _showSearch = false;
  bool _showFilters = false;
  final _searchController = TextEditingController();
  late AnimationController _filterAnimController;
  late Animation<double> _filterAnimation;

  @override
  void initState() {
    super.initState();
    _filterAnimController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _filterAnimation = CurvedAnimation(
      parent: _filterAnimController,
      curve: Curves.easeInOut,
    );
    if (_showFilters) _filterAnimController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _filterAnimController.dispose();
    super.dispose();
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
      if (_showFilters) {
        _filterAnimController.forward();
      } else {
        _filterAnimController.reverse();
      }
    });
  }

  List<Task> _filterTasks(List<Task> tasks) {
    final smartFilter = ref.watch(smartFilterProvider);
    final tagFilter = ref.watch(tagFilterProvider);
    final searchQuery = _searchController.text.toLowerCase().trim();
    
    var filtered = tasks.where((t) => t.deletedAt == null).toList();
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayEnd = today.add(const Duration(days: 1));
    final tomorrowEnd = today.add(const Duration(days: 2));

    switch (smartFilter) {
      case 'today':
        filtered = filtered.where((t) {
          final date = DateTime.fromMillisecondsSinceEpoch(t.startDate ?? t.startTime ?? 0);
          return date.isAfter(today.subtract(const Duration(days: 1))) && date.isBefore(todayEnd);
        }).toList();
        break;
      case 'tomorrow':
        filtered = filtered.where((t) {
          final date = DateTime.fromMillisecondsSinceEpoch(t.startDate ?? t.startTime ?? 0);
          return date.isAfter(todayEnd.subtract(const Duration(days: 1))) && date.isBefore(tomorrowEnd);
        }).toList();
        break;
      case 'future':
        filtered = filtered.where((t) {
          final date = DateTime.fromMillisecondsSinceEpoch(t.startDate ?? t.startTime ?? 0);
          return date.isAfter(tomorrowEnd.subtract(const Duration(days: 1)));
        }).toList();
        break;
      case 'completed':
        filtered = filtered.where((t) => t.status == 'done').toList();
        break;
    }

    if (tagFilter != null) {
      filtered = filtered.where((t) => t.tags.any((tag) => tag.id == tagFilter)).toList();
    }

    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((t) {
        return t.title.toLowerCase().contains(searchQuery) || 
               t.note.toLowerCase().contains(searchQuery);
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
    ref.read(taskListProvider.notifier).softDeleteTask(task.id!);
    ref.read(recycleBinProvider.notifier).addDeleted(task);
    context.showUndoSnackBar('任务已删除', () {
      ref.read(taskListProvider.notifier).restoreTask(task.id!);
      ref.read(recycleBinProvider.notifier).restore(task);
    });
  }

  void _completeTaskWithUndo(Task task) {
    ref.read(taskListProvider.notifier).toggleComplete(task);
    final wasDone = task.status == 'done';
    context.showUndoSnackBar(wasDone ? '已取消完成' : '已完成', () {
      ref.read(taskListProvider.notifier).toggleComplete(task);
    });
  }

  void _onReorder(int oldIndex, int newIndex, List<Task> filteredTasks) {
    if (oldIndex < newIndex) newIndex -= 1;
    
    final movedTask = filteredTasks[oldIndex];
    final targetTask = filteredTasks[newIndex];
    
    // Calculate new sort order
    int newSortOrder;
    if (newIndex == 0) {
      newSortOrder = filteredTasks.first.sortOrder - 1;
    } else if (newIndex == filteredTasks.length - 1) {
      newSortOrder = filteredTasks.last.sortOrder + 1;
    } else {
      final before = filteredTasks[newIndex - 1];
      final after = filteredTasks[newIndex + (oldIndex < newIndex ? 0 : 1)];
      newSortOrder = ((before.sortOrder + after.sortOrder) / 2).round();
    }
    
    ref.read(taskRepositoryProvider).updateTaskSortOrder(movedTask.id!, newSortOrder);
    ref.read(taskListProvider.notifier).loadTasks();
  }

  void _showBatchOperationsSheet(List<int> selectedIds) {
    showModalBottomSheet(
      context: context,
      builder: (context) => BatchOperationsSheet(selectedIds: selectedIds),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tasksAsync = ref.watch(taskListProvider);
    final tagsAsync = ref.watch(tagListProvider);
    final selection = ref.watch(selectionProvider);
    final isSelectionMode = selection.isNotEmpty;
    final smartFilter = ref.watch(smartFilterProvider);
    final tagFilter = ref.watch(tagFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '搜索任务...',
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              )
            : const Text('YuiTodo'),
        actions: [
          if (isSelectionMode) ...[
            TextButton(
              onPressed: () => _showBatchOperationsSheet(selection),
              child: const Text('操作'),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => ref.read(selectionProvider.notifier).clear(),
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.bar_chart),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StatisticsScreen()),
              ),
            ),
            IconButton(
              icon: AnimatedIcon(
                icon: AnimatedIcons.menu_close,
                progress: _filterAnimation,
                color: _showFilters ? theme.colorScheme.primary : null,
              ),
              onPressed: _toggleFilters,
            ),
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
          // Animated filter section
          SizeTransition(
            sizeFactor: _filterAnimation,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  bottom: BorderSide(color: theme.dividerColor),
                ),
              ),
              child: Column(
                children: [
                  // Smart filter row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        _filterChip('all', '全部', smartFilter),
                        const SizedBox(width: 8),
                        _filterChip('today', '今天', smartFilter),
                        const SizedBox(width: 8),
                        _filterChip('tomorrow', '明天', smartFilter),
                        const SizedBox(width: 8),
                        _filterChip('future', '未来', smartFilter),
                        const SizedBox(width: 8),
                        _filterChip('completed', '已完成', smartFilter),
                      ],
                    ),
                  ),
                  // Tag filter row
                  if (tagsAsync.hasValue && tagsAsync.value!.isNotEmpty)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          FilterChip(
                            label: const Text('全部'),
                            selected: tagFilter == null,
                            visualDensity: VisualDensity.compact,
                            onSelected: (_) => ref.read(tagFilterProvider.notifier).setTag(null),
                          ),
                          const SizedBox(width: 8),
                          ...tagsAsync.value!.map((tag) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(tag.name),
                                selected: tagFilter == tag.id,
                                visualDensity: VisualDensity.compact,
                                onSelected: (_) => ref.read(tagFilterProvider.notifier).setTag(tag.id),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          // Task list with drag-and-drop
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
                return ReorderableListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: filtered.length,
                  onReorder: (oldIndex, newIndex) => _onReorder(oldIndex, newIndex, filtered),
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
                          _completeTaskWithUndo(task);
                        } else {
                          _deleteTaskWithUndo(task);
                        }
                        return false;
                      },
                      child: TaskCard(
                        key: ValueKey(task.id),
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
                        onStepToggle: (task, step) => _toggleStep(task, step),
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
      floatingActionButton: isSelectionMode
          ? null
          : FloatingActionButton(
              onPressed: () => _openTaskEditor(null),
              child: const Icon(Icons.add),
            ),
    );
  }

  void _toggleStep(Task task, TaskStep step) {
    if (step.id == null) return;
    final newStatus = step.status == 'completed' ? 'pending' : 'completed';
    ref.read(taskRepositoryProvider).updateStepStatus(step.id!, newStatus);
    ref.read(taskListProvider.notifier).loadTasks();
  }

  Widget _filterChip(String id, String label, String currentFilter) {
    return FilterChip(
      label: Text(label),
      selected: currentFilter == id,
      visualDensity: VisualDensity.compact,
      onSelected: (_) => ref.read(smartFilterProvider.notifier).setFilter(id),
    );
  }
}

/// Batch operations bottom sheet
class BatchOperationsSheet extends ConsumerWidget {
  final List<int> selectedIds;

  const BatchOperationsSheet({
    super.key,
    required this.selectedIds,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tagsAsync = ref.watch(tagListProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '已选择 ${selectedIds.length} 个任务',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Icon(Icons.delete, color: theme.colorScheme.error),
            title: const Text('批量删除'),
            onTap: () {
              ref.read(taskListProvider.notifier).batchSoftDelete(selectedIds);
              ref.read(selectionProvider.notifier).clear();
              Navigator.pop(context);
            },
          ),
          if (tagsAsync.hasValue)
            ...tagsAsync.value!.map((tag) {
              return ListTile(
                leading: Icon(Icons.label, color: Color(int.parse(tag.color.replaceFirst('#', '0xFF')))),
                title: Text('添加标签: ${tag.name}'),
                onTap: () {
                  ref.read(taskListProvider.notifier).batchAddTag(selectedIds, tag.id!);
                  ref.read(selectionProvider.notifier).clear();
                  Navigator.pop(context);
                },
              );
            }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
