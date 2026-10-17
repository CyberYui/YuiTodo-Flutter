import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/recurrence_rule.dart';
import '../../models/task.dart';
import '../../providers/habit_provider.dart';
import '../../providers/occurrence_provider.dart';
import '../../repositories/task_repository.dart';
import '../widgets/habit_grid.dart';

const _habitColors = [
  '#22C55E',
  '#3B82F6',
  '#F59E0B',
  '#EF4444',
  '#8B5CF6',
  '#06B6D4',
  '#EC4899',
  '#64748B',
];

class HabitScreen extends ConsumerWidget {
  const HabitScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(habitProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('习惯')),
      body: async.when(
        data: (habits) {
          if (habits.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '还没有习惯，点击 + 创建一个',
                    style: TextStyle(color: theme.colorScheme.outline),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: habits.length,
            itemBuilder: (context, index) =>
                _card(context, ref, theme, habits[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createHabit(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _card(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    HabitData habit,
  ) {
    final color = Color(int.parse(habit.task.color.replaceFirst('#', '0xFF')));
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.15),
                  child: Icon(Icons.check_circle, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.task.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '连续 ${habit.streak} 天 · 累计 ${habit.totalDays} 天 · 本周 ${habit.weekDone}/${habit.task.habitTargetPerWeek}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: habit.todayDone ? '取消今日打卡' : '今日打卡',
                  icon: Icon(
                    habit.todayDone
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    color:
                        habit.todayDone ? color : theme.colorScheme.outline,
                    size: 30,
                  ),
                  onPressed: () => _toggle(ref, habit),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'delete') _delete(context, ref, habit);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'delete', child: Text('删除习惯')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            HabitGrid(days: habit.days, color: color),
          ],
        ),
      ),
    );
  }

  Future<void> _toggle(WidgetRef ref, HabitData habit) async {
    final engine = ref.read(taskDateQueryEngineProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (habit.todayDone) {
      await engine.uncomplete(habit.task, today);
    } else {
      await engine.complete(habit.task, today);
    }
    ref.invalidate(habitProvider);
    await ref.read(occurrenceListProvider.notifier).load();
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    HabitData habit,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除习惯'),
        content: Text('确定删除「${habit.task.title}」吗？打卡记录将一并删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final repo = ref.read(taskRepositoryProvider);
    final rules = await repo.getRecurrenceRuleMap();
    final rule = rules[habit.task.id];
    if (rule?.id != null) {
      await repo.deleteRecurrenceRule(rule!.id!);
    }
    await repo.deleteTask(habit.task.id!);
    ref.invalidate(habitProvider);
    await ref.read(occurrenceListProvider.notifier).load();
  }

  Future<void> _createHabit(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    var color = '#22C55E';
    var target = 7;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('新建习惯'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: '习惯名称',
                    hintText: '如：喝水、阅读、运动',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('颜色'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _habitColors.map((c) {
                    final selected = c == color;
                    return GestureDetector(
                      onTap: () => setState(() => color = c),
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor:
                            Color(int.parse(c.replaceFirst('#', '0xFF'))),
                        child: selected
                            ? const Icon(Icons.check,
                                size: 14, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('每周目标'),
                    const Spacer(),
                    Text('$target 天'),
                  ],
                ),
                Slider(
                  value: target.toDouble(),
                  min: 1,
                  max: 7,
                  divisions: 6,
                  onChanged: (v) => setState(() => target = v.round()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;
    final title = controller.text.trim();
    if (title.isEmpty) return;

    final repo = ref.read(taskRepositoryProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final id = await repo.createTask(Task(
      title: title,
      color: color,
      isHabit: true,
      habitTargetPerWeek: target,
      startDate: today.millisecondsSinceEpoch,
      startTime: today.millisecondsSinceEpoch,
      endTime: today.add(const Duration(days: 1)).millisecondsSinceEpoch,
      createdAt: now.millisecondsSinceEpoch,
      updatedAt: now.millisecondsSinceEpoch,
    ));
    await repo.createRecurrenceRule(RecurrenceRule(
      taskId: id,
      type: 'daily',
      interval: 1,
      createdAt: now.millisecondsSinceEpoch,
    ));
    ref.invalidate(habitProvider);
    await ref.read(occurrenceListProvider.notifier).load();
  }
}
