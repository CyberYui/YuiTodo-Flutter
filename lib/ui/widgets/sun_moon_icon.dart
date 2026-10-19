import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A sun ↔ moon morph driven by [isDark].
///
/// Implemented with a [CustomPainter] rather than a Rive asset: the sun body
/// is a circle with eight rays, and the moon is the same circle minus a "bite"
/// circle that slides in from the upper-right. The geometry is theme-aware and
/// needs no extra dependency.
class SunMoonIcon extends StatefulWidget {
  const SunMoonIcon({
    super.key,
    required this.isDark,
    this.size = 24,
    this.color,
    this.duration = const Duration(milliseconds: 380),
  });

  final bool isDark;
  final double size;
  final Color? color;
  final Duration duration;

  @override
  State<SunMoonIcon> createState() => _SunMoonIconState();
}

class _SunMoonIconState extends State<SunMoonIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _controller.value = widget.isDark ? 1 : 0;
  }

  @override
  void didUpdateWidget(covariant SunMoonIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDark == widget.isDark) return;
    if (widget.isDark) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _progress,
        builder: (context, _) => CustomPaint(
          painter: _SunMoonPainter(
            progress: reduceMotion
                ? (widget.isDark ? 1.0 : 0.0)
                : _progress.value,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _SunMoonPainter extends CustomPainter {
  _SunMoonPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.clamp(0.0, 1.0);
    final center = size.center(Offset.zero);
    final unit = size.shortestSide;
    final bodyRadius = unit * 0.24;
    final paint = Paint()
      ..color = color
      ..isAntiAlias = true;

    // Sun rays fade and shrink as the moon forms. A slight rotation keeps the
    // transition from looking mechanical.
    final rayOpacity = (1 - t).clamp(0.0, 1.0);
    if (rayOpacity > 0.01) {
      final rayPaint = Paint()
        ..color = color.withOpacity(rayOpacity)
        ..strokeWidth = unit * 0.075
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final inner = bodyRadius + unit * 0.10;
      final outer = inner + unit * 0.09 * (1 - t);
      for (var i = 0; i < 8; i++) {
        final angle = i * math.pi / 4 + t * math.pi / 8;
        final direction = Offset(math.cos(angle), math.sin(angle));
        canvas.drawLine(
          center + direction * inner,
          center + direction * outer,
          rayPaint,
        );
      }
    }

    // Moon = body circle minus a bite circle. At t=0 the bite is far outside
    // (full sun disc); at t=1 it cuts the upper-right into a crescent.
    final body = Path()
      ..addOval(Rect.fromCircle(center: center, radius: bodyRadius));
    final biteCenter = center +
        Offset(
          unit * (0.95 - 0.72 * t),
          -unit * (0.10 + 0.10 * t),
        );
    final bite = Path()
      ..addOval(
        Rect.fromCircle(center: biteCenter, radius: bodyRadius * 0.92),
      );
    final moon = Path.combine(PathOperation.difference, body, bite);
    canvas.drawPath(moon, paint);
  }

  @override
  bool shouldRepaint(covariant _SunMoonPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
