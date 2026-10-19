import 'package:flutter/material.dart';
import '../../statistics/statistics_calculator.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final double height;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.height = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact stat card for single number display
class CompactStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const CompactStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MiniBarChart extends StatelessWidget {
  final List<double> values;
  final Color color;

  const MiniBarChart({super.key, required this.values, required this.color});

  @override
  Widget build(BuildContext context) {
    final maxValue = values.isEmpty
        ? 1.0
        : values.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 80,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: values.map((v) {
          final height = maxValue > 0 ? (v / maxValue) * 60 : 0.0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Container(
                height: height + 4,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// 月度贡献热力图（GitHub 绿墙风格）。
///
/// 布局说明：
/// - 竖屏（默认）：7 列（周一~周日）× 若干行，格子用 LayoutBuilder 平分宽度，
///   必然铺满整张卡片；格子尺寸随屏幕宽度自适应放大。
/// - 横屏（[sideBySide] = true）：格子边长被 [maxCellSize] 限制为与竖屏相近的大小，
///   避免横屏时格子被过度放大；网格与右侧的汇总数字并排，填满横向空间。
class ContributionHeatmap extends StatelessWidget {
  /// 日期 -> 当日完成任务数，key 为当天 0 点的 DateTime。
  final Map<DateTime, int> data;

  /// 热力格子的基色（通常取主题色）。
  final Color baseColor;

  /// 格子最大边长（逻辑像素）。
  /// - null：不限制，格子平分宽度（竖屏）。
  /// - 有值：格子不超过该边长，用于横屏时保持与竖屏相近的视觉大小。
  final double? maxCellSize;

  /// 是否采用「网格 + 汇总数字」左右并排布局（横屏用）。
  final bool sideBySide;

  const ContributionHeatmap({
    super.key,
    required this.data,
    required this.baseColor,
    this.maxCellSize,
    this.sideBySide = false,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weeks = <List<_HeatmapDay>>[];

    // Calculate start date (first day of current month, aligned to Monday)
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final monday = firstDayOfMonth.subtract(Duration(days: firstDayOfMonth.weekday - 1));
    var currentWeek = <_HeatmapDay>[];

    // Pad the first week
    final firstWeekday = monday.weekday;
    for (int i = 1; i < firstWeekday; i++) {
      currentWeek.add(
        _HeatmapDay(
          date: monday.subtract(Duration(days: firstWeekday - i)),
          count: -1,
        ),
      );
    }

    // Generate weeks for current month only
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    // Start from the first day of the current month
    final firstDayOfCurrentMonth = DateTime(now.year, now.month, 1);
    for (int i = 0; i < daysInMonth; i++) {
      final date = firstDayOfCurrentMonth.add(Duration(days: i));
      final day = DateTime(date.year, date.month, date.day);
      final count = data[day] ?? 0;
      currentWeek.add(_HeatmapDay(date: day, count: count));

      if (currentWeek.length == 7) {
        weeks.add(currentWeek);
        currentWeek = <_HeatmapDay>[];
      }
    }

    if (currentWeek.isNotEmpty) {
      weeks.add(currentWeek);
    }

    // Find max count for color scaling
    final maxCount = data.values.isEmpty
        ? 1
        : data.values.reduce((a, b) => a > b ? a : b);

    // Calculate monthly stats
    int monthTotal = 0;
    int monthActiveDays = 0;
    for (int i = 1; i <= daysInMonth; i++) {
      final day = DateTime(now.year, now.month, i);
      final count = data[day] ?? 0;
      monthTotal += count;
      if (count > 0) monthActiveDays++;
    }

    // Calculate yearly stats
    int yearTotal = 0;
    int yearActiveDays = 0;
    for (final entry in data.entries) {
      if (entry.key.year == now.year) {
        yearTotal += entry.value;
        if (entry.value > 0) yearActiveDays++;
      }
    }

    final grid = _buildGrid(context, weeks, maxCount);
    final monthLabel = Text(
      '${now.month}月',
      style: TextStyle(
        fontSize: 10,
        color: Theme.of(context).colorScheme.outline,
      ),
    );

    // ---------- 4. 横屏：网格 + 汇总数字左右并排 ----------
    // 网格格子被 maxCellSize 限制为与竖屏相近的大小，避免横屏时被过度放大；
    // 右侧放 2×2 汇总数字，充分利用横向空间，不留下大片空白。
    if (sideBySide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          grid,
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                monthLabel,
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildSummaryItem(context, '本月完成', '$monthTotal', '任务')),
                    Expanded(child: _buildSummaryItem(context, '活跃天数', '$monthActiveDays', '天')),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildSummaryItem(context, '年度完成', '$yearTotal', '任务')),
                    Expanded(child: _buildSummaryItem(context, '年度活跃', '$yearActiveDays', '天')),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }

    // ---------- 5. 竖屏：月份标签 + 铺满整张卡片宽度的网格 + 一行汇总 ----------
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 14,
          child: Align(alignment: Alignment.centerLeft, child: monthLabel),
        ),
        grid,
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildSummaryItem(context, '本月完成', '$monthTotal', '任务')),
            Expanded(child: _buildSummaryItem(context, '活跃天数', '$monthActiveDays', '天')),
            Expanded(child: _buildSummaryItem(context, '年度完成', '$yearTotal', '任务')),
            Expanded(child: _buildSummaryItem(context, '年度活跃', '$yearActiveDays', '天')),
          ],
        ),
      ],
    );
  }

  /// 构建热力网格。
  ///
  /// - [maxCellSize] 为 null：格子用 LayoutBuilder 平分可用宽度，必然铺满整张卡片（竖屏）。
  /// - 指定 [maxCellSize]：格子边长不超过该值，网格整体宽度固定（横屏，配合 sideBySide 使用）。
  ///   注意：此时不能再用 LayoutBuilder 取宽度——因为在 Row 中作为非弹性子组件，
  ///   LayoutBuilder 会拿到无限宽度约束，算不出正确尺寸。
  Widget _buildGrid(BuildContext context, List<List<_HeatmapDay>> weeks, int maxCount) {
    if (maxCellSize != null) {
      // 固定格子大小（横屏）
      return _gridWithCellSize(maxCellSize!, weeks, maxCount);
    }
    // 铺满可用宽度（竖屏）
    return LayoutBuilder(
      builder: (context, constraints) {
        // 7 列，列间距 2，共 6 个间距
        final cell = (constraints.maxWidth - 6 * 2) / 7;
        return _gridWithCellSize(cell, weeks, maxCount);
      },
    );
  }

  /// 按给定格子边长渲染整个网格。
  Widget _gridWithCellSize(double cell, List<List<_HeatmapDay>> weeks, int maxCount) {
    final totalWidth = cell * 7 + 6 * 2;
    return SizedBox(
      width: totalWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: weeks.map((week) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: List.generate(7, (col) {
                final day = col < week.length ? week[col] : null;
                // count < 0 表示当前月份之外的占位空格，渲染为透明
                final isEmpty = day == null || day.count < 0;
                final intensity =
                    (day != null && maxCount > 0) ? day.count / maxCount : 0.0;
                // 非空格子的颜色：无任务=极浅底色，有任务=随完成数加深（0.2 ~ 1.0）
                final Color cellColor;
                if (isEmpty) {
                  cellColor = Colors.transparent;
                } else if (day.count == 0) {
                  cellColor = baseColor.withValues(alpha: 0.08);
                } else {
                  cellColor = baseColor.withValues(alpha: 0.2 + intensity * 0.8);
                }
                return Padding(
                  padding: EdgeInsets.only(right: col < 6 ? 2 : 0),
                  child: Container(
                    width: cell,
                    height: cell,
                    decoration: BoxDecoration(
                      color: cellColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, String value, String unit) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: baseColor,
          ),
        ),
        Text(
          '$label($unit)',
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

/// Horizontal bar chart for tag distribution
class TagDistributionChart extends StatelessWidget {
  final List<TagStat> tagStats;
  final Color baseColor;

  const TagDistributionChart({
    super.key,
    required this.tagStats,
    required this.baseColor,
  });

  @override
  Widget build(BuildContext context) {
    if (tagStats.isEmpty) {
      return const Center(child: Text('暂无标签数据'));
    }

    final maxTotal = tagStats.map((t) => t.total).reduce((a, b) => a > b ? a : b);

    return Column(
      children: tagStats.take(5).map((tag) {
        final percentage = maxTotal > 0 ? tag.total / maxTotal : 0.0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  tag.name,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: baseColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: percentage,
                      child: Container(
                        height: 20,
                        decoration: BoxDecoration(
                          color: _parseColor(tag.color),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 40,
                child: Text(
                  '${tag.total}',
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _parseColor(String colorStr) {
    try {
      return Color(int.parse(colorStr.replaceFirst('#', '0xFF')));
    } catch (_) {
      return baseColor;
    }
  }
}

/// Weekday distribution chart
class WeekdayDistributionChart extends StatelessWidget {
  final Map<int, int> weekdayDistribution;
  final Color baseColor;

  const WeekdayDistributionChart({
    super.key,
    required this.weekdayDistribution,
    required this.baseColor,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = weekdayDistribution.values.isEmpty
        ? 1
        : weekdayDistribution.values.reduce((a, b) => a > b ? a : b);

    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];

    return SizedBox(
      height: 130,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final weekday = index + 1;
          final count = weekdayDistribution[weekday] ?? 0;
          final barHeight = maxValue > 0 ? (count / maxValue) * 70 : 0.0;
          return SizedBox(
            width: 32,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 数字标签 - 固定在柱子上方
                SizedBox(
                  height: 16,
                  child: Text(
                    '$count',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 2),
                // 柱子
                Container(
                  width: 20,
                  height: barHeight + 2,
                  decoration: BoxDecoration(
                    color: count > 0
                        ? baseColor.withValues(alpha: 0.7)
                        : baseColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 4),
                // 星期标签
                SizedBox(
                  height: 16,
                  child: Text(
                    weekdays[index],
                    style: const TextStyle(fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

/// Streak display card
class StreakCard extends StatelessWidget {
  final int currentStreak;
  final int longestStreak;
  final Color color;

  const StreakCard({
    super.key,
    required this.currentStreak,
    required this.longestStreak,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Icon(Icons.local_fire_department, color: color, size: 32),
                const SizedBox(height: 4),
                Text(
                  '$currentStreak',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const Text(
                  '当前连续',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            Container(
              height: 40,
              width: 1,
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
            Column(
              children: [
                Icon(Icons.emoji_events, color: color, size: 32),
                const SizedBox(height: 4),
                Text(
                  '$longestStreak',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const Text(
                  '最长连续',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeatmapDay {
  final DateTime date;
  final int count;

  _HeatmapDay({required this.date, required this.count});
}
