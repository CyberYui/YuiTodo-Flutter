import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/date/date_utils.dart';
import '../../models/focus_session.dart';
import '../../models/task.dart';
import '../../providers/focus_provider.dart';
import '../../providers/occurrence_provider.dart';

/// Focus mode: timer / stopwatch with pause, rest and records.
class FocusScreen extends ConsumerStatefulWidget {
  final Task? task;

  const FocusScreen({super.key, this.task});

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> {
  int _mode = FocusMode.timer;
  int _minutes = 25;
  Task? _task;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final runtime = ref.watch(focusProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('专注')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (!runtime.hasSession) _buildSetup(theme) else _buildActive(theme, runtime),
          const SizedBox(height: 28),
          _buildRecords(theme),
        ],
      ),
    );
  }

  Widget _buildSetup(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: FocusMode.timer, label: Text('计时')),
            ButtonSegment(value: FocusMode.stopwatch, label: Text('秒表')),
          ],
          selected: {_mode},
          onSelectionChanged: (s) => setState(() => _mode = s.first),
        ),
        const SizedBox(height: 20),
        if (_mode == FocusMode.timer) ...[
          Row(
            children: [
              Text('时长', style: theme.textTheme.titleSmall),
              const Spacer(),
              Text('$_minutes 分钟', style: theme.textTheme.titleMedium),
            ],
          ),
          Slider(
            value: _minutes.toDouble(),
            min: 5,
            max: 240,
            divisions: 47,
            label: '$_minutes 分钟',
            onChanged: (v) => setState(() => _minutes = (v / 5).round() * 5),
          ),
        ] else
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('秒表会正向计时，结束时可保存本次专注记录。'),
          ),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.task_alt),
          title: Text(_task?.title ?? '无关联任务'),
          subtitle: Text(_task == null ? '点击选择要专注的任务' : '专注结束后可回到该任务'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _pickTask,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text('开始专注'),
            onPressed: _start,
          ),
        ),
      ],
    );
  }

  Widget _buildActive(ThemeData theme, FocusRuntime runtime) {
    final isTimer = runtime.mode == FocusMode.timer;
    final displaySeconds =
        isTimer ? runtime.remainingSeconds : runtime.elapsed.inSeconds;
    final label = runtime.isResting
        ? '休息中'
        : runtime.isFinished
            ? '本次完成'
            : runtime.isPaused
                ? '已暂停'
                : '专注中';

    return Column(
      children: [
        if (runtime.focusName != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              runtime.focusName!,
              style: theme.textTheme.titleMedium,
            ),
          ),
        SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 220,
                height: 220,
                child: CircularProgressIndicator(
                  value: runtime.progress,
                  strokeWidth: 10,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatDuration(displaySeconds),
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(label, style: theme.textTheme.bodyMedium),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        if (!runtime.isFinished)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!runtime.isResting)
                OutlinedButton.icon(
                  icon: TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: runtime.isPaused ? 0 : 1,
                      end: runtime.isPaused ? 0 : 1,
                    ),
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => AnimatedIcon(
                      icon: AnimatedIcons.play_pause,
                      progress: AlwaysStoppedAnimation<double>(value),
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  label: Text(runtime.isPaused ? '继续' : '暂停'),
                  onPressed: runtime.isPaused
                      ? () => ref.read(focusProvider.notifier).resume()
                      : () => ref.read(focusProvider.notifier).pause(),
                ),
              const SizedBox(width: 12),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                ),
                icon: const Icon(Icons.stop),
                label: const Text('结束'),
                onPressed: () async {
                  await ref.read(focusProvider.notifier).endEarly();
                  ref.invalidate(focusSessionsProvider);
                },
              ),
            ],
          ),
        if (runtime.isFinished) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!runtime.isResting)
                FilledButton.icon(
                  icon: const Icon(Icons.coffee),
                  label: const Text('休息一下'),
                  onPressed: () => ref.read(focusProvider.notifier).startRest(),
                )
              else
                FilledButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('结束休息'),
                  onPressed: () async {
                    await ref.read(focusProvider.notifier).endRest();
                  },
                ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('再来一次'),
                onPressed: () {
                  ref.read(focusProvider.notifier).reset();
                  ref.invalidate(focusSessionsProvider);
                },
              ),
            ],
          ),
          if (runtime.restCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '已休息 ${runtime.restCount} 次 · ${_formatDuration(runtime.restTotal.inSeconds)}',
                style: theme.textTheme.bodySmall,
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildRecords(ThemeData theme) {
    final async = ref.watch(focusSessionsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('专注记录', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        async.when(
          data: (sessions) {
            if (sessions.isEmpty) {
              return Text(
                '还没有专注记录',
                style: TextStyle(color: theme.colorScheme.outline),
              );
            }
            return Column(
              children: sessions.take(10).map((s) {
                final date = DateTime.fromMillisecondsSinceEpoch(s.startTime);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    s.mode == FocusMode.timer ? Icons.timer : Icons.hourglass_bottom,
                  ),
                  title: Text(
                    '${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                  ),
                  subtitle: Text(s.focusName ?? '无关联任务'),
                  trailing: Text(
                    '${_formatDuration(s.actualDuration)} · ${_statusLabel(s.status)}',
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(8),
            child: LinearProgressIndicator(),
          ),
          error: (e, _) => Text('加载失败: $e'),
        ),
      ],
    );
  }

  Future<void> _pickTask() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final occs = await ref.read(taskDateQueryEngineProvider).queryRange(
          today,
          today,
          includeAllNonRecurring: true,
        );
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: const Icon(Icons.clear),
                title: const Text('无关联任务'),
                onTap: () {
                  setState(() => _task = null);
                  Navigator.pop(ctx);
                },
              ),
              ...occs.map(
                (o) => ListTile(
                  leading: const Icon(Icons.task_alt),
                  title: Text(o.task.title),
                  subtitle: Text(o.isDone ? '已完成' : '待完成'),
                  onTap: () {
                    setState(() => _task = o.task);
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _start() async {
    await ref.read(focusProvider.notifier).start(
          mode: _mode,
          targetSeconds: _mode == FocusMode.timer ? _minutes * 60 : 0,
          taskId: _task?.id,
          focusName: _task?.title,
        );
  }

  String _formatDuration(int seconds) {
    final d = Duration(seconds: seconds);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _statusLabel(int status) {
    switch (status) {
      case FocusStatus.onTime:
        return '按时完成';
      case FocusStatus.endedEarly:
        return '提前结束';
      case FocusStatus.interrupted:
        return '被打断';
      default:
        return '进行中';
    }
  }
}
