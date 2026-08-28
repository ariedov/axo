import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config.dart';
import '../data/answer.dart';
import '../data/game_round.dart';
import '../data/models.dart';
import '../data/translation_catalog.dart';
import '../state/habit_scope.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets/answer_flash.dart';
import '../widgets/axolotl_mascot.dart';
import '../widgets/game_input_body.dart';
import '../widgets/game_round_summary.dart';
import '../widgets/game_scaffold.dart';
import '../widgets/game_score_bar.dart';
import '../widgets/game_setup_body.dart';
import '../widgets/task_icons.dart';

class EnglishScreen extends StatefulWidget {
  const EnglishScreen({super.key});

  @override
  State<EnglishScreen> createState() => _EnglishScreenState();
}

enum _TranslateMode { both, toUk, toEn }

class _EnglishScreenState extends State<EnglishScreen> {
  final _random = Random();
  final _input = TextEditingController();
  final _focus = FocusNode();
  final _round = GameRound();
  List<TranslationPair> _pairs = const [];
  TranslationPair? _current;
  var _mode = _TranslateMode.both;
  var _toUkrainian = true;
  var _misses = 0;
  var _mood = AxolotlMood.happy;
  var _busy = false;
  var _showSummary = false;
  var _roundPoints = 0;
  var _playing = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (mounted) setState(() {});
    });
    _load();
  }

  @override
  void dispose() {
    _focus.dispose();
    _input.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final pairs = await TranslationCatalog.load();
    if (!mounted) return;
    setState(() => _pairs = pairs);
  }

  bool get _infinite =>
      HabitScope.of(context).playsLeft(AppConfig.englishGame) <= 0;

  int get _roundReward => _mode == _TranslateMode.both
      ? AppConfig.englishBothWaysPoints
      : AppConfig.englishOneWayPoints;

  void _setMode(_TranslateMode mode) {
    if (mode == _mode) return;
    setState(() {
      _mode = mode;
      _toUkrainian = switch (mode) {
        _TranslateMode.toUk => true,
        _TranslateMode.toEn => false,
        _TranslateMode.both => _toUkrainian,
      };
      _input.clear();
    });
  }

  void _next() {
    if (_pairs.isEmpty) return;
    setState(() {
      _current = _pairs[_random.nextInt(_pairs.length)];
      _toUkrainian = switch (_mode) {
        _TranslateMode.toUk => true,
        _TranslateMode.toEn => false,
        _TranslateMode.both => !_toUkrainian,
      };
      _input.clear();
      _misses = 0;
      _mood = AxolotlMood.happy;
      _busy = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keepKeyboard();
    });
  }

  void _keepKeyboard() {
    if (!mounted || _showSummary || !_playing) return;
    _focus.requestFocus();
  }

  void _start() {
    _round.reset();
    _roundPoints = 0;
    _showSummary = false;
    _playing = true;
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
      _roundPoints = await HabitScope.of(
        context,
      ).tryAwardGamePlay(
        AppConfig.englishGame,
        points: _roundReward,
      );
      if (!mounted) return;
      setState(() {
        _showSummary = true;
        _busy = false;
        _mood = AxolotlMood.celebrate;
      });
      _focus.unfocus();
      return;
    }
    _next();
  }

  Future<void> _check() async {
    if (_busy || _showSummary) return;
    final current = _current;
    if (current == null) return;
    final guess = _input.text;
    if (normalizeAnswer(guess).isEmpty) return;

    if (answersMatch(guess, _answer)) {
      HapticFeedback.mediumImpact();
      setState(() {
        _busy = true;
        _mood = AxolotlMood.celebrate;
      });
      _keepKeyboard();
      await showAnswerFlash(context);
      if (!mounted) return;
      await _finishItem(true);
      return;
    }

    HapticFeedback.heavyImpact();
    final misses = _misses + 1;
    final revealed = 'Було «$_answer». ${S.keepGoing}';
    setState(() {
      _misses = misses;
      _mood = AxolotlMood.cheer;
      if (misses >= 2) _busy = true;
    });
    _keepKeyboard();
    await showAnswerFlash(
      context,
      message: misses >= 2 ? revealed : S.tryAgain,
      success: false,
      hold: Duration(milliseconds: misses >= 2 ? 1100 : 700),
    );
    if (!mounted) return;
    if (misses >= 2) await _finishItem(false);
  }

  String get _prompt =>
      _toUkrainian ? (_current?.en ?? '') : (_current?.uk ?? '');

  String get _answer =>
      _toUkrainian ? (_current?.uk ?? '') : (_current?.en ?? '');

  @override
  Widget build(BuildContext context) {
    final word = _current;
    return GameScaffold(
      title: S.english,
      mood: _mood,
      showMascot: !_playing || _showSummary,
      child: _pairs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _showSummary
          ? GameRoundSummary(
              correct: _round.correct,
              wrong: _round.wrong,
              points: _roundPoints,
              gameId: AppConfig.englishGame,
              onContinue: _continueAfterRound,
            )
          : !_playing
          ? GameSetupBody(
              gameId: AppConfig.englishGame,
              onStart: _start,
              options: [
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    GameModeChip(
                      selected: _mode == _TranslateMode.both,
                      onTap: () => _setMode(_TranslateMode.both),
                      points: AppConfig.englishBothWaysPoints,
                      child: const Text(S.bothWays),
                    ),
                    GameModeChip(
                      selected: _mode == _TranslateMode.toUk,
                      onTap: () => _setMode(_TranslateMode.toUk),
                      points: AppConfig.englishOneWayPoints,
                      child: const _DirectionLabel(from: S.enLang, to: S.uaLang),
                    ),
                    GameModeChip(
                      selected: _mode == _TranslateMode.toEn,
                      onTap: () => _setMode(_TranslateMode.toEn),
                      points: AppConfig.englishOneWayPoints,
                      child: const _DirectionLabel(from: S.uaLang, to: S.enLang),
                    ),
                  ],
                ),
              ],
            )
          : word == null
          ? const Center(child: CircularProgressIndicator())
          : GameInputBody(
              chrome: [
                GameScoreBar(round: _round, infinite: _infinite),
                const SizedBox(height: 12),
              ],
              prompt: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.blush, width: 2),
                  ),
                  child: Column(
                    children: [
                      PictureGlyph(word.emoji, size: 40),
                      const SizedBox(height: 4),
                      Text(
                        _toUkrainian ? S.translateToUk : S.translateToEn,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _prompt,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
              field: TextField(
                controller: _input,
                focusNode: _focus,
                textAlign: TextAlign.center,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.none,
                autocorrect: false,
                enableSuggestions: false,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
                decoration: InputDecoration(
                  hintText: _focus.hasFocus ? null : S.writeTheWord,
                ),
                onSubmitted: (_) {
                  _check();
                  _keepKeyboard();
                },
              ),
              action: FilledButton(
                onPressed: _busy ? null : _check,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Text(S.check),
                ),
              ),
            ),
    );
  }
}

class _DirectionLabel extends StatelessWidget {
  const _DirectionLabel({required this.from, required this.to});

  final String from;
  final String to;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(from),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Icon(Icons.arrow_forward_rounded, size: 16),
        ),
        Text(to),
      ],
    );
  }
}

