import 'dart:async';

import 'package:flutter/material.dart';

/// Fade + slide-in wrapper for list items.
///
/// The caller supplies a stable [Key]; when the same key is rebuilt the state
/// (and therefore the finished animation) is preserved, so only newly inserted
/// items animate. A small per-index delay gives a stagger effect on first load.
class AnimatedEntry extends StatefulWidget {
  const AnimatedEntry({
    super.key,
    required this.child,
    this.index = 0,
    this.duration = const Duration(milliseconds: 260),
    this.stagger = const Duration(milliseconds: 22),
    this.maxStagger = const Duration(milliseconds: 220),
  });

  final Widget child;
  final int index;
  final Duration duration;
  final Duration stagger;
  final Duration maxStagger;

  @override
  State<AnimatedEntry> createState() => _AnimatedEntryState();
}

class _AnimatedEntryState extends State<AnimatedEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;
  late final Animation<double> _scale;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(curved);
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.02),
      end: Offset.zero,
    ).animate(curved);
    _scale = Tween<double>(begin: 0.985, end: 1).animate(curved);

    final delayMs = (widget.index * widget.stagger.inMilliseconds)
        .clamp(0, widget.maxStagger.inMilliseconds);
    if (delayMs <= 0) {
      _controller.forward();
    } else {
      _delayTimer = Timer(Duration(milliseconds: delayMs), () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: ScaleTransition(scale: _scale, child: widget.child),
      ),
    );
  }
}
