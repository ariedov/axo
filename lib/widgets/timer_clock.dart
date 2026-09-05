import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config.dart';
import '../theme.dart';

class TimerClock extends StatelessWidget {
  const TimerClock({
    super.key,
    required this.progress,
    required this.label,
    this.sublabel,
    this.paused = false,
    this.size = 240,
    this.maxMinutes = AppConfig.timerMaxMinutes,
    this.onMinutes,
  });

  final double progress;
  final String label;
  final String? sublabel;
  final bool paused;
  final double size;
  final int maxMinutes;
  final ValueChanged<int>? onMinutes;

  bool get _interactive => onMinutes != null;

  static int minutesForOffset(
    Offset local, {
    required double size,
    int min = AppConfig.timerMinMinutes,
    int max = AppConfig.timerMaxMinutes,
  }) {
    final center = Offset(size / 2, size / 2);
    final delta = local - center;
    var angle = math.atan2(delta.dy, delta.dx) + math.pi / 2;
    if (angle < 0) angle += math.pi * 2;
    var minutes = (angle / (math.pi * 2) * max).round();
    if (minutes <= 0 || minutes > max) return max;
    if (minutes < min) return min;
    return minutes;
  }

  void _setFrom(Offset local) {
    final onMinutes = this.onMinutes;
    if (onMinutes == null) return;
    final center = Offset(size / 2, size / 2);
    if ((local - center).distance < size * 0.12) return;
    onMinutes(minutesForOffset(local, size: size, max: maxMinutes));
  }

  @override
  Widget build(BuildContext context) {
    final t = progress.clamp(0.0, 1.0);
    final clock = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _TimerClockPainter(
          progress: t,
          paused: paused,
          showHandle: _interactive,
        ),
        child: Center(
          child: IgnorePointer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: size * 0.18,
                    color: paused ? AppColors.muted : AppColors.ink,
                    height: 1,
                  ),
                ),
                if (sublabel != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    sublabel!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (!_interactive) return clock;

    return GestureDetector(
      onTapDown: (details) => _setFrom(details.localPosition),
      onPanStart: (details) {
        HapticFeedback.selectionClick();
        _setFrom(details.localPosition);
      },
      onPanUpdate: (details) => _setFrom(details.localPosition),
      child: clock,
    );
  }
}

class _TimerClockPainter extends CustomPainter {
  const _TimerClockPainter({
    required this.progress,
    required this.paused,
    required this.showHandle,
  });

  final double progress;
  final bool paused;
  final bool showHandle;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final ringRadius = radius - 10;
    final accent = paused ? AppColors.muted : AppColors.pink;
    final track = Paint()
      ..color = AppColors.blush
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, ringRadius, track);

    for (var i = 0; i < 60; i++) {
      final angle = (i / 60) * math.pi * 2 - math.pi / 2;
      final major = i % 5 == 0;
      final inner = radius - (major ? 28 : 20);
      final outer = radius - 8;
      final paint = Paint()
        ..color = major
            ? AppColors.ink.withValues(alpha: 0.45)
            : AppColors.blush
        ..strokeWidth = major ? 2.4 : 1.2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        center + Offset(math.cos(angle), math.sin(angle)) * inner,
        center + Offset(math.cos(angle), math.sin(angle)) * outer,
        paint,
      );
    }

    if (progress <= 0) return;

    final sweep = progress * math.pi * 2;
    final arc = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: ringRadius),
      -math.pi / 2,
      sweep,
      false,
      arc,
    );

    if (!showHandle) return;
    final handAngle = -math.pi / 2 + sweep;
    final hand =
        center + Offset(math.cos(handAngle), math.sin(handAngle)) * ringRadius;
    canvas.drawCircle(hand, 12, Paint()..color = accent);
    canvas.drawCircle(hand, 5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _TimerClockPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.paused != paused ||
        oldDelegate.showHandle != showHandle;
  }
}
