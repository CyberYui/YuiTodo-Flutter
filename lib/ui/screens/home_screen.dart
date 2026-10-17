import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/task.dart';
import '../../models/task_occurrence.dart';
import '../../providers/task_provider.dart';
import '../../providers/occurrence_provider.dart';
import '../../providers/tag_provider.dart';
import '../../providers/filter_provider.dart';
import '../../providers/recycle_bin_provider.dart';
import '../../repositories/task_repository.dart';
import '../screens/task_editor_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/statistics_screen.dart';
import '../widgets/task_card.dart';
import '../../core/utils/app_banner.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
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

  List<TaskOccurrence> _filterOccurrences(List<TaskOccurrence> occurrences) {
    final smartFilter = ref.watch(smartFilterProvider);
    final tagFilter = ref.watch(tagFilterProvider);
    final searchQuery = _searchController.text.toLowerCase().trim();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    var filtered = occurrences.where((o) => !o.isSkipped).toList();

    switch (smartFilter) {
      case 'today':
        filtered = filtered.where((o) => o.day == today).toList();
        break;
      case 'tomorrow':
        filtered = filtered.where((o) => o.day == tomorrow).toList();
        break;
      // "未来" shows the next occurrence per task.
      case 'future':
        filtered = filtered.where((o) => o.day.isAfter(today)).toList();
        filtered = _dedupeByTask(filtered, today);
        break;
      case 'completed':
        filtered = filtered.where((o) => o.isDone).toList();
        filtered = _dedupeByTask(filtered, today, preferLatest: true);
        break;
      case 'all':
      default:
        // One card per task: pending first, then the occurrence closest to today.
        filtered = _dedupeByTask(filtered, today);
        break;
    }

    if (tagFilter != null) {
      filtered = filtered
          .where((o) => o.task.tags.any((tag) => tag.id == tagFilter))
          .toList();
    }

    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((o) {
        final t = o.task;
        if (t.title.toLowerCase().contains(searchQuery)) return true;
        if (t.note.toLowerCase().contains(searchQuery)) return true;
        for (final step in t.steps) {
          if (step.title.toLowerCase().contains(searchQuery)) return true;
        }
        return false;
      }).toList();
    }

    return filtered;
  }

  /// Collapse multiple occurrences of the same task into a single card.
  List<TaskOccurrence> _dedupeByTask(
    List<TaskOccurrence> list,
    DateTime today, {
    bool preferLatest = false,
  }) {
    final map = <int, TaskOccurrence>{};
    for (final o in list) {
      final id = o.task.id;
      if (id == null) continue;
      final existing = map[id];
      map[id] = existing == null
          ? o
          : _preferred(existing, o, today, preferLatest: preferLatest);
    }
    return map.values.toList();
  }

  TaskOccurrence _preferred(
    TaskOccurrence a,
    TaskOccurrence b,
    DateTime today, {
    bool preferLatest = false,
  }) {
    // Pending beats done/skipped.
    if (a.isPending != b.isPending) return a.isPending ? a : b;
    // For the completed view keep the latest completion.
    if (preferLatest) return a.day.isAfter(b.day) ? a : b;
    // Otherwise keep the occurrence closest to today.
    final da = a.day.difference(today).inDays.abs();
    final db = b.day.difference(today).inDays.abs();
    if (da != db) return da < db ? a : b;
    return a.day.isBefore(b.day) ? a : b;
  }

  Future<void> _openTaskEditor(Task? task) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskEditorScreen(task: task)),
    );
    if (!mounted) return;
    await ref.read(occurrenceListProvider.notifier).load();
  }

  void _enterSelectionMode(int taskId) {
    ref.read(selectionProvider.notifier).toggle(taskId);
  }

  Future<void> _deleteTaskWithUndo(Task task) async {
    final deletedAt = DateTime.now().millisecondsSinceEpoch;
    await ref.read(taskListProvider.notifier).softDeleteTask(task.id!);
    ref.read(recycleBinProvider.notifier).addDeleted(
      task.copyWith(deletedAt: deletedAt),
    );
    await ref.read(occurrenceListProvider.notifier).load();
    if (!mounted) return;
    context.showTopBanner('任务已删除', actionLabel: '撤销', onAction: () async {
      await ref.read(taskListProvider.notifier).restoreTask(task.id!);
      await ref.read(recycleBinProvider.notifier).restore(task);
      await ref.read(occurrenceListProvider.notifier).load();
    });
  }

  Future<void> _completeOccurrenceWithUndo(TaskOccurrence occ) async {
    final wasDone = occ.isDone;
    await ref.read(occurrenceListProvider.notifier).setDone(occ, !wasDone);
    if (!mounted) return;
    context.showTopBanner(
      wasDone ? '已取消完成' : '已完成',
      actionLabel: '撤销',
      onAction: () async {
        await ref.read(occurrenceListProvider.notifier).setDone(occ, wasDone);
      },
    );
  }

  void _onReorder(
    int oldIndex,
    int newIndex,
    List<TaskOccurrence> filtered,
  ) {
    if (oldIndex < newIndex) newIndex -= 1;
    if (newIndex < 0 || newIndex >= filtered.length) return;

    final moved = filtered[oldIndex].task;

    int newSortOrder;
    if (newIndex == 0) {
      newSortOrder = filtered.first.task.sortOrder - 1;
    } else if (newIndex == filtered.length - 1) {
      newSortOrder = filtered.last.task.sortOrder + 1;
    } else {
      final before = filtered[newIndex - 1].task;
      final after = filtered[newIndex + (oldIndex < newIndex ? 0 : 1)].task;
      newSortOrder = ((before.sortOrder + after.sortOrder) / 2).round();
    }

    ref.read(taskRepositoryProvider).updateTaskSortOrder(moved.id!, newSortOrder);
    ref.read(occurrenceListProvider.notifier).load();
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
    final occurrencesAsync = ref.watch(occurrenceListProvider);
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
                border: Border(bottom: BorderSide(color: theme.dividerColor)),
              ),
              child: Column(
                children: [
                  // Smart filter row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          FilterChip(
                            label: const Text('全部'),
                            selected: tagFilter == null,
                            visualDensity: VisualDensity.compact,
                            onSelected: (_) => ref
                                .read(tagFilterProvider.notifier)
                                .setTag(null),
                          ),
                          const SizedBox(width: 8),
                          ...tagsAsync.value!.map((tag) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(tag.name),
                                selected: tagFilter == tag.id,
                                visualDensity: VisualDensity.compact,
                                onSelected: (_) => ref
                                    .read(tagFilterProvider.notifier)
                                    .setTag(tag.id),
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
          // Task list with drag-and-drop and pull-to-refresh
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(occurrenceListProvider.notifier).load();
              },
              child: occurrencesAsync.when(
                data: (occurrences) {
                  final filtered = _filterOccurrences(occurrences);
                  if (filtered.isEmpty) {
                    return ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.3,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.task_alt,
                                  size: 64,
                                  color: theme.colorScheme.outline,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '暂无任务',
                                  style: TextStyle(color: theme.colorScheme.outline),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return ReorderableListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: filtered.length,
                    onReorder: (oldIndex, newIndex) =>
                        _onReorder(oldIndex, newIndex, filtered),
                    itemBuilder: (context, index) {
                      final occ = filtered[index];
                      final task = occ.task;
                      return Dismissible(
                        key: Key('occ-${task.id}-${occ.dayKey}'),
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
                            await _completeOccurrenceWithUndo(occ);
                          } else {
                            await _deleteTaskWithUndo(task);
                          }
                          return false;
                        },
                        child: TaskCard(
                          key: ValueKey('${task.id}-${occ.dayKey}'),
                          task: task,
                          isSelected: selection.contains(task.id),
                          index: index,
                          isDone: occ.isDone,
                          occurrenceDay: occ.day,
                          onTap: () {
                            if (isSelectionMode) {
                              ref
                                  .read(selectionProvider.notifier)
                                  .toggle(task.id!);
                            } else {
                              _openTaskEditor(task);
                            }
                          },
                          onLongPress: () => _enterSelectionMode(task.id!),
                          onStepToggle: (Task task, TaskStep step) =>
                              _toggleStep(task, step),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('加载失败: $e')),
              ),
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

  Future<void> _toggleStep(Task task, TaskStep step) async {
    if (step.id == null) return;
    final newStatus = step.status == 'completed' ? 'pending' : 'completed';
    await ref.read(taskRepositoryProvider).updateStepStatus(step.id!, newStatus);
    await ref.read(taskListProvider.notifier).loadTasks();
    await ref.read(occurrenceListProvider.notifier).load();
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

  const BatchOperationsSheet({super.key, required this.selectedIds});

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
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
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
                leading: Icon(
                  Icons.label,
                  color: Color(int.parse(tag.color.replaceFirst('#', '0xFF'))),
                ),
                title: Text('添加标签: ${tag.name}'),
                onTap: () {
                  ref
                      .read(taskListProvider.notifier)
                      .batchAddTag(selectedIds, tag.id!);
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
