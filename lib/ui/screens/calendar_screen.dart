import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/date/date_utils.dart';
import '../../core/theme/calendar_background.dart';
import '../../models/task.dart';
import '../../models/task_occurrence.dart';
import '../../providers/calendar_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/occurrence_provider.dart';
import '../../repositories/task_repository.dart';
import '../screens/task_editor_screen.dart';
import '../widgets/animated_entry.dart';

/// Month calendar with per-day task indicators and a day task list.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = DateTime(now.year, now.month, 1);
    _selectedDay = DateTime(now.year, now.month, now.day);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(calendarProvider.notifier).loadMonth(_focusedDay);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final async = ref.watch(calendarProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('日历'),
        actions: [
          IconButton(
            tooltip: '回到今天',
            icon: const Icon(Icons.today),
            onPressed: () {
              final now = DateTime.now();
              setState(() {
                _focusedDay = DateTime(now.year, now.month, 1);
                _selectedDay = DateTime(now.year, now.month, now.day);
              });
              ref.read(calendarProvider.notifier).loadMonth(_focusedDay);
            },
          ),
        ],
      ),
      body: async.when(
        data: (occurrences) {
          final byDay = <int, List<TaskOccurrence>>{};
          for (final o in occurrences) {
            (byDay[ymdKey(o.day)] ??= []).add(o);
          }
          final selected =
              byDay[ymdKey(_selectedDay)] ?? const <TaskOccurrence>[];

          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(child: CalendarBackground.layer()),
              Container(
                decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.primary.withOpacity(0.16),
                  theme.colorScheme.surface,
                ],
                stops: const [0, 0.52],
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
                  child: TableCalendar<TaskOccurrence>(
                    firstDay: DateTime(2000),
                    lastDay: DateTime(2100),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                    eventLoader: (day) => byDay[ymdKey(day)] ?? const [],
                    calendarFormat: CalendarFormat.month,
                    availableCalendarFormats: const {CalendarFormat.month: '月'},
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    locale: 'zh_CN',
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ) ??
                          const TextStyle(fontSize: 16),
                      leftChevronIcon: Icon(
                        Icons.chevron_left,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      weekendStyle: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: true,
                      defaultTextStyle: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                      weekendTextStyle: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                      outsideTextStyle: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurfaceVariant
                            .withOpacity(0.35),
                      ),
                      todayDecoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.16),
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      selectedTextStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onPrimary,
                      ),
                      markersMaxCount: 3,
                      markerSize: 5,
                      markerMargin: const EdgeInsets.symmetric(horizontal: 1),
                    ),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                      ref.read(calendarProvider.notifier).loadMonth(focusedDay);
                    },
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, day, events) {
                        if (events.isEmpty) return null;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: events.take(3).map((o) {
                            final color = Color(
                              int.parse(
                                o.task.color.replaceFirst('#', '0xFF'),
                              ),
                            );
                            return Container(
                              width: 5,
                              height: 5,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final offset = Tween<Offset>(
                        begin: const Offset(0.03, 0),
                        end: Offset.zero,
                      ).animate(animation);
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(position: offset, child: child),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey(ymdKey(_selectedDay)),
                      child: selected.isEmpty
                          ? _buildEmptyDay(theme)
                          : ListView.builder(
                              padding: const EdgeInsets.only(
                                top: 10,
                                bottom: 96,
                              ),
                              itemCount: selected.length,
                              itemBuilder: (context, index) => _buildCompactTask(
                                theme,
                                selected[index],
                                index,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _reload() async {
    await ref
        .read(calendarProvider.notifier)
        .loadMonth(_focusedDay, showLoading: false);
    if (!mounted) return;
    await ref.read(occurrenceListProvider.notifier).load();
  }

  Future<void> _toggleComplete(TaskOccurrence occ) async {
    final engine = ref.read(taskDateQueryEngineProvider);
    if (occ.isDone) {
      await engine.uncomplete(occ.task, occ.day);
    } else {
      await engine.complete(occ.task, occ.day);
    }
    await _reload();
  }

  Future<void> _toggleStep(
    Task task,
    TaskStep step,
    TaskOccurrence occ,
  ) async {
    if (step.id == null) return;
    final newStatus = step.status == 'completed' ? 'pending' : 'completed';
    if (occ.isRecurring) {
      await ref.read(taskRepositoryProvider).setStepOccurrenceStatus(
            step.id!,
            occ.task.id!,
            occ.day,
            newStatus,
          );
    } else {
      await ref
          .read(taskRepositoryProvider)
          .updateStepStatus(step.id!, newStatus);
    }
    await _reload();
  }

  Future<void> _openEditor(Task? task) async {
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
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskEditorScreen(task: base)),
    );
    if (!mounted) return;
    await _reload();
  }

  Widget _buildCompactTask(
    ThemeData theme,
    TaskOccurrence occ,
    int index,
  ) {
    final task = occ.task;
    final color = Color(int.parse(task.color.replaceFirst('#', '0xFF')));
    final done = occ.isDone;
    final subtitle = _subtitleOf(task);

    return AnimatedEntry(
      key: ValueKey('cal-${task.id}-${occ.dayKey}'),
      index: index,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Material(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _openEditor(task),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _toggleComplete(occ),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        done
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 20,
                        color: done ? color : theme.colorScheme.outline,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          task.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            decoration:
                                done ? TextDecoration.lineThrough : null,
                            color: done
                                ? theme.colorScheme.outline
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (task.isStarred) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                  ],
                  if (occ.isRecurring) ...[
                    const SizedBox(width: 6),
                    Icon(
                      Icons.repeat,
                      size: 14,
                      color: theme.colorScheme.outline,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _subtitleOf(Task task) {
    if (task.steps.isNotEmpty) {
      final done = task.steps.where((s) => s.status == 'completed').length;
      return '子任务 $done/${task.steps.length}';
    }
    if (task.tags.isNotEmpty) return task.tags.first.name;
    return task.note;
  }

  Widget _buildEmptyDay(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_available,
            size: 40,
            color: theme.colorScheme.outline.withOpacity(0.6),
          ),
          const SizedBox(height: 8),
          Text(
            '当天没有任务',
            style: TextStyle(color: theme.colorScheme.outline),
          ),
        ],
      ),
    );
  }
}
