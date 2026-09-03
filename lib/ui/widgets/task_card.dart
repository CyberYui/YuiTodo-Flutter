import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/task.dart';
import '../../core/icons/app_icons.dart';
import '../../core/icons/flat_icon_mapper.dart';

/// 任务卡片组件
/// 布局结构参考 QQ 个人资料卡片：
/// - 左侧：色条 + 圆形图标（带拖拽手柄）
/// - 右侧：标题行（标题 + 日期）、标签行、备注、子任务预览
/// - 整体紧凑，无多余空白
class TaskCard extends ConsumerWidget {
  final Task task;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Function(Task, TaskStep)? onStepToggle;
  final int index;

  const TaskCard({
    super.key,
    required this.task,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    this.onStepToggle,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // 解析任务颜色（将 #RRGGBB 格式转为 Color）
    final taskColor = Color(int.parse(task.color.replaceFirst('#', '0xFF')));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        color: isSelected ? theme.colorScheme.primary.withOpacity(0.08) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================== 左侧：色条 ====================
            // 色条：位于卡片最左侧的竖向色带，用于快速识别任务颜色
            Container(
              width: 4,
              height: 70, // 高度固定，根据内容自适应更好但需要 LayoutBuilder
              margin: const EdgeInsets.only(top: 12, bottom: 12, left: 0),
              decoration: BoxDecoration(
                color: taskColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // ==================== 左侧：圆形图标 ====================
            // 图标区域：圆形背景 + 图标（支持二次元 PNG 或 Material Icons）
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 12),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: taskColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: task.icon != null
                    ? AppIcons.isAvatar(task.icon!)
                        ? ClipOval(
                            child: Image.asset('assets/icons/${task.icon}.png', width: 48, height: 48),
                          )
                        : Icon(FlatIconMapper.getIcon(task.icon!), size: 24, color: taskColor)
                    : Icon(Icons.task_alt, size: 24, color: taskColor),
              ),
            ),
            const SizedBox(width: 12),
            
            // ==================== 中间：内容区域 ====================
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // -------------------- 标题行 --------------------
                    // 包含任务标题（左）和截止日期（右）
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              decoration: task.status == 'done' ? TextDecoration.lineThrough : null,
                              color: task.status == 'done' ? theme.colorScheme.outline : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (task.endTime != null)
                          Text(
                            _formatDate(task.endTime!),
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                          ),
                      ],
                    ),
                    
                    // -------------------- 标签行 --------------------
                    // 显示任务的标签列表（最多3个），每个标签有独立颜色
                    if (task.tags.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: task.tags.take(3).map((tag) {
                          final tagColor = Color(int.parse(tag.color.replaceFirst('#', '0xFF')));
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: tagColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tag.name,
                              style: TextStyle(fontSize: 10, color: tagColor, fontWeight: FontWeight.w500),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    
                    // -------------------- 备注预览 --------------------
                    // 显示任务备注内容（最多2行）
                    if (task.note.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.note,
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    
                    // -------------------- 子任务预览 --------------------
                    // 显示子任务进度和列表（最多2个+N更多）
                    if (task.steps.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      ..._buildSubtasks(),
                    ],
                  ],
                ),
              ),
            ),
            
            // ==================== 右侧：拖拽手柄 ====================
            // ReorderableDelayedDragStartListener：长按图标区域可拖拽排序
            ReorderableDelayedDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, top: 12),
                child: Icon(Icons.drag_indicator, size: 16, color: theme.colorScheme.outline.withOpacity(0.4)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建子任务预览列表
  List<Widget> _buildSubtasks() {
    final maxVisible = 2; // 最多显示2个子任务
    final visibleSteps = task.steps.take(maxVisible).toList();
    final remaining = task.steps.length - maxVisible;
    final subtaskColor = Color(int.parse(task.color.replaceFirst('#', '0xFF')));

    final widgets = <Widget>[];

    // 显示可见的子任务列表（带勾选框）
    for (final step in visibleSteps) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Row(
            children: [
              // 勾选框：点击可切换子任务完成状态
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (onStepToggle != null) {
                    onStepToggle!(task, step);
                  }
                },
                child: Icon(
                  step.status == 'completed' ? Icons.check_circle : Icons.circle_outlined,
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
                    decoration: step.status == 'completed' ? TextDecoration.lineThrough : null,
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

    // 如果还有更多子任务，显示"+N更多"
    if (remaining > 0) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 3, left: 24),
          child: Text(
            '还有 $remaining 个...',
            style: TextStyle(fontSize: 11, color: subtaskColor.withOpacity(0.6)),
          ),
        ),
      );
    }

    return widgets;
  }

  /// 格式化日期显示
  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);

    if (taskDate == today) return '今天';
    if (taskDate == today.add(const Duration(days: 1))) return '明天';
    return '${date.month}/${date.day}';
  }
}
