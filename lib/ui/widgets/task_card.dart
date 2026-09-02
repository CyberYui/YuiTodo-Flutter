import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/task.dart';
import '../../core/icons/app_icons.dart';
import '../../core/icons/flat_icon_mapper.dart';

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
    final taskColor = Color(int.parse(task.color.replaceFirst('#', '0xFF')));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: isSelected ? theme.colorScheme.primary.withOpacity(0.08) : theme.colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Color strip on the far left
              Container(
                width: 3,
                height: 60,
                decoration: BoxDecoration(
                  color: taskColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              
              // Icon with drag handle - long press to reorder
              ReorderableDelayedDragStartListener(
                index: index,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: taskColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: task.icon != null
                      ? AppIcons.isAvatar(task.icon!)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.asset('assets/icons/${task.icon}.png', width: 32, height: 32),
                            )
                          : Icon(FlatIconMapper.getIcon(task.icon!), size: 20, color: taskColor)
                      : Icon(Icons.task_alt, size: 20, color: taskColor),
                ),
              ),
              const SizedBox(width: 10),
              
              // Content area
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
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
                    
                    // Tags row
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
                    
                    // Note preview
                    if (task.note.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.note,
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    
                    // Subtasks preview
                    if (task.steps.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      ..._buildSubtasks(),
                    ],
                  ],
                ),
              ),
              
              // Drag handle icon (subtle, on the right)
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Icon(Icons.drag_indicator, size: 16, color: theme.colorScheme.outline.withOpacity(0.4)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSubtasks() {
    final maxVisible = 2;
    final visibleSteps = task.steps.take(maxVisible).toList();
    final remaining = task.steps.length - maxVisible;
    final subtaskColor = Color(int.parse(task.color.replaceFirst('#', '0xFF')));

    final widgets = <Widget>[];

    for (final step in visibleSteps) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 3),
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
