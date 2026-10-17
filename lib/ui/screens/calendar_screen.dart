import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/date/date_utils.dart';
import '../../models/task.dart';
import '../../models/task_occurrence.dart';
import '../../providers/calendar_provider.dart';
import '../../providers/occurrence_provider.dart';
import '../../repositories/task_repository.dart';
import '../screens/task_editor_screen.dart';
import '../widgets/task_card.dart';

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

          return Column(
            children: [
              TableCalendar<TaskOccurrence>(
                firstDay: DateTime(2000),
                lastDay: DateTime(2100),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                eventLoader: (day) => byDay[ymdKey(day)] ?? const [],
                calendarFormat: CalendarFormat.month,
                availableCalendarFormats: const {CalendarFormat.month: '月'},
                startingDayOfWeek: StartingDayOfWeek.monday,
                locale: 'zh_CN',
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
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
                          margin: const EdgeInsets.symmetric(horizontal: 1),
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
              const Divider(height: 1),
              Expanded(
                child: selected.isEmpty
                    ? Center(
                        child: Text(
                          '当天没有任务',
                          style: TextStyle(color: theme.colorScheme.outline),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: selected.length,
                        itemBuilder: (context, index) {
                          final occ = selected[index];
                          return TaskCard(
                            task: occ.task,
                            isSelected: false,
                            index: index,
                            isDone: occ.isDone,
                            occurrenceDay: occ.day,
                            onToggleComplete: () => _toggleComplete(occ),
                            onTap: () => _openEditor(occ.task),
                            onLongPress: () {},
                            onStepToggle: (t, s) => _toggleStep(t, s, occ),
                          );
                        },
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
    await ref.read(calendarProvider.notifier).loadMonth(_focusedDay);
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
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskEditorScreen(task: task)),
    );
    if (!mounted) return;
    await _reload();
  }
}
