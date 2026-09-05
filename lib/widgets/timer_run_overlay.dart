import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/screen_wake.dart';
import '../data/timer_repository.dart';
import '../state/habit_scope.dart';
import '../strings.dart';
import '../theme.dart';
import 'axolotl_mascot.dart';
import 'timer_clock.dart';

Future<void> showTimerRunDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: AppColors.peach,
    builder: (context) => const TimerRunOverlay(),
  );
}

class TimerRunOverlay extends StatefulWidget {
  const TimerRunOverlay({super.key});

  @override
  State<TimerRunOverlay> createState() => _TimerRunOverlayState();
}

class _TimerRunOverlayState extends State<TimerRunOverlay> {
  Timer? _ticker;
  var _done = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) => _tick());
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncWake());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    unawaited(setScreenWake(false));
    super.dispose();
  }

  Future<void> _tick() async {
    if (!mounted || _done) return;
    final store = HabitScope.of(context);
    if (store.timerFinished) {
      HapticFeedback.mediumImpact();
      await store.completeTimer();
      if (!mounted) return;
      setState(() => _done = true);
      await setScreenWake(false);
      return;
    }
    setState(() {});
    await _syncWake();
  }

  Future<void> _syncWake() {
    if (_done) return setScreenWake(false);
    final active = HabitScope.of(context).activeTimer;
    return setScreenWake(active != null && active.isRunning);
  }

  Future<void> _pause() async {
    await HabitScope.of(context).pauseTimer();
    await setScreenWake(false);
    if (mounted) setState(() {});
  }

  Future<void> _resume() async {
    await HabitScope.of(context).resumeTimer();
    await setScreenWake(true);
    if (mounted) setState(() {});
  }

  Future<void> _close() {
    return setScreenWake(false).whenComplete(() {
      if (mounted) Navigator.pop(context);
    });
  }

  Future<void> _abandon() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text(S.timerAbandonTitle),
        content: const Text(S.timerAbandonBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(S.cancel),
          ),
          FilledButton(
            key: const Key('timer-abandon-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(S.timerAbandon),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await HabitScope.of(context).abandonTimer();
    await _close();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return _DoneBody(onClose: _close);
    }

    final store = HabitScope.of(context);
    final active = store.activeTimer;
    if (active == null) return const SizedBox.shrink();

    final elapsed = active.elapsedAt(store.now());
    final target = active.target;
    final progress = target.inMilliseconds == 0
        ? 1.0
        : elapsed.inMilliseconds / target.inMilliseconds;
    final paused = active.status == TimerStatus.paused;
    final reason = active.reason.isEmpty ? null : active.reason;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_abandon());
      },
      child: Dialog.fullscreen(
        backgroundColor: AppColors.peach,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              children: [
                const Text(
                  S.timer,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
                ),
                if (reason != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    reason,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: AppColors.pinkDark,
                    ),
                  ),
                ],
                const Spacer(),
                TimerClock(
                  key: const Key('timer-run-clock'),
                  progress: progress,
                  label: S.countdown(elapsed),
                  sublabel: S.timerOf(
                    S.countdown(elapsed),
                    S.countdown(target),
                  ),
                  paused: paused,
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        key: const Key('timer-abandon'),
                        onPressed: _abandon,
                        child: const Text(S.timerAbandon),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        key: paused
                            ? const Key('timer-resume')
                            : const Key('timer-pause'),
                        onPressed: paused ? _resume : _pause,
                        child: Text(paused ? S.timerResume : S.timerPause),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DoneBody extends StatelessWidget {
  const _DoneBody({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: AppColors.peach,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            children: [
              const Spacer(),
              const AxolotlMascot(mood: AxolotlMood.celebrate, size: 160),
              const SizedBox(height: 12),
              const Text(
                S.timerDone,
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 28),
              ),
              const SizedBox(height: 8),
              const Text(
                S.timerDoneBody,
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const Spacer(),
              FilledButton(
                key: const Key('timer-done'),
                onPressed: onClose,
                child: const Text(S.ok),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
