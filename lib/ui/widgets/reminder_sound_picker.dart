import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/notifications/reminder_sounds.dart';
import '../../core/notifications/sound_preview.dart';

/// Sound picker with in-place previews.
///
/// Tapping a row selects it and starts a preview; tapping it again stops.
/// Tapping another row stops the previous preview before playing the new one.
class ReminderSoundPicker extends StatefulWidget {
  final String? selectedKey;
  final ValueChanged<String?> onSelected;

  const ReminderSoundPicker({
    super.key,
    required this.selectedKey,
    required this.onSelected,
  });

  @override
  State<ReminderSoundPicker> createState() => _ReminderSoundPickerState();
}

class _ReminderSoundPickerState extends State<ReminderSoundPicker>
    with WidgetsBindingObserver {
  late String? _selected = widget.selectedKey;
  final SoundPreview _preview = SoundPreview.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_preview.stop());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      unawaited(_preview.stop());
    }
  }

  void _select(ReminderSoundOption option) {
    setState(() => _selected = option.key);
    widget.onSelected(option.key);
    unawaited(_preview.toggle(option.key));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: ListenableBuilder(
        listenable: _preview,
        builder: (context, _) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '提醒铃声',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              for (final option in reminderSounds)
                ListTile(
                  leading: Icon(
                    option.key == null
                        ? Icons.notifications_active_outlined
                        : Icons.music_note_outlined,
                  ),
                  title: Text(option.label),
                  subtitle:
                      option.key == null ? const Text('使用系统默认通知音') : null,
                  trailing: _preview.isPlaying(option.key)
                      ? PlayingBars(color: theme.colorScheme.primary)
                      : _selected == option.key
                          ? const Icon(Icons.check)
                          : Icon(
                              Icons.play_circle_outline,
                              color: theme.colorScheme.outline,
                            ),
                  onTap: () => _select(option),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  '点击试听，再次点击停止；铃声仅对本任务生效。',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('完成'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small three-bar equalizer used while a preview is playing.
class PlayingBars extends StatefulWidget {
  final Color color;

  const PlayingBars({super.key, required this.color});

  @override
  State<PlayingBars> createState() => _PlayingBarsState();
}

class _PlayingBarsState extends State<PlayingBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 720),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      return Icon(Icons.graphic_eq, color: widget.color, size: 20);
    }
    return Semantics(
      label: '正在试听',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => SizedBox(
          width: 24,
          height: 18,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(3, (index) {
              final phase = (_controller.value + index * 0.22) % 1.0;
              final height =
                  6 + 12 * (0.5 + 0.5 * math.sin(phase * 2 * math.pi));
              return Container(
                width: 3,
                height: height,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
