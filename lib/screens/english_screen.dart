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
import '../widgets/axolotl_mascot.dart';
import '../widgets/game_plays_banner.dart';
import '../widgets/game_round_summary.dart';
import '../widgets/game_scaffold.dart';
import '../widgets/game_score_bar.dart';
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
  String? _feedback;

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
    _next();
  }

  bool get _infinite =>
      HabitScope.of(context).playsLeft(AppConfig.englishGame) <= 0;

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
      _feedback = null;
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
      ).tryAwardGamePlay(AppConfig.englishGame);
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
        _feedback = S.correct;
      });
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      await _finishItem(true);
      return;
    }

    HapticFeedback.heavyImpact();
    setState(() {
      _misses += 1;
      _mood = AxolotlMood.cheer;
      _feedback = _misses >= 2 ? 'Було «$_answer». ${S.tryAgain}' : S.tryAgain;
    });
    if (_misses >= 2) {
      _busy = true;
      await Future<void>.delayed(const Duration(milliseconds: 1600));
      if (!mounted) return;
      await _finishItem(false);
    }
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
      child: word == null
          ? const Center(child: CircularProgressIndicator())
          : _showSummary
          ? GameRoundSummary(
              correct: _round.correct,
              wrong: _round.wrong,
              points: _roundPoints,
              gameId: AppConfig.englishGame,
              onContinue: _continueAfterRound,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              children: [
                const GamePlaysBanner(gameId: AppConfig.englishGame),
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    _ModeChip(
                      selected: _mode == _TranslateMode.both,
                      onTap: () => _setMode(_TranslateMode.both),
                      child: const Text(S.bothWays),
                    ),
                    _ModeChip(
                      selected: _mode == _TranslateMode.toUk,
                      onTap: () => _setMode(_TranslateMode.toUk),
                      child: const _DirectionLabel(from: S.enLang, to: S.uaLang),
                    ),
                    _ModeChip(
                      selected: _mode == _TranslateMode.toEn,
                      onTap: () => _setMode(_TranslateMode.toEn),
                      child: const _DirectionLabel(from: S.uaLang, to: S.enLang),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GameScoreBar(round: _round, infinite: _infinite),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.blush, width: 2),
                  ),
                  child: Column(
                    children: [
                      PictureGlyph(word.emoji, size: 64),
                      const SizedBox(height: 8),
                      Text(
                        _toUkrainian ? S.translateToUk : S.translateToEn,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _prompt,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _input,
                  focusNode: _focus,
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.none,
                  autocorrect: false,
                  enableSuggestions: false,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                  decoration: InputDecoration(
                    hintText: _focus.hasFocus ? null : S.writeTheWord,
                  ),
                  onSubmitted: (_) => _check(),
                ),
                if (_feedback != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
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
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _check,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Text(S.check),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.child,
    required this.selected,
    required this.onTap,
  });

  final Widget child;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: child,
        selected: selected,
        selectedColor: AppColors.blush,
        onSelected: (_) => onTap(),
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

