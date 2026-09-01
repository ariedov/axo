import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config.dart';
import '../data/game_round.dart';
import '../data/shuffled_deck.dart';
import '../data/times_tables_problem.dart';
import '../state/habit_scope.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets/answer_flash.dart';
import '../widgets/axolotl_mascot.dart';
import '../widgets/game_keypad.dart';
import '../widgets/game_round_summary.dart';
import '../widgets/game_scaffold.dart';
import '../widgets/game_score_bar.dart';
import '../widgets/game_setup_body.dart';

class TimesTablesScreen extends StatefulWidget {
  const TimesTablesScreen({super.key});

  @override
  State<TimesTablesScreen> createState() => _TimesTablesScreenState();
}

class _TimesTablesScreenState extends State<TimesTablesScreen> {
  final _random = Random();
  final _round = GameRound();
  late ShuffledDeck<TimesTablesProblem> _deck;
  var _min = AppConfig.timesTablesMin;
  var _max = AppConfig.timesTablesMax;
  var _a = 2;
  var _b = 3;
  var _input = '';
  var _misses = 0;
  var _mood = AxolotlMood.happy;
  var _busy = false;
  var _showSummary = false;
  var _roundPoints = 0;
  var _playing = false;

  int get _answer => _a * _b;

  bool get _infinite =>
      HabitScope.of(context).playsLeft(AppConfig.timesTablesGame) <= 0;

  int get _roundReward {
    if (_min == 1 && _max == 5) return AppConfig.timesTablesEasyPoints;
    if (_min == 6 && _max == 10) return AppConfig.timesTablesHardPoints;
    return AppConfig.timesTablesNormalPoints;
  }

  void _setRange(int min, int max) {
    if (min == _min && max == _max) return;
    setState(() {
      _min = min;
      _max = max;
    });
  }

  void _next() {
    final problem = _deck.next();
    setState(() {
      _a = problem.a;
      _b = problem.b;
      _input = '';
      _misses = 0;
      _mood = AxolotlMood.happy;
      _busy = false;
    });
  }

  void _start() {
    _round.reset();
    _roundPoints = 0;
    _showSummary = false;
    _playing = true;
    _deck = ShuffledDeck(
      items: TimesTablesProblem.all(_min, _max),
      random: _random,
    );
    _next();
  }

  void _continueAfterRound() {
    setState(() {
      _playing = false;
      _showSummary = false;
      _round.reset();
      _roundPoints = 0;
    });
  }

  Future<void> _finishItem(bool success) async {
    _round.record(success);
    if (!_infinite && _round.isComplete) {
      _roundPoints = await HabitScope.of(context)
          .tryAwardGamePlay(AppConfig.timesTablesGame, points: _roundReward);
      if (!mounted) return;
      setState(() {
        _showSummary = true;
        _busy = false;
        _mood = AxolotlMood.celebrate;
      });
      return;
    }
    _next();
  }

  void _digit(String digit) {
    if (_busy || _showSummary || _input.length >= 4) return;
    setState(() {
      _input += digit;
    });
  }

  void _backspace() {
    if (_busy || _showSummary || _input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  Future<void> _check() async {
    if (_busy || _showSummary) return;
    final value = int.tryParse(_input);
    if (value == null) return;

    if (value == _answer) {
      HapticFeedback.mediumImpact();
      setState(() {
        _busy = true;
        _mood = AxolotlMood.celebrate;
      });
      await showAnswerFlash(context);
      if (!mounted) return;
      await _finishItem(true);
      return;
    }

    HapticFeedback.heavyImpact();
    final misses = _misses + 1;
    setState(() {
      _misses = misses;
      _mood = AxolotlMood.cheer;
      _busy = true;
      _input = '';
    });
    await showAnswerFlash(
      context,
      message: misses >= 2 ? 'Було $_answer. ${S.keepGoing}' : S.tryAgain,
      success: false,
      hold: Duration(milliseconds: misses >= 2 ? 1100 : 700),
    );
    if (!mounted) return;
    if (misses >= 2) {
      await _finishItem(false);
    } else {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: S.timesTables,
      mood: _mood,
      footer: !_playing || _showSummary
          ? null
          : Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: GameKeypad(
                onDigit: _digit,
                onBackspace: _backspace,
                onCheck: _check,
              ),
            ),
      child: _showSummary
          ? GameRoundSummary(
              correct: _round.correct,
              wrong: _round.wrong,
              points: _roundPoints,
              gameId: AppConfig.timesTablesGame,
              onContinue: _continueAfterRound,
            )
          : !_playing
          ? GameSetupBody(
              gameId: AppConfig.timesTablesGame,
              onStart: _start,
              options: [
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    GameModeChip(
                      selected: _min == 1 && _max == 5,
                      onTap: () => _setRange(1, 5),
                      points: AppConfig.timesTablesEasyPoints,
                      child: const Text(S.easy),
                    ),
                    GameModeChip(
                      selected: _min == 1 && _max == 10,
                      onTap: () => _setRange(1, 10),
                      points: AppConfig.timesTablesNormalPoints,
                      child: const Text(S.normal),
                    ),
                    GameModeChip(
                      selected: _min == 6 && _max == 10,
                      onTap: () => _setRange(6, 10),
                      points: AppConfig.timesTablesHardPoints,
                      child: const Text(S.hard),
                    ),
                  ],
                ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                GameScoreBar(round: _round, infinite: _infinite),
                const SizedBox(height: 12),
                Text(
                  '$_a  ×  $_b',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _input.isEmpty ? '?' : _input,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: AppColors.pinkDark,
                  ),
                ),
              ],
            ),
    );
  }
}
