import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../providers/tag_provider.dart';
import '../../core/icons/app_icons.dart';
import '../../core/icons/flat_icon_mapper.dart';
import '../../core/theme/task_colors.dart';
import '../../core/utils/recurrence.dart';
import '../widgets/recurrence_selector.dart';
import '../widgets/reminder_selector.dart';
import '../widgets/icon_picker.dart';
import '../../repositories/task_repository.dart';

class TaskEditorScreen extends ConsumerStatefulWidget {
  final Task? task;

  const TaskEditorScreen({super.key, this.task});

  @override
  ConsumerState<TaskEditorScreen> createState() => _TaskEditorScreenState();
}

class _TaskEditorScreenState extends ConsumerState<TaskEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _noteController;
  late TextEditingController _stepController;
  
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  String _color = '#3B82F6';
  String? _icon;
  List<TaskStep> _steps = [];
  List<Tag> _selectedTags = [];
  RecurrenceType _recurrenceType = RecurrenceType.none;
  int _recurrenceInterval = 1;
  List<String> _reminderTimes = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _noteController = TextEditingController(text: widget.task?.note ?? '');
    _stepController = TextEditingController();
    
    if (widget.task != null) {
      _startDate = DateTime.fromMillisecondsSinceEpoch(widget.task!.startDate ?? widget.task!.startTime ?? DateTime.now().millisecondsSinceEpoch);
      _endDate = DateTime.fromMillisecondsSinceEpoch(widget.task!.endTime ?? DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch);
      _color = widget.task!.color;
      _icon = widget.task!.icon;
      _steps = widget.task!.steps.toList();
      _selectedTags = widget.task!.tags.toList();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _stepController.dispose();
    super.dispose();
  }

  void _addStep() {
    final text = _stepController.text.trim();
    if (text.isEmpty) return;
    
    setState(() {
      _steps.add(TaskStep(
        taskId: widget.task?.id ?? 0,
        title: text,
        sortOrder: _steps.length,
      ));
      _stepController.clear();
    });
  }

  void _removeStep(int index) {
    setState(() {
      _steps.removeAt(index);
    });
  }

  void _toggleStepStatus(int index) {
    setState(() {
      final step = _steps[index];
      _steps[index] = TaskStep(
        id: step.id,
        taskId: step.taskId,
        title: step.title,
        sortOrder: step.sortOrder,
        status: step.status == 'completed' ? 'pending' : 'completed',
      );
    });
  }

  Future<void> _showIconPicker(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => IconPickerBottomSheet(
        selectedIcon: _icon,
        onSelected: (icon) => Navigator.pop(context, icon),
      ),
    );
    
    if (result != null) {
      setState(() => _icon = result);
    }
  }

  Future<void> _saveTask() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入任务标题')),
      );
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final task = Task(
      id: widget.task?.id,
      title: _titleController.text.trim(),
      note: _noteController.text.trim(),
      status: widget.task?.status ?? 'pending',
      startTime: _startDate.millisecondsSinceEpoch,
      endTime: _endDate.millisecondsSinceEpoch,
      startDate: _startDate.millisecondsSinceEpoch,
      color: _color,
      icon: _icon,
      recurrenceId: widget.task?.recurrenceId,
      isStarred: widget.task?.isStarred ?? false,
      sortOrder: widget.task?.sortOrder ?? 0,
      createdAt: widget.task?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      int taskId;
      if (widget.task == null) {
        taskId = await ref.read(taskRepositoryProvider).createTask(task);
        final repo = ref.read(taskRepositoryProvider);
        for (int i = 0; i < _steps.length; i++) {
          await repo.createStep(TaskStep(
            taskId: taskId,
            title: _steps[i].title,
            sortOrder: i,
            status: _steps[i].status,
          ));
        }
        for (final tag in _selectedTags) {
          if (tag.id != null) {
            await repo.addTagToTask(taskId, tag.id!);
          }
        }
        await ref.read(taskListProvider.notifier).loadTasks();
      } else {
        await ref.read(taskListProvider.notifier).updateTask(task);
        taskId = task.id!;
        final repo = ref.read(taskRepositoryProvider);
        
        // Delete existing steps and re-add with correct order
        final existingSteps = await repo.getStepsForTask(taskId);
        for (final step in existingSteps) {
          if (step.id != null) {
            await repo.deleteStep(step.id!);
          }
        }
        for (int i = 0; i < _steps.length; i++) {
          await repo.createStep(TaskStep(
            taskId: taskId,
            title: _steps[i].title,
            sortOrder: i,
            status: _steps[i].status,
          ));
        }
        
        // Update tags
        final existingTags = await repo.getTagsForTask(taskId);
        for (final tag in existingTags) {
          await repo.removeTagFromTask(taskId, tag.id!);
        }
        for (final tag in _selectedTags) {
          if (tag.id != null) {
            await repo.addTagToTask(taskId, tag.id!);
          }
        }
        await ref.read(taskListProvider.notifier).loadTasks();
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? '新建任务' : '编辑任务'),
        actions: [
          TextButton.icon(
            onPressed: _saveTask,
            icon: const Icon(Icons.check),
            label: const Text('保存'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Basic info section
          _buildSection(
            title: '基本信息',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: '任务标题',
                    hintText: '输入任务名称',
                    prefixIcon: Icon(Icons.title),
                  ),
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: '备注',
                    hintText: '添加备注（可选）',
                    prefixIcon: Icon(Icons.notes),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Date section
          _buildSection(
            title: '日期',
            child: Row(
              children: [
                Expanded(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('开始日期'),
                    subtitle: Text('${_startDate.year}-${_startDate.month}-${_startDate.day}'),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) setState(() => _startDate = date);
                    },
                  ),
                ),
                Expanded(
                  child: ListTile(
                    leading: const Icon(Icons.event),
                    title: const Text('结束日期'),
                    subtitle: Text('${_endDate.year}-${_endDate.month}-${_endDate.day}'),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) setState(() => _endDate = date);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Color section
          _buildSection(
            title: '颜色',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _showColorPicker(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(int.parse(_color.replaceFirst('#', '0xFF'))).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Color(int.parse(_color.replaceFirst('#', '0xFF'))).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Color(int.parse(_color.replaceFirst('#', '0xFF'))),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text('已选择: $_color')),
                        const Icon(Icons.palette),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: TaskColors.all.map((c) {
                    final isSelected = _color == c;
                    final isCustom = TaskColors.isCustom(c);
                    final color = isCustom ? Colors.grey.withOpacity(0.3) : Color(int.parse(c.replaceFirst('#', '0xFF')));
                    return GestureDetector(
                      onTap: () {
                        if (isCustom) {
                          _showCustomColorPicker(context);
                        } else {
                          setState(() => _color = c);
                        }
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: theme.colorScheme.outline, width: 3) : Border.all(color: Colors.grey.withOpacity(0.2)),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ] : null,
                        ),
                        child: isCustom 
                            ? const Icon(Icons.color_lens, color: Colors.white, size: 18) 
                            : (isSelected ? const Icon(Icons.check, color: Colors.white, size: 18) : null),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Icon section
          _buildSection(
            title: '图标',
            child: GestureDetector(
              onTap: () => _showIconPicker(context),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    if (_icon != null)
                      AppIcons.isAvatar(_icon!)
                          ? Image.asset('assets/icons/$_icon.png', width: 40, height: 40)
                          : Icon(FlatIconMapper.getIcon(_icon!), size: 40)
                        else
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.add_photo_alternate, color: theme.colorScheme.outline),
                          ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_icon == null ? '选择图标' : '当前: $_icon')),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Tags section
          _buildSection(
            title: '标签',
            child: Consumer(
              builder: (context, ref, _) {
                final tagsAsync = ref.watch(tagListProvider);
                return tagsAsync.when(
                  data: (tags) => Wrap(
                    spacing: 8,
                    children: tags.map((tag) {
                      final isSelected = _selectedTags.any((t) => t.id == tag.id);
                      return FilterChip(
                        label: Text(tag.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedTags.add(tag);
                            } else {
                              _selectedTags.removeWhere((t) => t.id == tag.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const Text('加载标签失败'),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Recurrence section
          _buildSection(
            title: '重复',
            child: RecurrenceSelector(
              type: _recurrenceType,
              interval: _recurrenceInterval,
              onTypeChanged: (t) => setState(() => _recurrenceType = t),
              onIntervalChanged: (i) => setState(() => _recurrenceInterval = i),
            ),
          ),
          const SizedBox(height: 16),

          // Reminder section
          _buildSection(
            title: '提醒',
            child: ReminderSelector(
              times: _reminderTimes,
              onChanged: (times) => setState(() => _reminderTimes = times),
            ),
          ),
          const SizedBox(height: 16),

          // Steps section
          _buildSection(
            title: '子任务',
            child: Column(
              children: [
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _steps.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex--;
                      final item = _steps.removeAt(oldIndex);
                      _steps.insert(newIndex, item);
                      for (int i = 0; i < _steps.length; i++) {
                        _steps[i] = TaskStep(
                          id: _steps[i].id,
                          taskId: _steps[i].taskId,
                          title: _steps[i].title,
                          sortOrder: i,
                          status: _steps[i].status,
                        );
                      }
                    });
                  },
                  itemBuilder: (context, index) {
                    final step = _steps[index];
                    return ListTile(
                      key: ValueKey('step-$index'),
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ReorderableDragStartListener(
                            index: index,
                            child: Icon(Icons.drag_handle, color: theme.colorScheme.outline),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _toggleStepStatus(index),
                            child: Icon(
                              step.status == 'completed' ? Icons.check_circle : Icons.circle_outlined,
                              color: step.status == 'completed' ? theme.colorScheme.primary : null,
                            ),
                          ),
                        ],
                      ),
                      title: Text(
                        step.title,
                        style: TextStyle(
                          decoration: step.status == 'completed' ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => _removeStep(index),
                      ),
                    );
                  },
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _stepController,
                        decoration: const InputDecoration(
                          hintText: '添加子任务',
                          prefixIcon: Icon(Icons.add),
                        ),
                        onSubmitted: (_) => _addStep(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _addStep,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: child,
          ),
        ],
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('自定义颜色', style: Theme.of(context).textTheme.titleLarge),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  void _showCustomColorPicker(BuildContext context) {
    Color currentColor = _color.isNotEmpty && _color != '#CUSTOM' 
        ? Color(int.parse(_color.replaceFirst('#', '0xFF')))
        : Colors.blue;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('自定义颜色'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // RGB Sliders
              StatefulBuilder(
                builder: (context, setDialogState) {
                  return Column(
                    children: [
                      // Red
                      Row(
                        children: [
                          const Text('R'),
                          Expanded(
                            child: Slider(
                              value: currentColor.red.toDouble(),
                              min: 0,
                              max: 255,
                              activeColor: Colors.red,
                              onChanged: (v) {
                                setDialogState(() {
                                  currentColor = Color.fromARGB(255, v.round(), currentColor.green, currentColor.blue);
                                });
                              },
                            ),
                          ),
                          SizedBox(width: 30, child: Text('${currentColor.red}')),
                        ],
                      ),
                      // Green
                      Row(
                        children: [
                          const Text('G'),
                          Expanded(
                            child: Slider(
                              value: currentColor.green.toDouble(),
                              min: 0,
                              max: 255,
                              activeColor: Colors.green,
                              onChanged: (v) {
                                setDialogState(() {
                                  currentColor = Color.fromARGB(255, currentColor.red, v.round(), currentColor.blue);
                                });
                              },
                            ),
                          ),
                          SizedBox(width: 30, child: Text('${currentColor.green}')),
                        ],
                      ),
                      // Blue
                      Row(
                        children: [
                          const Text('B'),
                          Expanded(
                            child: Slider(
                              value: currentColor.blue.toDouble(),
                              min: 0,
                              max: 255,
                              activeColor: Colors.blue,
                              onChanged: (v) {
                                setDialogState(() {
                                  currentColor = Color.fromARGB(255, currentColor.red, currentColor.green, v.round());
                                });
                              },
                            ),
                          ),
                          SizedBox(width: 30, child: Text('${currentColor.blue}')),
                        ],
                      ),
                      // Preview
                      Container(
                        width: double.infinity,
                        height: 50,
                        margin: const EdgeInsets.only(top: 16),
                        decoration: BoxDecoration(
                          color: currentColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final hex = '#${currentColor.value.toRadixString(16).substring(2).toUpperCase()}';
                setState(() => _color = hex);
                Navigator.pop(context);
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }
}
