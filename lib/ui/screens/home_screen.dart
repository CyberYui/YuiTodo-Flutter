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
import '../../providers/recycle_bin_provider.dart';
import '../../repositories/task_repository.dart';
import '../screens/task_editor_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/statistics_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/focus_screen.dart';
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
    HapticFeedback.mediumImpact();
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
    HapticFeedback.lightImpact();
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
              icon: const Icon(Icons.timer_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FocusScreen()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.calendar_month),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CalendarScreen()),
              ),
            ),
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
    if (smartFilter == 'all') {
      return _buildSectionedList(
        context,
        theme,
        occurrences,
        selection,
        isSelectionMode,
      );
    }

    final filtered = _filterOccurrences(occurrences);
    if (filtered.isEmpty) return _emptyState(theme);

    return ReorderableListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: filtered.length,
      onReorder: (oldIndex, newIndex) =>
          _onReorder(oldIndex, newIndex, filtered),
      itemBuilder: (context, index) => _buildSlidableItem(
        context,
        theme,
        filtered[index],
        index,
        selection,
        isSelectionMode,
      ),
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
      final items = _itemsForSection(section, base, today);
      final collapsed = collapsedMap[section] ?? false;
      children.add(_sectionHeader(theme, section, items.length, collapsed));
      if (!collapsed) {
        for (var i = 0; i < items.length; i++) {
          children.add(_buildSlidableItem(
            context,
            theme,
            items[i],
            i,
            selection,
            isSelectionMode,
          ));
        }
      }
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
                  style: TextStyle(color: theme.colorScheme.outline),
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
    bool isSelectionMode,
  ) {
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
            color: const Color(0xFF22C55E),
            onTap: () => _completeOccurrenceWithUndo(occ),
          ),
          _slidableAction(
            context,
            icon: task.isStarred ? Icons.star : Icons.star_border,
            label: '星标',
            color: const Color(0xFFF59E0B),
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
            color: const Color(0xFFF59E0B),
            onTap: () => _toggleStarOccurrence(occ),
            fadeFromSurfaceLeft: true,
          ),
          if (occ.isRecurring)
            _slidableAction(
              context,
              icon: Icons.skip_next,
              label: '跳过',
              color: const Color(0xFF64748B),
              onTap: () => _skipOccurrence(occ),
            ),
          _slidableAction(
            context,
            icon: Icons.hourglass_bottom,
            label: '专注',
            color: const Color(0xFF0EA5E9),
            onTap: () => _openFocus(task),
          ),
          _slidableAction(
            context,
            icon: Icons.calendar_today,
            label: '改期',
            color: const Color(0xFF4F46E5),
            onTap: () => _quickReschedule(occ),
          ),
          _slidableAction(
            context,
            icon: Icons.delete,
            label: '删除',
            color: const Color(0xFFEF4444),
            onTap: () => _deleteTaskWithUndo(task),
          ),
        ],
      ),
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
