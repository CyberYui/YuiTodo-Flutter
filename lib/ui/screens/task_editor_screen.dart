import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/task.dart';
import '../../models/recurrence_rule.dart';
import '../../providers/task_provider.dart';
import '../../providers/tag_provider.dart';
import '../../core/icons/app_icons.dart';
import '../../core/icons/flat_icon_mapper.dart';
import '../../core/notifications/reminder_sounds.dart';
import '../../core/theme/task_colors.dart';
import '../../core/utils/recurrence.dart';
import '../../core/utils/reminder_scheduler.dart';
import '../widgets/recurrence_selector.dart';
import '../widgets/reminder_selector.dart';
import '../widgets/reminder_sound_picker.dart';
import '../widgets/icon_picker.dart';
import '../widgets/help_icon.dart';
import '../../repositories/task_repository.dart';
import '../../services/notification_service.dart';

class TaskEditorScreen extends ConsumerStatefulWidget {
  final Task? task;
  final String? initialTitle;

  const TaskEditorScreen({super.key, this.task, this.initialTitle});

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
  int? _reminderTime;
  String? _reminderSound;
  List<TaskReminder> _reminders = [];
  bool _extrasLoaded = false;
  bool _showCustomPaletteIcon = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.task?.title ?? widget.initialTitle ?? '',
    );
    _noteController = TextEditingController(text: widget.task?.note ?? '');
    _stepController = TextEditingController();

    if (widget.task != null) {
      _startDate = DateTime.fromMillisecondsSinceEpoch(
        widget.task!.startDate ??
            widget.task!.startTime ??
            DateTime.now().millisecondsSinceEpoch,
      );
      _endDate = DateTime.fromMillisecondsSinceEpoch(
        widget.task!.endTime ??
            DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch,
      );
      _color = widget.task!.color;
      _icon = widget.task!.icon;
      _steps = widget.task!.steps.toList();
      _selectedTags = widget.task!.tags.toList();
      _reminderTime = widget.task!.reminderTime;
      _reminderSound = widget.task!.reminderSound;
      _loadExtras();
    }
  }

  Future<void> _loadExtras() async {
    final id = widget.task?.id;
    if (id == null) return;
    final repo = ref.read(taskRepositoryProvider);
    final rules = await repo.getRecurrenceRuleMap();
    final reminders = await repo.getRemindersForTask(id);
    if (!mounted) return;
    final rule = rules[id];
    setState(() {
      if (rule != null) {
        _recurrenceType = RecurrenceType.values.firstWhere(
          (t) => t.name == rule.type,
          orElse: () => RecurrenceType.none,
        );
        _recurrenceInterval = rule.interval;
      }
      _reminders = reminders;
      _extrasLoaded = true;
    });
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
      _steps.add(
        TaskStep(
          taskId: widget.task?.id ?? 0,
          title: text,
          sortOrder: _steps.length,
        ),
      );
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

  Future<void> _showReminderSoundPicker(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => ReminderSoundPicker(
        selectedKey: _reminderSound,
        onSelected: (key) => setState(() => _reminderSound = key),
      ),
    );
  }

  Future<void> _saveTask() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请输入任务标题')));
      return;
    }

    // Never wipe stored extras when the editor is saved before the async load
    // finishes (the load is fast, but this closes the race).
    if (widget.task != null && !_extrasLoaded) {
      await _loadExtras();
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
      recurrenceId: null,
      isStarred: widget.task?.isStarred ?? false,
      sortOrder: widget.task?.sortOrder ?? 0,
      createdAt: widget.task?.createdAt ?? now,
      updatedAt: now,
      reminderTime: _reminderTime,
      reminderSound: _reminderSound,
    );

    try {
      int taskId;
      if (widget.task == null) {
        taskId = await ref.read(taskRepositoryProvider).createTask(task);
        final repo = ref.read(taskRepositoryProvider);
        for (int i = 0; i < _steps.length; i++) {
          await repo.createStep(
            TaskStep(
              taskId: taskId,
              title: _steps[i].title,
              sortOrder: i,
              status: _steps[i].status,
            ),
          );
        }
        for (final tag in _selectedTags) {
          if (tag.id != null) {
            await repo.addTagToTask(taskId, tag.id!);
          }
        }
        // Create recurrence rule if recurring. The rule lives in its own
        // table; the task itself stays a single template row.
        if (_recurrenceType != RecurrenceType.none) {
          await repo.createRecurrenceRule(RecurrenceRule(
            taskId: taskId,
            type: _recurrenceType.name,
            interval: _recurrenceInterval,
            createdAt: now,
          ));
        }
        await ref.read(taskListProvider.notifier).loadTasks();
      } else {
        await ref.read(taskListProvider.notifier).updateTask(task);
        taskId = task.id!;
        final repo = ref.read(taskRepositoryProvider);

        // Keep existing step ids so per-occurrence history survives edits.
        // Removed steps are deleted; existing steps are updated in place.
        final existingSteps = await repo.getStepsForTask(taskId);
        final incomingIds =
            _steps.where((s) => s.id != null).map((s) => s.id!).toSet();
        for (final step in existingSteps) {
          if (step.id != null && !incomingIds.contains(step.id)) {
            await repo.deleteStep(step.id!);
          }
        }
        for (int i = 0; i < _steps.length; i++) {
          final step = _steps[i];
          if (step.id != null) {
            await repo.updateStep(TaskStep(
              id: step.id,
              taskId: taskId,
              title: step.title,
              sortOrder: i,
              status: step.status,
            ));
          } else {
            await repo.createStep(TaskStep(
              taskId: taskId,
              title: step.title,
              sortOrder: i,
              status: step.status,
            ));
          }
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

        // Sync the recurrence rule with the editor state.
        final rules = await repo.getRecurrenceRuleMap();
        final existingRule = rules[taskId];
        if (_recurrenceType == RecurrenceType.none) {
          if (existingRule != null) {
            await repo.deleteRecurrenceRule(existingRule.id!);
          }
        } else if (existingRule == null) {
          await repo.createRecurrenceRule(RecurrenceRule(
            taskId: taskId,
            type: _recurrenceType.name,
            interval: _recurrenceInterval,
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ));
        } else {
          await repo.updateRecurrenceRule(existingRule.copyWith(
            type: _recurrenceType.name,
            interval: _recurrenceInterval,
          ));
        }

        await ref.read(taskListProvider.notifier).loadTasks();
      }
      await ref
          .read(taskRepositoryProvider)
          .replaceTaskReminders(taskId, _reminders);
      if (mounted) Navigator.pop(context);

      // Schedule notifications after pop (fire-and-forget). Recurring tasks
      // get their next 7 occurrences pre-scheduled.
      if (_reminderTime != null || _reminders.isNotEmpty) {
        final rulesMap =
            await ref.read(taskRepositoryProvider).getRecurrenceRuleMap();
        _scheduleNotification(taskId, task, rulesMap[taskId], _reminders);
      } else {
        await NotificationService.instance.cancelTaskReminders(taskId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    }
  }

  Future<void> _scheduleNotification(
    int taskId,
    Task task,
    RecurrenceRule? rule,
    List<TaskReminder> extras,
  ) async {
    try {
      final hasPermission =
          await NotificationService.instance.requestPermission();
      if (!hasPermission) return;

      final now = DateTime.now();
      final anchor = DateTime.fromMillisecondsSinceEpoch(
        task.startDate ?? task.startTime ?? task.createdAt,
      );

      final primaryTimes = <DateTime>[];
      final reminder = task.reminderTime;
      final reminderDate = reminder == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(reminder);
      if (reminderDate != null) {
        primaryTimes.addAll(
          ReminderScheduler.reminderTimes(
            anchor: anchor,
            reminderDate: reminderDate,
            rule: rule,
            now: now,
          ),
        );
      }

      final extraTimes = <List<DateTime>>[];
      final extraOffsets = <int>[];
      for (final extra in extras) {
        final offset = extra.offsetMinutes;
        if (offset == null || reminderDate == null) continue;
        extraOffsets.add(offset);
        extraTimes.add(
          ReminderScheduler.offsetReminderTimes(
            anchor: anchor,
            reminderDate: reminderDate,
            offsetMinutes: offset,
            rule: rule,
            now: now,
          ),
        );
      }

      if (primaryTimes.isEmpty && extraTimes.every((times) => times.isEmpty)) {
        await NotificationService.instance.cancelTaskReminders(taskId);
        return;
      }

      final color = Color(int.parse(task.color.replaceFirst('#', '0xFF')));
      final bigText = task.note.isNotEmpty ? task.note : '任务提醒';
      await NotificationService.instance.scheduleTaskReminders(
        taskId: taskId,
        title: task.title,
        body: '任务提醒',
        primaryTimes: primaryTimes,
        extraTimes: extraTimes,
        extraOffsets: extraOffsets,
        recurring: rule != null,
        soundKey: _reminderSound,
        color: color,
        bigText: bigText,
      );
    } catch (e) {
      debugPrint('Failed to schedule notification: $e');
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
                const SizedBox(height: 10),
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: '备注',
                    hintText: '添加备注（可选）',
                    prefixIcon: Icon(Icons.notes),
                    alignLabelWithHint: true,
                  ),
                  minLines: 1,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textAlignVertical: TextAlignVertical.top,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Date section - disabled when recurrence is active
          _buildSection(
            title: '日期',
            titleWidget: Row(
              children: [
                const Text('日期'),
                const SizedBox(width: 4),
                HelpIcon(
                  text: '设置任务的开始和结束日期。\n\n注意：如果选择了重复规则，日期选择将被禁用。',
                  size: 14,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    dense: true,
                    title: const Text('开始日期'),
                    subtitle: Text(
                      '${_startDate.year}-${_startDate.month}-${_startDate.day}',
                    ),
                    enabled: _recurrenceType == RecurrenceType.none,
                    onTap: _recurrenceType == RecurrenceType.none
                        ? () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _startDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (date != null) setState(() => _startDate = date);
                          }
                        : null,
                  ),
                ),
                Expanded(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    dense: true,
                    title: const Text('结束日期'),
                    subtitle: Text(
                      '${_endDate.year}-${_endDate.month}-${_endDate.day}',
                    ),
                    enabled: _recurrenceType == RecurrenceType.none,
                    onTap: _recurrenceType == RecurrenceType.none
                        ? () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _endDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (date != null) setState(() => _endDate = date);
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ==================== 颜色选择区块 ====================
          _buildSection(
            title: '颜色',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 当前选中颜色预览：显示当前任务颜色的圆形色块 + 十六进制值
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(int.parse(_color.replaceFirst('#', '0xFF')))
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Color(int.parse(_color.replaceFirst('#', '0xFF')))
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      // 圆形色块：显示当前选中颜色
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Color(
                            int.parse(_color.replaceFirst('#', '0xFF')),
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 十六进制颜色值文本
                      Expanded(child: Text('已选择: $_color')),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // 颜色调色盘：显示所有可选颜色（16色 + 1自定义槽位）
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: TaskColors.all.map((c) {
                    // 判断当前颜色是否被选中（包括自定义颜色槽位）
                    final isSelected =
                        _color == c ||
                        (TaskColors.isCustom(c) &&
                            _color.isNotEmpty &&
                            _color != '#CUSTOM');
                    final isCustom = TaskColors.isCustom(c);
                    // 自定义槽位颜色：如果已有自定义颜色则显示该颜色，否则显示灰色占位
                    final color = isCustom
                        ? (_color.isNotEmpty && _color != '#CUSTOM'
                              ? TaskColors.fromHex(_color)
                              : Colors.grey.withValues(alpha: 0.3))
                        : Color(int.parse(c.replaceFirst('#', '0xFF')));
                    return GestureDetector(
                      onTap: () {
                        if (isCustom) {
                          // 点击自定义槽位：如果调色盘图标已显示，则打开调色盘；否则显示调色盘图标
                          if (_showCustomPaletteIcon) {
                            _showCustomColorPicker(context);
                          } else {
                            setState(() => _showCustomPaletteIcon = true);
                          }
                        } else {
                          // 点击普通颜色：直接选中，重置自定义槽位状态
                          setState(() {
                            _color = c;
                            _showCustomPaletteIcon = false;
                          });
                        }
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(
                                  color: theme.colorScheme.outline,
                                  width: 3,
                                )
                              : Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: isCustom
                            ? (_showCustomPaletteIcon
                                  ? const Icon(
                                      Icons.palette,
                                      color: Colors.white,
                                      size: 18,
                                    )
                                  : (_color.isNotEmpty && _color != '#CUSTOM'
                                        ? (isSelected
                                              ? const Icon(
                                                  Icons.check,
                                                  color: Colors.white,
                                                  size: 18,
                                                )
                                              : const Icon(
                                                  Icons.palette,
                                                  color: Colors.white,
                                                  size: 18,
                                                ))
                                        : const Icon(
                                            Icons.color_lens,
                                            color: Colors.white,
                                            size: 18,
                                          )))
                            : (isSelected
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 18,
                                    )
                                  : null),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Icon section
          _buildSection(
            title: '图标',
            child: GestureDetector(
              onTap: () => _showIconPicker(context),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    if (_icon != null)
                      AppIcons.isAvatar(_icon!)
                          ? Image.asset(
                              'assets/icons/$_icon.png',
                              width: 40,
                              height: 40,
                            )
                          : Icon(FlatIconMapper.getIcon(_icon!), size: 40)
                    else
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.add_photo_alternate,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(_icon == null ? '选择图标' : '当前: $_icon'),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

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
                      final isSelected = _selectedTags.any(
                        (t) => t.id == tag.id,
                      );
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
                  error: (_, _) => const Text('加载标签失败'),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // Recurrence section
          _buildSection(
            title: '重复',
            titleWidget: Row(
              children: [
                const Text('重复'),
                const SizedBox(width: 4),
                HelpIcon(
                  text: '设置任务重复规则。\n\n注意：重复任务与起止日期互斥，选择重复后将自动清除结束日期。',
                  size: 14,
                ),
              ],
            ),
            child: RecurrenceSelector(
              type: _recurrenceType,
              interval: _recurrenceInterval,
              onTypeChanged: (t) {
                setState(() {
                  _recurrenceType = t;
                  if (t != RecurrenceType.none) {
                    // Switching to recurring: clear end date, set start to today
                    _startDate = DateTime.now();
                    _endDate = DateTime.now().add(const Duration(days: 1));
                  }
                });
              },
              onIntervalChanged: (i) => setState(() => _recurrenceInterval = i),
            ),
          ),
          const SizedBox(height: 10),

          // Reminder section
          _buildSection(
            title: '提醒',
            titleWidget: Row(
              children: [
                const Text('提醒'),
                const SizedBox(width: 4),
                HelpIcon(
                  text: '设置任务提醒时间。\n\n'
                      '可添加多个「提前 X 分钟」提醒，按任务开始时间计算；'
                      '重复任务按每次发生计算。\n\n'
                      '需要开启通知权限才能正常收到提醒。',
                  size: 14,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReminderSelector(
                  reminderTime: _reminderTime,
                  reminders: _reminders,
                  isRecurring: _recurrenceType != RecurrenceType.none,
                  onReminderTimeChanged: (time) =>
                      setState(() => _reminderTime = time),
                  onRemindersChanged: (list) =>
                      setState(() => _reminders = list),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.music_note_outlined),
                  title: const Text('提醒铃声'),
                  subtitle: Text(reminderSoundFor(_reminderSound).label),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showReminderSoundPicker(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Steps section
          _buildSection(
            title: '子任务',
            child: Column(
              children: [
                if (_recurrenceType != RecurrenceType.none)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '子任务完成状态按天记录，请在任务列表勾选',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                  ),
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _steps.length,
                  onReorderItem: (oldIndex, newIndex) {
                    setState(() {
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
                            child: Icon(
                              Icons.drag_handle,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _recurrenceType == RecurrenceType.none
                                ? () => _toggleStepStatus(index)
                                : null,
                            child: Icon(
                              step.status == 'completed'
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: step.status == 'completed'
                                  ? theme.colorScheme.primary
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      title: Text(
                        step.title,
                        style: TextStyle(
                          decoration: step.status == 'completed'
                              ? TextDecoration.lineThrough
                              : null,
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

  Widget _buildSection({required String title, Widget? titleWidget, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: titleWidget ?? Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: child,
          ),
        ],
      ),
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
                              value: currentColor.r * 255,
                              min: 0,
                              max: 255,
                              activeColor: Colors.red,
                              onChanged: (v) {
                                setDialogState(() {
                                  currentColor = Color.fromARGB(
                                    255,
                                    v.round(),
                                    (currentColor.g * 255).round(),
                                    (currentColor.b * 255).round(),
                                  );
                                });
                              },
                            ),
                          ),
                          SizedBox(
                            width: 30,
                            child: Text('${(currentColor.r * 255).round()}'),
                          ),
                        ],
                      ),
                      // Green
                      Row(
                        children: [
                          const Text('G'),
                          Expanded(
                            child: Slider(
                              value: currentColor.g * 255,
                              min: 0,
                              max: 255,
                              activeColor: Colors.green,
                              onChanged: (v) {
                                setDialogState(() {
                                  currentColor = Color.fromARGB(
                                    255,
                                    (currentColor.r * 255).round(),
                                    v.round(),
                                    (currentColor.b * 255).round(),
                                  );
                                });
                              },
                            ),
                          ),
                          SizedBox(
                            width: 30,
                            child: Text('${(currentColor.g * 255).round()}'),
                          ),
                        ],
                      ),
                      // Blue
                      Row(
                        children: [
                          const Text('B'),
                          Expanded(
                            child: Slider(
                              value: currentColor.b * 255,
                              min: 0,
                              max: 255,
                              activeColor: Colors.blue,
                              onChanged: (v) {
                                setDialogState(() {
                                  currentColor = Color.fromARGB(
                                    255,
                                    (currentColor.r * 255).round(),
                                    (currentColor.g * 255).round(),
                                    v.round(),
                                  );
                                });
                              },
                            ),
                          ),
                          SizedBox(
                            width: 30,
                            child: Text('${(currentColor.b * 255).round()}'),
                          ),
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
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.3),
                          ),
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
                final hex =
                    '#${currentColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
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
