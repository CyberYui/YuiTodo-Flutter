import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../providers/tag_provider.dart';

class TaskCard extends ConsumerWidget {
  final Task task;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const TaskCard({
    super.key,
    required this.task,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDone = task.status == 'done';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isSelected ? theme.colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Checkbox - separate tap target to prevent accidental navigation
              GestureDetector(
                onTap: () => ref.read(taskListProvider.notifier).toggleComplete(task),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDone ? theme.colorScheme.primary : theme.colorScheme.outline,
                      width: 2,
                    ),
                    color: isDone ? theme.colorScheme.primary : Colors.transparent,
                  ),
                  child: isDone
                      ? const Icon(Icons.check, size: 18, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              // Icon
              if (task.icon != null) ...[
                Image.asset('assets/icons/${task.icon}.png', width: 32, height: 32),
                const SizedBox(width: 12),
              ],
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        color: isDone ? theme.colorScheme.onSurface.withOpacity(0.5) : null,
                      ),
                    ),
                    if (task.note.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.note,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    // Tags
                    if (task.tags.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: task.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Color(int.parse(tag.color.replaceFirst('#', '0xFF'))).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tag.name,
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(int.parse(tag.color.replaceFirst('#', '0xFF'))),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    // Steps indicator
                    if (task.steps.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.checklist, size: 14, color: theme.colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            '${task.steps.where((s) => s.status == 'completed').length}/${task.steps.length}',
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.primary),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Star
              if (task.isStarred)
                Icon(Icons.star, size: 20, color: Colors.amber[600]),
            ],
          ),
        ),
      ),
    );
  }
}
