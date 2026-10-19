import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../models/task.dart';
import '../../models/task_occurrence.dart';
import '../../providers/task_provider.dart';
import '../../providers/occurrence_provider.dart';
import '../../providers/tag_provider.dart';
import '../../providers/filter_provider.dart';
import '../../providers/section_provider.dart';
import '../../providers/habit_provider.dart';
import '../../providers/recycle_bin_provider.dart';
import '../../repositories/task_repository.dart';
import '../../services/notification_service.dart';
import '../screens/task_editor_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/statistics_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/focus_screen.dart';
import '../widgets/task_card.dart';
import '../widgets/animated_entry.dart';
import '../../core/utils/app_banner.dart';
import '../../core/utils/manual_order.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  bool _showSearch = false;
  bool _showFilters = false;

  /// Tasks fading out before the actual soft delete is applied.
  final Set<int> _removingTaskIds = <int>{};

  /// Optimistic sort orders applied immediately on drop, before the DB write
  /// and reload finish. Keeps the ReorderableListView from snapping back.
  final Map<int, int> _optimisticSortOrders = <int, int>{};
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

  List<TaskOccurrence> _applyCommonFilters(List<TaskOccurrence> occurrences) {
    final tagFilter = ref.watch(tagFilterProvider);
    final searchQuery = _searchController.text.toLowerCase().trim();

    var filtered = occurrences.where((o) => !o.isSkipped).toList();

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

  List<TaskOccurrence> _filterOccurrences(List<TaskOccurrence> occurrences) {
    final smartFilter = ref.watch(smartFilterProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    var filtered = _applyCommonFilters(occurrences);

    switch (smartFilter) {
      case 'today':
        filtered = filtered.where((o) => o.day == today).toList();
        break;
      case 'tomorrow':
        filtered = filtered.where((o) => o.day == tomorrow).toList();
        break;
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
        filtered = _dedupeByTask(filtered, today);
        break;
    }

    return filtered;
  }

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
    Task? base = task;
    if (task?.id != null) {
      try {
        base = await ref
                .read(taskRepositoryProvider)
                .getTaskById(task!.id!) ??
            task;
      } catch (_) {
        // Fall back to the passed task if the lookup fails.
      }
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskEditorScreen(task: base)),
    );
    if (!mounted) return;
    await ref.read(occurrenceListProvider.notifier).load();
  }

  void _enterSelectionMode(int taskId) {
    ref.read(selectionProvider.notifier).toggle(taskId);
  }

  Future<void> _deleteTaskWithUndo(Task task) async {
    final id = task.id!;
    if (!_removingTaskIds.contains(id)) {
      setState(() => _removingTaskIds.add(id));
      await Future.delayed(const Duration(milliseconds: 160));
    }
    HapticFeedback.mediumImpact();
    final deletedAt = DateTime.now().millisecondsSinceEpoch;
    await ref.read(taskListProvider.notifier).softDeleteTask(task.id!);
    await NotificationService.instance.cancelTaskReminders(task.id!);
    ref.read(recycleBinProvider.notifier).addDeleted(
      task.copyWith(deletedAt: deletedAt),
    );
    await ref.read(occurrenceListProvider.notifier).load();
    if (!mounted) return;
    setState(() => _removingTaskIds.remove(id));
    context.showTopBanner('任务已删除', actionLabel: '撤销', onAction: () async {
      await ref.read(taskListProvider.notifier).restoreTask(task.id!);
      await ref.read(recycleBinProvider.notifier).restore(task);
      await ref.read(occurrenceListProvider.notifier).load();
      await _rescheduleNotifications();
    });
  }

  Future<void> _rescheduleNotifications() async {
    final repo = ref.read(taskRepositoryProvider);
    final tasks = await repo.getAllTasks();
    final rules = await repo.getRecurrenceRuleMap();
    final reminders = await repo.getEnabledRemindersByTask();
    await NotificationService.instance.rescheduleAll(tasks, rules, reminders);
  }

  Future<void> _completeOccurrenceWithUndo(TaskOccurrence occ) async {
    HapticFeedback.lightImpact();
    final wasDone = occ.isDone;
    await ref.read(occurrenceListProvider.notifier).setDone(occ, !wasDone);
    if (occ.task.isHabit) {
      ref.invalidate(habitProvider);
    }
    // A completed one-off task should not keep its reminder.
    if (!occ.isRecurring) {
      if (!wasDone) {
        await NotificationService.instance.cancelTaskReminders(occ.task.id!);
      } else {
        await _rescheduleNotifications();
      }
    }
    if (!mounted) return;
    context.showTopBanner(
      wasDone ? '已取消完成' : '已完成',
      actionLabel: '撤销',
      onAction: () async {
        await ref.read(occurrenceListProvider.notifier).setDone(occ, wasDone);
        if (occ.task.isHabit) {
          ref.invalidate(habitProvider);
        }
        if (!occ.isRecurring) {
          await _rescheduleNotifications();
        }
      },
    );
  }

  void _showSortDisabledPrompt() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text('排序功能仅支持筛选后的标签列表'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Future<void> _onReorder(
    int oldIndex,
    int newIndex,
    List<TaskOccurrence> filtered,
  ) async {
    if (oldIndex < 0 || oldIndex >= filtered.length) return;
    if (newIndex < 0 || newIndex >= filtered.length) return;
    if (newIndex == oldIndex) return;

    // Rebuild the visible order, then renumber the whole filtered list with
    // spaced values. Renumbering avoids integer midpoint collisions when the
    // old sortOrder values are adjacent (0, 1, 2 ...).
    final reordered = [...filtered];
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);

    // Apply the new order immediately so the drop animation lands on the
    // final layout instead of snapping back while the DB write runs.
    setState(() {
      for (var i = 0; i < reordered.length; i++) {
        _optimisticSortOrders[reordered[i].task.id!] = i * 100;
      }
    });

    final repo = ref.read(taskRepositoryProvider);
    for (var i = 0; i < reordered.length; i++) {
      await repo.updateTaskSortOrder(reordered[i].task.id!, i * 100);
    }
    await ref.read(occurrenceListProvider.notifier).load();
    if (mounted) {
      setState(() => _optimisticSortOrders.clear());
    }
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
            : const Text(
                'YuiTodo',
                style: TextStyle(fontFamily: 'SmileySans'),
              ),
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
              icon: const Icon(Icons.search),
              onPressed: () => setState(() => _showSearch = !_showSearch),
            ),
            IconButton(
              icon: AnimatedIcon(
                icon: AnimatedIcons.menu_close,
                progress: _filterAnimation,
                color: _showFilters ? theme.colorScheme.primary : null,
              ),
              onPressed: _toggleFilters,
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: '更多',
              onSelected: (value) {
                switch (value) {
                  case 'calendar':
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CalendarScreen()),
                    );
                    break;
                  case 'focus':
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FocusScreen()),
                    );
                    break;
                  case 'stats':
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StatisticsScreen()),
                    );
                    break;
                  case 'settings':
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                    break;
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'calendar',
                  child: Row(children: [
                    Icon(Icons.calendar_month),
                    SizedBox(width: 12),
                    Text('日历'),
                  ]),
                ),
                PopupMenuItem(
                  value: 'focus',
                  child: Row(children: [
                    Icon(Icons.timer_outlined),
                    SizedBox(width: 12),
                    Text('专注'),
                  ]),
                ),
                PopupMenuItem(
                  value: 'stats',
                  child: Row(children: [
                    Icon(Icons.bar_chart),
                    SizedBox(width: 12),
                    Text('统计'),
                  ]),
                ),
                PopupMenuItem(
                  value: 'settings',
                  child: Row(children: [
                    Icon(Icons.settings),
                    SizedBox(width: 12),
                    Text('设置'),
                  ]),
                ),
              ],
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
                data: (occurrences) => _buildList(
                  context,
                  theme,
                  occurrences,
                  selection,
                  isSelectionMode,
                  smartFilter,
                ),
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

  Future<void> _toggleStep(
    Task task,
    TaskStep step,
    TaskOccurrence occ,
  ) async {
    if (step.id == null) return;
    final newStatus = step.status == 'completed' ? 'pending' : 'completed';
    if (occ.isRecurring) {
      // Subtasks are per-occurrence for recurring tasks.
      await ref.read(taskRepositoryProvider).setStepOccurrenceStatus(
            step.id!,
            occ.task.id!,
            occ.day,
            newStatus,
          );
      await ref.read(occurrenceListProvider.notifier).load();
    } else {
      await ref.read(taskRepositoryProvider).updateStepStatus(step.id!, newStatus);
      await ref.read(taskListProvider.notifier).loadTasks();
      await ref.read(occurrenceListProvider.notifier).load();
    }
  }

  Widget _buildList(
    BuildContext context,
    ThemeData theme,
    List<TaskOccurrence> occurrences,
    List<int> selection,
    bool isSelectionMode,
    String smartFilter,
  ) {
    final tagFilter = ref.watch(tagFilterProvider);
    if (smartFilter == 'all' && tagFilter == null) {
      return _buildSectionedList(
        context,
        theme,
        occurrences,
        selection,
        isSelectionMode,
      );
    }

    final filtered = sortForManualOrder(
      _filterOccurrences(occurrences),
      sortOrderOverrides: _optimisticSortOrders,
    );
    if (filtered.isEmpty) return _emptyState(theme);

    return ReorderableListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: filtered.length,
      onReorderItem: (oldIndex, newIndex) =>
          _onReorder(oldIndex, newIndex, filtered),
      itemBuilder: (context, index) {
        final occ = filtered[index];
        // No entry animation in the reorderable list: it replays after a
        // drop and causes a visible flicker. The list's own drop animation
        // is enough.
        return KeyedSubtree(
          key: ValueKey('f-${occ.task.id}-${occ.dayKey}'),
          child: _buildSlidableItem(
            context,
            theme,
            occ,
            index,
            selection,
            isSelectionMode,
            sortEnabled: true,
          ),
        );
      },
    );
  }

  Widget _buildSectionedList(
    BuildContext context,
    ThemeData theme,
    List<TaskOccurrence> occurrences,
    List<int> selection,
    bool isSelectionMode,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final order = ref.watch(sectionOrderProvider);
    final collapsedMap = ref.watch(sectionCollapseProvider);
    final base = _applyCommonFilters(occurrences);

    final children = <Widget>[];
    for (final section in order) {
      final items =
          sortForManualOrder(_itemsForSection(section, base, today));
      final collapsed = collapsedMap[section] ?? false;
      children.add(_sectionHeader(theme, section, items.length, collapsed));

      final itemWidgets = <Widget>[];
      for (var i = 0; i < items.length; i++) {
        final occ = items[i];
        itemWidgets.add(
          AnimatedEntry(
            key: ValueKey('occ-${occ.task.id}-${occ.dayKey}'),
            index: i,
            child: _buildSlidableItem(
              context,
              theme,
              occ,
              i,
              selection,
              isSelectionMode,
              sortEnabled: false,
            ),
          ),
        );
      }

      // Animate the section body height so collapse/expand feels physical.
      children.add(
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOutCubic,
          alignment: Alignment.topCenter,
          child: collapsed
              ? const SizedBox(width: double.infinity)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: itemWidgets,
                ),
        ),
      );
    }

    if (children.isEmpty) return _emptyState(theme);
    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: children,
    );
  }

  List<TaskOccurrence> _itemsForSection(
    HomeSection section,
    List<TaskOccurrence> occurrences,
    DateTime today,
  ) {
    switch (section) {
      case HomeSection.previous:
        final list = occurrences
            .where((o) => o.isPending && o.day.isBefore(today))
            .toList();
        return _dedupeByTask(list, today, preferLatest: true);
      case HomeSection.today:
        return occurrences
            .where((o) => o.isPending && o.day == today)
            .toList();
      case HomeSection.future:
        final list = occurrences
            .where((o) => o.isPending && o.day.isAfter(today))
            .toList();
        return _dedupeByTask(list, today);
      case HomeSection.completedToday:
        final list = occurrences
            .where((o) => o.isDone && o.day == today)
            .toList();
        return _dedupeByTask(list, today, preferLatest: true);
    }
  }

  Widget _sectionHeader(
    ThemeData theme,
    HomeSection section,
    int count,
    bool collapsed,
  ) {
    return InkWell(
      onTap: () => ref.read(sectionCollapseProvider.notifier).toggle(section),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
        child: Row(
          children: [
            AnimatedRotation(
              turns: collapsed ? 0.0 : 0.5,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.expand_more,
                size: 18,
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              section.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 6),
            if (count > 0)
              Text(
                '($count)',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.outline,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(ThemeData theme) {
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
                  style: TextStyle(
                    fontFamily: 'SmileySans',
                    fontSize: 18,
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlidableItem(
    BuildContext context,
    ThemeData theme,
    TaskOccurrence occ,
    int index,
    List<int> selection,
    bool isSelectionMode, {
    bool sortEnabled = true,
  }) {
    final task = occ.task;
    return Slidable(
      key: ValueKey('occ-${task.id}-${occ.dayKey}'),
      groupTag: 'tasks',
      dragStartBehavior: DragStartBehavior.down,
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.5,
        children: [
          _slidableAction(
            context,
            icon: occ.isDone ? Icons.undo : Icons.check,
            label: occ.isDone ? '取消完成' : '完成',
            color: theme.colorScheme.primary,
            onTap: () => _completeOccurrenceWithUndo(occ),
          ),
          _slidableAction(
            context,
            icon: task.isStarred ? Icons.star : Icons.star_border,
            label: '星标',
            color: theme.colorScheme.tertiary,
            onTap: () => _toggleStarOccurrence(occ),
            fadeToSurfaceRight: true,
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: occ.isRecurring ? 0.95 : 0.8,
        children: [
          _slidableAction(
            context,
            icon: task.isStarred ? Icons.star : Icons.star_border,
            label: '星标',
            color: theme.colorScheme.tertiary,
            onTap: () => _toggleStarOccurrence(occ),
            fadeFromSurfaceLeft: true,
          ),
          if (occ.isRecurring)
            _slidableAction(
              context,
              icon: Icons.skip_next,
              label: '跳过',
              // A tinted neutral: still reads as "skip", but follows the
              // theme instead of being a fixed dark grey.
              color: Color.lerp(
                theme.colorScheme.primary,
                theme.colorScheme.outline,
                0.55,
              )!,
              onTap: () => _skipOccurrence(occ),
            ),
          _slidableAction(
            context,
            icon: Icons.hourglass_bottom,
            label: '专注',
            color: theme.colorScheme.secondary,
            onTap: () => _openFocus(task),
          ),
          _slidableAction(
            context,
            icon: Icons.calendar_today,
            label: '改期',
            color: theme.colorScheme.primary,
            onTap: () => _quickReschedule(occ),
          ),
          _slidableAction(
            context,
            icon: Icons.delete,
            label: '删除',
            color: theme.colorScheme.error,
            onTap: () => _deleteTaskWithUndo(task),
          ),
        ],
      ),
      child: AnimatedOpacity(
        opacity: _removingTaskIds.contains(task.id) ? 0 : 1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: AnimatedScale(
          scale: _removingTaskIds.contains(task.id) ? 0.96 : 1,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          child: TaskCard(
            task: task,
            isSelected: selection.contains(task.id),
            index: index,
            isDone: occ.isDone,
            occurrenceDay: occ.day,
            onToggleComplete: () => _completeOccurrenceWithUndo(occ),
            onTap: () {
              if (isSelectionMode) {
                ref.read(selectionProvider.notifier).toggle(task.id!);
              } else {
                _openTaskEditor(task);
              }
            },
            onLongPress: () => _enterSelectionMode(task.id!),
            onStepToggle: (t, s) => _toggleStep(t, s, occ),
            sortEnabled: sortEnabled,
            onSortDisabled: _showSortDisabledPrompt,
          ),
        ),
      ),
    );
  }

  Widget _slidableAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool fadeFromSurfaceLeft = false,
    bool fadeToSurfaceRight = false,
  }) {
    final theme = Theme.of(context);
    // Junction actions fade from/to the card surface; the rest use a
    // same-hue gradient so the buttons feel softer without losing the
    // smooth transition at the card edge.
    final colors = fadeFromSurfaceLeft
        ? [theme.colorScheme.surface, color]
        : fadeToSurfaceRight
            ? [color, theme.colorScheme.surface]
            : [
                Color.lerp(color, Colors.black, 0.14)!,
                Color.lerp(color, Colors.white, 0.10)!,
              ];
    return CustomSlidableAction(
      onPressed: (_) => onTap(),
      padding: EdgeInsets.zero,
      child: SizedBox.expand(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: colors,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFocus(Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FocusScreen(task: task)),
    );
  }

  Future<void> _toggleStarOccurrence(TaskOccurrence occ) async {
    HapticFeedback.selectionClick();
    final task = occ.task;
    final next = !task.isStarred;
    await ref
        .read(taskListProvider.notifier)
        .updateTask(task.copyWith(isStarred: next));
    await ref.read(occurrenceListProvider.notifier).load();
    if (!mounted) return;
    context.showTopBanner(
      next ? '已加星标' : '已取消星标',
      actionLabel: '撤销',
      onAction: () async {
        await ref
            .read(taskListProvider.notifier)
            .updateTask(task.copyWith(isStarred: !next));
        await ref.read(occurrenceListProvider.notifier).load();
      },
    );
  }

  Future<void> _skipOccurrence(TaskOccurrence occ) async {
    HapticFeedback.lightImpact();
    await ref.read(occurrenceListProvider.notifier).skip(occ);
    if (!mounted) return;
    context.showTopBanner('已跳过本次', actionLabel: '撤销', onAction: () async {
      await ref.read(occurrenceListProvider.notifier).clear(occ);
    });
  }

  Future<void> _quickReschedule(TaskOccurrence occ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: occ.day,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;

    final task = occ.task;
    final oldStart = DateTime.fromMillisecondsSinceEpoch(
      task.startDate ?? task.startTime ?? task.createdAt,
    );
    final newStart = DateTime(
      picked.year,
      picked.month,
      picked.day,
      oldStart.hour,
      oldStart.minute,
    );
    final delta = newStart.difference(oldStart);
    final newEnd = task.endTime != null
        ? DateTime.fromMillisecondsSinceEpoch(task.endTime!).add(delta)
        : null;

    await ref.read(taskListProvider.notifier).updateTask(
          task.copyWith(
            startDate: newStart.millisecondsSinceEpoch,
            startTime: newStart.millisecondsSinceEpoch,
            endTime: newEnd?.millisecondsSinceEpoch,
          ),
        );
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
