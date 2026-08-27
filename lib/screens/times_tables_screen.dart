import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config.dart';
import '../data/game_round.dart';
import '../state/habit_scope.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets/axolotl_mascot.dart';
import '../widgets/game_plays_banner.dart';
import '../widgets/game_round_summary.dart';
import '../widgets/game_scaffold.dart';
import '../widgets/game_score_bar.dart';

class TimesTablesScreen extends StatefulWidget {
  const TimesTablesScreen({super.key});

  @override
  State<TimesTablesScreen> createState() => _TimesTablesScreenState();
}

class _TimesTablesScreenState extends State<TimesTablesScreen> {
  final _random = Random();
  final _round = GameRound();
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
  String? _feedback;

  int get _answer => _a * _b;

  bool get _infinite =>
      HabitScope.of(context).playsLeft(AppConfig.timesTablesGame) <= 0;

  @override
  void initState() {
    super.initState();
    _next();
  }

  void _setRange(int min, int max) {
    if (min == _min && max == _max) return;
    setState(() {
      _min = min;
      _max = max;
    });
  }

  void _next() {
    setState(() {
      _a = _min + _random.nextInt(_max - _min + 1);
      _b = _min + _random.nextInt(_max - _min + 1);
      _input = '';
      _misses = 0;
      _feedback = null;
      _mood = AxolotlMood.happy;
      _busy = false;
    });
  }

  void _continueAfterRound() {
    _round.reset();
    _roundPoints = 0;
    _showSummary = false;
    _next();
  }

  Future<void> _finishItem(bool success) async {
    _round.record(success);
    if (!_infinite && _round.isComplete) {
      _roundPoints = await HabitScope.of(
        context,
      ).tryAwardGamePlay(AppConfig.timesTablesGame);
      if (!mounted) return;
      setState(() {
        _showSummary = true;
        _busy = false;
        _mood = AxolotlMood.celebrate;
        _feedback = null;
      });
      return;
    }
    _next();
  }

  void _digit(String digit) {
    if (_busy || _showSummary || _input.length >= 4) return;
    setState(() {
      _input += digit;
      _feedback = null;
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
        _feedback = S.correct;
      });
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      await _finishItem(true);
      return;
    }

    HapticFeedback.heavyImpact();
    setState(() {
      _misses += 1;
      _mood = AxolotlMood.cheer;
      _feedback = _misses >= 2 ? 'Було $_answer. ${S.tryAgain}' : S.tryAgain;
      _input = '';
    });
    if (_misses >= 2) {
      _busy = true;
      await Future<void>.delayed(const Duration(milliseconds: 1400));
      if (!mounted) return;
      await _finishItem(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: S.timesTables,
      mood: _mood,
      footer: _showSummary
          ? null
          : Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: _Keypad(
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
          : ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const GamePlaysBanner(gameId: AppConfig.timesTablesGame),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RangeChip(
                label: S.easy,
                selected: _min == 1 && _max == 5,
                onTap: () => _setRange(1, 5),
              ),
              _RangeChip(
                label: S.normal,
                selected: _min == 1 && _max == 10,
                onTap: () => _setRange(1, 10),
              ),
              _RangeChip(
                label: S.hard,
                selected: _min == 6 && _max == 10,
                onTap: () => _setRange(6, 10),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
          SizedBox(
            height: 44,
            child: _feedback == null
                ? null
                : Align(
                    alignment: Alignment.center,
                    child: Text(
                      _feedback!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: _mood == AxolotlMood.celebrate
                            ? AppColors.tealDark
                            : AppColors.pinkDark,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: AppColors.blush,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.onDigit,
    required this.onBackspace,
    required this.onCheck,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['⌫', '0', '✓'],
    ];

    return Column(
      children: [
        for (final row in keys)
          Row(
            children: [
              for (final key in row)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: FilledButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        if (key == '⌫') {
                          onBackspace();
                        } else if (key == '✓') {
                          onCheck();
                        } else {
                          onDigit(key);
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: key == '✓'
                            ? AppColors.teal
                            : Colors.white,
                        foregroundColor: AppColors.ink,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: const BorderSide(color: AppColors.blush, width: 2),
                        ),
                      ),
                      child: Text(
                        key,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
