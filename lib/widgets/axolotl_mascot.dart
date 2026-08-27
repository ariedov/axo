import 'package:flutter/material.dart';

import '../theme.dart';

enum AxolotlMood { happy, cheer, celebrate }

class AxolotlMascot extends StatefulWidget {
  const AxolotlMascot({
    super.key,
    required this.mood,
    this.size = 180,
    this.animate = true,
  });

  final AxolotlMood mood;
  final double size;
  final bool animate;

  static const happy = 'assets/mascot/axolotl_happy.png';
  static const cheer = 'assets/mascot/axolotl_cheer.png';
  static const celebrate = 'assets/mascot/axolotl_celebrate.png';

  @override
  State<AxolotlMascot> createState() => _AxolotlMascotState();
}

class _AxolotlMascotState extends State<AxolotlMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.animate) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  String get _asset => switch (widget.mood) {
    AxolotlMood.celebrate => AxolotlMascot.celebrate,
    AxolotlMood.cheer => AxolotlMascot.cheer,
    AxolotlMood.happy => AxolotlMascot.happy,
  };

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      _asset,
      width: widget.size,
      height: widget.size,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
    );
    if (!widget.animate) return image;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final scale = 0.97 + (_pulse.value * 0.06);
        return Transform.scale(scale: scale, child: child);
      },
      child: image,
    );
  }
}

class SpeechBubble extends StatelessWidget {
  const SpeechBubble({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.pink.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
