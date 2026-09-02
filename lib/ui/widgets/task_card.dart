import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';

class TaskCard extends ConsumerWidget {
  final Task task;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Function(Task, TaskStep)? onStepToggle;

  const TaskCard({
    super.key,
    required this.task,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    this.onStepToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final taskColor = Color(int.parse(task.color.replaceFirst('#', '0xFF')));
    final completedSteps = task.steps.where((s) => s.status == 'completed').length;
    final totalSteps = task.steps.length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Color indicator
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: taskColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              
              // Icon
              if (task.icon != null)
                Image.asset('assets/icons/${task.icon}.png', width: 32, height: 32)
              else
                Icon(Icons.task_alt, color: taskColor, size: 28),
              const SizedBox(width: 12),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and date
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              decoration: task.status == 'done' ? TextDecoration.lineThrough : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (task.endTime != null)
                          Text(
                            _formatDate(task.endTime!),
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                      ],
                    ),
                    
                    // Note preview
                    if (task.note.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        task.note,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.outline,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    
                    // Tags
                    if (task.tags.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: task.tags.take(3).map((tag) {
                          final tagColor = Color(int.parse(tag.color.replaceFirst('#', '0xFF')));
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: tagColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tag.name,
                              style: TextStyle(fontSize: 10, color: tagColor),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    
                    // Subtasks preview
                    if (task.steps.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      ..._buildSubtaskPreview(context, ref),
                    ],
                  ],
                ),
              ),
              
              // Selection indicator
              if (isSelected)
                Icon(Icons.check_circle, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSubtaskPreview(BuildContext context, WidgetRef ref) {
    final maxVisible = 3;
    final visibleSteps = task.steps.take(maxVisible).toList();
    final remaining = task.steps.length - maxVisible;

    final widgets = <Widget>[];

    for (final step in visibleSteps) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  // Toggle step
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
          padding: const EdgeInsets.only(top: 4, left: 24),
          child: Text(
            '还有 $remaining 个子任务...',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.outline,
            ),
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
