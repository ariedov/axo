import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config.dart';
import '../data/game_round.dart';
import '../data/memory_deck.dart';
import '../data/simon_sequence.dart';
import '../state/habit_scope.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets/answer_flash.dart';
import '../widgets/axolotl_mascot.dart';
import '../widgets/game_round_summary.dart';
import '../widgets/game_scaffold.dart';
import '../widgets/game_score_bar.dart';
import '../widgets/game_setup_body.dart';

enum _SimonMode { easy, normal, hard }

class SimonScreen extends StatefulWidget {
  const SimonScreen({
    super.key,
    this.random,
    this.pads,
    this.startLength = AppConfig.simonStartLength,
    this.turns = AppConfig.roundLength,
    this.sequence,
    this.stepHold,
    this.gapHold,
    this.missHold = const Duration(milliseconds: 500),
    this.flashHold,
  });

  final Random? random;
  final int? pads;
  final int startLength;
  final int turns;
  final List<int>? sequence;
  final Duration? stepHold;
  final Duration? gapHold;
  final Duration missHold;
  final Duration? flashHold;

  @override
  State<SimonScreen> createState() => _SimonScreenState();
}

class _SimonScreenState extends State<SimonScreen> {
  late final Random _random = widget.random ?? Random();
  final _round = GameRound();
  var _mode = _SimonMode.normal;
  var _sequence = <int>[];
  var _activePads = AppConfig.simonNormalPads;
  var _step = 0;
  var _lit = -1;
  var _demoId = 0;
  var _mood = AxolotlMood.happy;
  var _busy = false;
  var _showSummary = false;
  var _roundPoints = 0;
  var _playing = false;

  bool get _infinite => HabitScope.of(context).gamesLocked;

  int get _pads =>
      widget.pads ??
      (_mode == _SimonMode.easy
          ? AppConfig.simonEasyPads
          : AppConfig.simonNormalPads);

  int get _columns => _activePads == 4 ? 2 : _activePads;

  Duration get _stepHold =>
      widget.stepHold ??
      switch (_mode) {
        _SimonMode.easy => const Duration(milliseconds: 420),
        _SimonMode.normal => const Duration(milliseconds: 340),
        _SimonMode.hard => const Duration(milliseconds: 220),
      };

  Duration get _gapHold =>
      widget.gapHold ??
      switch (_mode) {
        _SimonMode.easy => const Duration(milliseconds: 200),
        _SimonMode.normal => const Duration(milliseconds: 140),
        _SimonMode.hard => const Duration(milliseconds: 80),
      };

  int get _roundReward => switch (_mode) {
    _SimonMode.easy => AppConfig.timesTablesEasyPoints,
    _SimonMode.normal => AppConfig.timesTablesNormalPoints,
    _SimonMode.hard => AppConfig.timesTablesHardPoints,
  };

  void _setMode(_SimonMode mode) {
    if (mode == _mode) return;
    setState(() => _mode = mode);
  }

  void _start() {
    if (HabitScope.of(context).gamesLocked) return;
    _demoId += 1;
    _round.reset();
    _roundPoints = 0;
    _showSummary = false;
    _playing = true;
    _busy = true;
    _step = 0;
    _lit = -1;
    _mood = AxolotlMood.happy;
    _activePads = _pads;
    _sequence = widget.sequence != null
        ? List<int>.from(widget.sequence!)
        : SimonSequence.ofLength(
            widget.startLength,
            _random,
            pads: _activePads,
          );
    setState(() {});
    _playDemo();
  }

  void _continueAfterRound() {
    _demoId += 1;
    setState(() {
      _playing = false;
      _showSummary = false;
      _round.reset();
      _roundPoints = 0;
      _sequence = [];
      _step = 0;
      _lit = -1;
      _busy = false;
    });
  }

  Future<void> _wait(Duration duration) async {
    if (duration == Duration.zero) return;
    await Future<void>.delayed(duration);
  }

  Future<void> _playDemo() async {
    final id = ++_demoId;
    setState(() {
      _busy = true;
      _step = 0;
      _lit = -1;
    });
    if (_stepHold == Duration.zero && _gapHold == Duration.zero) {
      setState(() => _busy = false);
      return;
    }
    await _wait(_gapHold);
    for (final pad in _sequence) {
      if (!mounted || id != _demoId) return;
      HapticFeedback.lightImpact();
      setState(() => _lit = pad);
      await _wait(_stepHold);
      if (!mounted || id != _demoId) return;
      setState(() => _lit = -1);
      await _wait(_gapHold);
    }
    if (!mounted || id != _demoId) return;
    setState(() {
      _busy = false;
      _lit = -1;
    });
  }

  Future<void> _finishItem(bool success) async {
    _round.record(success);
    if (!_infinite && _round.answered >= widget.turns) {
      _roundPoints = await HabitScope.of(context)
          .tryAwardGamePlay(AppConfig.simonGame, points: _roundReward);
      if (!mounted) return;
      setState(() {
        _showSummary = true;
        _busy = false;
        _mood = AxolotlMood.celebrate;
        _lit = -1;
      });
      return;
    }
    if (success) {
      _sequence = SimonSequence.grow(_sequence, _random, pads: _activePads);
      _mood = AxolotlMood.celebrate;
    } else {
      _mood = AxolotlMood.cheer;
    }
    _step = 0;
    setState(() => _lit = -1);
    await _feedback(success: success);
    if (!mounted) return;
    await _playDemo();
  }

  Future<void> _feedback({required bool success}) async {
    final hold = widget.flashHold;
    if (hold == Duration.zero) return;
    await showAnswerFlash(
      context,
      message: success ? S.correct : S.keepGoing,
      success: success,
      hold: hold ?? const Duration(milliseconds: 900),
    );
  }

  Future<void> _pick(int pad) async {
    if (_busy || _showSummary) return;
    if (pad != _sequence[_step]) {
      HapticFeedback.heavyImpact();
      setState(() {
        _busy = true;
        _mood = AxolotlMood.cheer;
        _lit = pad;
      });
      await _wait(widget.missHold);
      if (!mounted) return;
      setState(() => _lit = -1);
      await _finishItem(false);
      return;
    }

    HapticFeedback.selectionClick();
    final next = _step + 1;
    if (next < _sequence.length) {
      setState(() {
        _step = next;
        _lit = pad;
      });
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _busy = true;
      _mood = AxolotlMood.celebrate;
      _lit = pad;
    });
    await _wait(_gapHold);
    if (!mounted) return;
    await _finishItem(true);
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: S.simon,
      mood: _mood,
      showMascot: !_playing || _showSummary,
      child: _showSummary
          ? GameRoundSummary(
              correct: _round.correct,
              wrong: _round.wrong,
              points: _roundPoints,
              onContinue: _continueAfterRound,
            )
          : !_playing
          ? GameSetupBody(
              onStart: _start,
              options: [
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    GameModeChip(
                      selected: _mode == _SimonMode.easy,
                      onTap: () => _setMode(_SimonMode.easy),
                      points: AppConfig.timesTablesEasyPoints,
                      child: const Text(S.easy),
                    ),
                    GameModeChip(
                      selected: _mode == _SimonMode.normal,
                      onTap: () => _setMode(_SimonMode.normal),
                      points: AppConfig.timesTablesNormalPoints,
                      child: const Text(S.normal),
                    ),
                    GameModeChip(
                      selected: _mode == _SimonMode.hard,
                      onTap: () => _setMode(_SimonMode.hard),
                      points: AppConfig.timesTablesHardPoints,
                      child: const Text(S.hard),
                    ),
                  ],
                ),
              ],
            )
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  GameScoreBar(round: _round, infinite: _infinite),
                  const SizedBox(height: 8),
                  Text(
                    _busy ? S.simonWatch : S.simonYourTurn,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _Board(
                      pads: _activePads,
                      columns: _columns,
                      lit: _lit,
                      onPick: _pick,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({
    required this.pads,
    required this.columns,
    required this.lit,
    required this.onPick,
  });

  final int pads;
  final int columns;
  final int lit;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final rows = (pads / columns).ceil();
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        final height = (constraints.maxHeight - gap * (rows - 1)) / rows;
        final size = min(width, height);
        return Center(
          child: SizedBox(
            key: const Key('simon-board'),
            width: size * columns + gap * (columns - 1),
            height: size * rows + gap * (rows - 1),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pads,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: gap,
                mainAxisSpacing: gap,
              ),
              itemBuilder: (context, index) {
                return _Pad(
                  index: index,
                  face: SimonSequence.faces[index],
                  lit: lit == index,
                  onTap: () => onPick(index),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _Pad extends StatelessWidget {
  const _Pad({
    required this.index,
    required this.face,
    required this.lit,
    required this.onTap,
  });

  final int index;
  final MemoryFace face;
  final bool lit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('simon-$index'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: lit ? face.color : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: face.color, width: lit ? 5 : 3),
          ),
          child: Center(
            child: Icon(
              face.icon,
              size: lit ? 48 : 40,
              color: lit ? Colors.white : face.color,
            ),
          ),
        ),
      ),
    );
  }
}
