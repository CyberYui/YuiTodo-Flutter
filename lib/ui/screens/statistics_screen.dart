import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../statistics/statistics_calculator.dart';
import '../../ui/widgets/stat_widgets.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tasksAsync = ref.watch(taskListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('统计'),
      ),
      body: tasksAsync.when(
        data: (tasks) {
          final stats = StatisticsCalculator.calculate(tasks);
          final todayProgress = StatisticsCalculator.getTodayProgress(tasks);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Today progress
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('今日进度', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${(todayProgress * 100).toInt()}%',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  Text(
                                    '已完成',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 60,
                              height: 60,
                              child: CircularProgressIndicator(
                                value: todayProgress,
                                strokeWidth: 8,
                                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Overview cards - use Row instead of GridView to avoid overflow
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: '总任务',
                        value: stats.totalTasks.toString(),
                        icon: Icons.task_alt,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: '已完成',
                        value: stats.completedTasks.toString(),
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: '待办',
                        value: stats.pendingTasks.toString(),
                        icon: Icons.pending_actions,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: '逾期',
                        value: stats.overdueTasks.toString(),
                        icon: Icons.warning,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Completion rate
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('完成率', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 12),
                        Text(
                          '${(stats.completionRate * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Daily trend
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('近 30 天趋势', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: stats.dailyCompletions.length,
                            itemBuilder: (context, index) {
                              final day = stats.dailyCompletions[index];
                              final height = day.total > 0 ? (day.completed / day.total) * 80.0 : 0.0;
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      width: 16,
                                      height: height + 4,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${day.date.day}',
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Annual heatmap
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('年度热力图', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 12),
                        AnnualHeatmap(
                          data: stats.heatmapData,
                          baseColor: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }
}
