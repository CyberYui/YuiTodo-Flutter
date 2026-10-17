import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/task_provider.dart';
import '../../providers/occurrence_provider.dart';
import '../../providers/tag_provider.dart';
import '../../services/app_usage_service.dart';
import '../../statistics/statistics_calculator.dart';
import '../../ui/widgets/stat_widgets.dart';
import '../../ui/widgets/help_icon.dart';

final statsRangeProvider = StateProvider<int>((ref) => 30);

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
    final count = await AppUsageService.instance.getTotalOpenCount();
    if (mounted) {
      setState(() {
        _appOpenCount = count;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final occurrencesAsync = ref.watch(occurrenceListProvider);
    final tasksAsync = ref.watch(taskListProvider);
    final tagsAsync = ref.watch(tagListProvider);
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(title: const Text('统计')),
      body: occurrencesAsync.when(
        data: (occurrences) {
          // Expand virtual occurrences into per-day task views so each
          // occurrence counts separately. Only count up to today so future
          // recurring instances do not inflate the totals.
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final rangeDays = ref.watch(statsRangeProvider);
          final rangeStart = rangeDays == 0
              ? DateTime(2000)
              : today.subtract(Duration(days: rangeDays - 1));
          final tasks = occurrences
              .where((o) => !o.isSkipped && !o.day.isAfter(today))
              .where((o) => !o.day.isBefore(rangeStart))
              .map(
                (o) => o.task.copyWith(
                  status: o.isDone ? 'done' : 'pending',
                  startDate: o.day.millisecondsSinceEpoch,
                  startTime: o.day.millisecondsSinceEpoch,
                ),
              )
              .toList();
          final stats = StatisticsCalculator.calculate(
            tasks,
            appOpenCount: _appOpenCount,
          );
          final todayProgress = StatisticsCalculator.getTodayProgress(tasks);
          final todayCreated = (tasksAsync.valueOrNull ?? []).where((t) {
            final d = DateTime.fromMillisecondsSinceEpoch(t.createdAt);
            return d.year == now.year && d.month == now.month && d.day == now.day;
          }).length;
          final tagCount = tagsAsync.value?.length ?? 0;

          if (isLandscape) {
            return _buildLandscapeLayout(
              theme,
              stats,
              todayProgress,
              todayCreated,
              tagCount,
            );
          }
          return _buildPortraitLayout(
            theme,
            stats,
            todayProgress,
            todayCreated,
            tagCount,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }

  Widget _buildRangeSelector(ThemeData theme) {
    final range = ref.watch(statsRangeProvider);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<int>(
        segments: const [
          ButtonSegment(value: 7, label: Text('7天')),
          ButtonSegment(value: 30, label: Text('30天')),
          ButtonSegment(value: 90, label: Text('90天')),
          ButtonSegment(value: 365, label: Text('1年')),
          ButtonSegment(value: 0, label: Text('全部')),
        ],
        selected: {range},
        onSelectionChanged: (s) {
          ref.read(statsRangeProvider.notifier).state = s.first;
        },
      ),
    );
  }

  Widget _buildEncouragement(ThemeData theme, double progress) {
    final (text, icon) = progress >= 0.9
        ? ('太棒了，今天几乎全部完成！', Icons.emoji_events)
        : progress >= 0.7
            ? ('进展不错，继续保持！', Icons.trending_up)
            : progress >= 0.4
                ? ('稳步推进中，加油。', Icons.directions_walk)
                : progress > 0
                    ? ('开始行动就是胜利。', Icons.play_arrow)
                    : ('今天还没有完成任务，从一件小事开始吧。', Icons.lightbulb_outline);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildPortraitLayout(ThemeData theme, TaskStatistics stats, double todayProgress, int todayCreated, int tagCount) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRangeSelector(theme),
          const SizedBox(height: 12),
          _buildEncouragement(theme, todayProgress),
          const SizedBox(height: 12),
          _buildTodayProgressCard(theme, todayProgress),
          const SizedBox(height: 16),
          _buildOverviewCards(theme, stats),
          const SizedBox(height: 16),
          _buildCompletionRateRow(theme, stats),
          const SizedBox(height: 16),
          StreakCard(
            currentStreak: stats.currentStreak,
            longestStreak: stats.longestStreak,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          CompactStatCard(
            label: '今日新增',
            value: todayCreated.toString(),
            icon: Icons.add_task,
            color: Colors.blue,
          ),
          const SizedBox(height: 8),
          CompactStatCard(
            label: '星标任务',
            value: stats.starredTasks.toString(),
            icon: Icons.star,
            color: Colors.amber,
          ),
          const SizedBox(height: 8),
          CompactStatCard(
            label: '应用打开次数',
            value: stats.appOpenCount.toString(),
            icon: Icons.touch_app,
            color: Colors.purple,
          ),
          const SizedBox(height: 8),
          CompactStatCard(
            label: '标签数量',
            value: tagCount.toString(),
            icon: Icons.label,
            color: Colors.teal,
          ),
          const SizedBox(height: 16),
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '月度贡献图',
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
  }

  Widget _buildLandscapeLayout(ThemeData theme, TaskStatistics stats, double todayProgress, int todayCreated, int tagCount) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Today progress + Overview cards
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildTodayProgressCard(theme, todayProgress)),
              const SizedBox(width: 16),
              Expanded(child: _buildOverviewCards(theme, stats)),
            ],
          ),
          const SizedBox(height: 16),
          // Row 2: Completion rate + Streak
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildCompletionRateRow(theme, stats)),
              const SizedBox(width: 16),
              Expanded(
                child: StreakCard(
                  currentStreak: stats.currentStreak,
                  longestStreak: stats.longestStreak,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Row 3: Compact stats
          Row(
            children: [
              Expanded(
                child: CompactStatCard(
                  label: '今日新增',
                  value: todayCreated.toString(),
                  icon: Icons.add_task,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CompactStatCard(
                  label: '应用打开次数',
                  value: stats.appOpenCount.toString(),
                  icon: Icons.touch_app,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CompactStatCard(
                  label: '标签数量',
                  value: tagCount.toString(),
                  icon: Icons.label,
                  color: Colors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Row 4: Tag distribution + Weekday distribution
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (stats.tagStats.isNotEmpty)
                Expanded(
                  child: Card(
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
                ),
              if (stats.tagStats.isNotEmpty) const SizedBox(width: 16),
              Expanded(
                child: Card(
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
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Row 5: 月度贡献图（横屏）
          // 横屏时屏幕变宽，若仍让格子平分宽度会被放得过大、几行就占满屏幕。
          // 因此限制格子最大边长为 18（与竖屏相近），并启用「网格 + 汇总数字」并排布局，
          // 让网格保持紧凑、右侧用数字填满横向空间。
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '月度贡献图',
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
                    maxCellSize: 18,
                    sideBySide: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayProgressCard(ThemeData theme, double todayProgress) {
    return Card(
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
    );
  }

  Widget _buildOverviewCards(ThemeData theme, TaskStatistics stats) {
    return Row(
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
    );
  }

  Widget _buildCompletionRateRow(ThemeData theme, TaskStatistics stats) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Card(
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
                  Text(
                    '${stats.completedTasks}/${stats.totalTasks} 任务已完成',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (stats.totalSteps > 0)
          Expanded(
            child: Card(
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
          ),
      ],
    );
  }
}
