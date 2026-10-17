import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/task.dart';
import '../../core/icons/app_icons.dart';
import '../../core/icons/flat_icon_mapper.dart';

/// 任务卡片组件
/// 布局结构：上下并行
/// - 上行：色条 + 图标 + (标题+日期+标签+备注) + 拖拽手柄
/// - 下行：子任务预览（全宽）
class TaskCard extends ConsumerWidget {
  final Task task;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Function(Task, TaskStep)? onStepToggle;
  final int index;

  /// Optional override for the "done" visual state. Used when the card
  /// represents a virtual occurrence whose state lives in task_occurrence
  /// rather than on [task.status].
  final bool? isDone;

  /// Toggles completion for this card (tapping the leading icon).
  final VoidCallback? onToggleComplete;

  /// Local date of the virtual occurrence this card represents. When it
  /// differs from the task's own start date, the card shows this day instead.
  final DateTime? occurrenceDay;

  const TaskCard({
    super.key,
    required this.task,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    this.onStepToggle,
    required this.index,
    this.isDone,
    this.occurrenceDay,
    this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final taskColor = Color(int.parse(task.color.replaceFirst('#', '0xFF')));
    final done = isDone ?? (task.status == 'done');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primary.withOpacity(0.15)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? Border.all(color: theme.colorScheme.primary.withOpacity(0.4))
            : null,
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================== 上行：色条+图标+内容+拖拽手柄 ====================
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 色条：左侧4px竖向彩色条 ---
                  Container(
                    width: 4,
                    height: 56,
                    decoration: BoxDecoration(
                      color: taskColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // --- 圆形图标（点击切换完成） ---
                  GestureDetector(
                    onTap: onToggleComplete,
                    behavior: HitTestBehavior.opaque,
                    child: Stack(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: taskColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: task.icon != null
                              ? AppIcons.isAvatar(task.icon!)
                                    ? ClipOval(
                                        child: Image.asset(
                                          'assets/icons/${task.icon}.png',
                                          width: 48,
                                          height: 48,
                                        ),
                                      )
                                    : Icon(
                                        FlatIconMapper.getIcon(task.icon!),
                                        size: 24,
                                        color: taskColor,
                                      )
                              : Icon(Icons.task_alt, size: 24, color: taskColor),
                        ),
                        if (done)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 240),
                              curve: Curves.easeOutBack,
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value.clamp(0, 1.2),
                                  child: Opacity(
                                    opacity: value.clamp(0, 1),
                                    child: child,
                                  ),
                                );
                              },
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // --- 上行右侧：标题+日期+标签+备注 ---
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 标题行（标题左 + 日期右）
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                task.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  decoration: done
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: done
                                      ? theme.colorScheme.outline
                                      : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (task.isStarred) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.star,
                                size: 14,
                                color: Colors.amber,
                              ),
                            ],
                            _buildDateLabel(theme),
                          ],
                        ),

                        // 标签行（最多3个彩色标签）
                        if (task.tags.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 4,
                            runSpacing: 2,
                            children: task.tags.take(3).map((tag) {
                              final tagColor = Color(
                                int.parse(tag.color.replaceFirst('#', '0xFF')),
                              );
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: tagColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  tag.name,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: tagColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],

                        // 备注预览（最多2行）
                        if (task.note.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            task.note,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.outline,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // --- 拖拽手柄（右侧） ---
                  ReorderableDelayedDragStartListener(
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8, top: 4),
                      child: Icon(
                        Icons.drag_indicator,
                        size: 16,
                        color: theme.colorScheme.outline.withOpacity(0.4),
                      ),
                    ),
                  ),
                ],
              ),

              // ==================== 下行：子任务预览（全宽） ====================
              if (task.steps.isNotEmpty) ...[
                const SizedBox(height: 8),
                // 子任务进度
                Text(
                  '子任务 ${task.steps.where((s) => s.status == 'completed').length}/${task.steps.length}',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.outline,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                ..._buildSubtasks(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 构建子任务预览列表
  List<Widget> _buildSubtasks() {
    final maxVisible = 3;
    final visibleSteps = task.steps.take(maxVisible).toList();
    final remaining = task.steps.length - maxVisible;
    final subtaskColor = Color(int.parse(task.color.replaceFirst('#', '0xFF')));

    final widgets = <Widget>[];

    for (final step in visibleSteps) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (onStepToggle != null) {
                    onStepToggle!(task, step);
                  }
                },
                child: Icon(
                  step.status == 'completed'
                      ? Icons.check_circle
                      : Icons.circle_outlined,
                  size: 16,
                  color: step.status == 'completed' ? Colors.green : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  step.title,
                  style: TextStyle(
                    fontSize: 12,
                    decoration: step.status == 'completed'
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (remaining > 0) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 4, left: 24),
          child: Text(
            '还有 $remaining 个...',
            style: TextStyle(
              fontSize: 11,
              color: subtaskColor.withOpacity(0.6),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  /// 构建日期标签：显示开始日期；若结束日期是另一天则一并显示范围。
  Widget _buildDateLabel(ThemeData theme) {
    final startTs = task.startDate ?? task.startTime;

    // If this card is a virtual occurrence on a different day than the task's
    // own anchor date, show the occurrence day (e.g. today / tomorrow).
    if (occurrenceDay != null) {
      final occ = DateTime(
        occurrenceDay!.year,
        occurrenceDay!.month,
        occurrenceDay!.day,
      );
      final startDate = startTs != null
          ? DateTime.fromMillisecondsSinceEpoch(startTs)
          : null;
      final startDay = startDate != null
          ? DateTime(startDate.year, startDate.month, startDate.day)
          : null;
      if (startDay == null || occ != startDay) {
        return Text(
          _formatDateFromDate(occ),
          style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
        );
      }
    }

    if (startTs == null) return const SizedBox.shrink();
    final startLabel = _formatDate(startTs);
    final endTs = task.endTime;
    final showEnd = endTs != null && !_isSameDay(startTs, endTs);
    final text = showEnd ? '$startLabel → ${_formatDate(endTs)}' : startLabel;
    return Text(
      text,
      style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
    );
  }

  bool _isSameDay(int a, int b) {
    final da = DateTime.fromMillisecondsSinceEpoch(a);
    final db = DateTime.fromMillisecondsSinceEpoch(b);
    return da.year == db.year && da.month == db.month && da.day == db.day;
  }

  /// 格式化日期显示
  String _formatDate(int timestamp) {
    return _formatDateFromDate(DateTime.fromMillisecondsSinceEpoch(timestamp));
  }

  String _formatDateFromDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) return '今天';
    if (d == today.add(const Duration(days: 1))) return '明天';
    if (d == today.subtract(const Duration(days: 1))) return '昨天';
    return '${date.month}/${date.day}';
  }
}
