import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

class TimerClock extends StatelessWidget {
  const TimerClock({
    super.key,
    required this.progress,
    required this.label,
    this.sublabel,
    this.paused = false,
    this.size = 240,
  });

  final double progress;
  final String label;
  final String? sublabel;
  final bool paused;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = progress.clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _TimerClockPainter(progress: t, paused: paused),
        child: Center(
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
    );
  }
}

class _TimerClockPainter extends CustomPainter {
  const _TimerClockPainter({required this.progress, required this.paused});

  final double progress;
  final bool paused;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final accent = paused ? AppColors.muted : AppColors.pink;
    final track = Paint()
      ..color = AppColors.blush
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius - 10, track);

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

    if (progress > 0) {
      final sweep = progress * math.pi * 2;
      final arc = Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 10),
        -math.pi / 2,
        sweep,
        false,
        arc,
      );
      final handAngle = -math.pi / 2 + sweep;
      final hand =
          center +
          Offset(math.cos(handAngle), math.sin(handAngle)) * (radius - 10);
      canvas.drawCircle(hand, 8, Paint()..color = accent);
      canvas.drawCircle(hand, 3.5, Paint()..color = Colors.white);
    }

    canvas.drawCircle(center, 6, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(covariant _TimerClockPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.paused != paused;
  }
}
