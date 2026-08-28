import 'dart:async';

import 'package:flutter/material.dart';

import '../strings.dart';
import '../theme.dart';
import 'axolotl_mascot.dart';

Future<void> showAnswerFlash(
  BuildContext context, {
  String message = S.correct,
  bool success = true,
  Duration hold = const Duration(milliseconds: 700),
}) {
  final overlay = Overlay.of(context);
  final textStyle = DefaultTextStyle.of(context).style;
  final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
  final done = Completer<void>();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => DefaultTextStyle(
      style: textStyle,
      child: Material(
        type: MaterialType.transparency,
        child: _AnswerFlash(
          message: message,
          success: success,
          hold: hold,
          keyboardInset: keyboardInset,
          onDone: () {
            if (entry.mounted) entry.remove();
            if (!done.isCompleted) done.complete();
          },
        ),
      ),
    ),
  );
  overlay.insert(entry);
  return done.future;
}

class _AnswerFlash extends StatefulWidget {
  const _AnswerFlash({
    required this.message,
    required this.success,
    required this.hold,
    required this.keyboardInset,
    required this.onDone,
  });

  final String message;
  final bool success;
  final Duration hold;
  final double keyboardInset;
  final VoidCallback onDone;

  @override
  State<_AnswerFlash> createState() => _AnswerFlashState();
}

class _AnswerFlashState extends State<_AnswerFlash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _run();
  }

  Future<void> _run() async {
    await _fade.forward();
    await Future<void>.delayed(widget.hold);
    if (mounted) {
      await _fade.reverse();
    }
    widget.onDone();
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.success ? AppColors.tealDark : AppColors.pinkDark;
    final scale = Tween<double>(begin: 0.86, end: 1).animate(
      CurvedAnimation(parent: _fade, curve: Curves.easeOutBack),
    );

    return AbsorbPointer(
      child: FadeTransition(
        opacity: _fade,
        child: ColoredBox(
          color: AppColors.peach.withValues(alpha: 0.92),
          child: Padding(
            padding: EdgeInsets.only(bottom: widget.keyboardInset),
            child: Align(
              alignment: widget.keyboardInset > 0
                  ? const Alignment(0, -0.35)
                  : Alignment.center,
              child: ScaleTransition(
                scale: scale,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 320),
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.pink.withValues(alpha: 0.2),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.success)
                        const _AxolotlParty()
                      else
                        Image.asset(
                          AxolotlMascot.cheer,
                          width: 96,
                          height: 96,
                          filterQuality: FilterQuality.high,
                        ),
                      const SizedBox(height: 8),
                      Text(
                        widget.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          inherit: false,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                          height: 1.25,
                          color: color,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AxolotlParty extends StatelessWidget {
  const _AxolotlParty();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: OverflowBox(
        maxWidth: 280,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Transform.translate(
              offset: const Offset(10, 8),
              child: Transform.rotate(
                angle: -0.22,
                child: Image.asset(
                  AxolotlMascot.happy,
                  width: 72,
                  height: 72,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
            Image.asset(
              AxolotlMascot.celebrate,
              width: 112,
              height: 112,
              filterQuality: FilterQuality.high,
            ),
            Transform.translate(
              offset: const Offset(-10, 10),
              child: Transform.rotate(
                angle: 0.2,
                child: Image.asset(
                  AxolotlMascot.cheer,
                  width: 72,
                  height: 72,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
