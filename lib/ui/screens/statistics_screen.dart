import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../statistics/statistics_calculator.dart';
import '../../ui/widgets/stat_widgets.dart';
import '../../ui/widgets/help_icon.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  int _appOpenCount = 0;

  @override
  void initState() {
    super.initState();
    _loadAppOpenCount();
  }

  Future<void> _loadAppOpenCount() async {
    // TODO: Load from AppUsageService
    setState(() {
      _appOpenCount = 1; // Placeholder
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tasksAsync = ref.watch(taskListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('统计')),
      body: tasksAsync.when(
        data: (tasks) {
          final stats = StatisticsCalculator.calculate(tasks, appOpenCount: _appOpenCount);
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
                        const Text(
                          '今日进度',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.6),
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
                                backgroundColor: theme.colorScheme.primary
                                    .withOpacity(0.1),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Overview cards - compact row
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: '总任务',
                        value: stats.totalTasks.toString(),
                        icon: Icons.task_alt,
                        color: theme.colorScheme.primary,
                        height: 100,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatCard(
                        label: '已完成',
                        value: stats.completedTasks.toString(),
                        icon: Icons.check_circle,
                        color: Colors.green,
                        height: 100,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatCard(
                        label: '待办',
                        value: stats.pendingTasks.toString(),
                        icon: Icons.pending_actions,
                        color: Colors.orange,
                        height: 100,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatCard(
                        label: '逾期',
                        value: stats.overdueTasks.toString(),
                        icon: Icons.warning,
                        color: Colors.red,
                        height: 100,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Completion rate
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '完成率',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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
                const SizedBox(height: 16),

                // Streak card
                StreakCard(
                  currentStreak: stats.currentStreak,
                  longestStreak: stats.longestStreak,
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),

                // Subtask completion rate
                if (stats.totalSteps > 0)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '子任务完成率',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${(stats.stepCompletionRate * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          Text(
                            '${stats.completedSteps}/${stats.totalSteps} 子任务已完成',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Starred tasks
                CompactStatCard(
                  label: '收藏任务',
                  value: stats.starredTasks.toString(),
                  icon: Icons.star,
                  color: Colors.amber,
                ),
                const SizedBox(height: 8),

                // App open count
                CompactStatCard(
                  label: '应用打开次数',
                  value: stats.appOpenCount.toString(),
                  icon: Icons.touch_app,
                  color: Colors.purple,
                ),
                const SizedBox(height: 8),

                // Total tags
                CompactStatCard(
                  label: '标签数量',
                  value: stats.totalTags.toString(),
                  icon: Icons.label,
                  color: Colors.teal,
                ),
                const SizedBox(height: 16),

                // Tag distribution
                if (stats.tagStats.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '标签分布',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TagDistributionChart(
                            tagStats: stats.tagStats,
                            baseColor: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Weekday distribution
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '星期分布',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        WeekdayDistributionChart(
                          weekdayDistribution: stats.weekdayDistribution,
                          baseColor: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Contribution heatmap - GitHub style
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              '年度贡献图',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '颜色越深完成越多',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ContributionHeatmap(
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
