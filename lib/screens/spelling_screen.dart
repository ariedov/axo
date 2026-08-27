import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config.dart';
import '../data/answer.dart';
import '../data/game_round.dart';
import '../data/models.dart';
import '../data/spelling_catalog.dart';
import '../state/habit_scope.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets/axolotl_mascot.dart';
import '../widgets/game_plays_banner.dart';
import '../widgets/game_round_summary.dart';
import '../widgets/game_scaffold.dart';
import '../widgets/game_score_bar.dart';
import '../widgets/task_icons.dart';

class SpellingScreen extends StatefulWidget {
  const SpellingScreen({super.key});

  @override
  State<SpellingScreen> createState() => _SpellingScreenState();
}

class _SpellingScreenState extends State<SpellingScreen> {
  final _random = Random();
  final _input = TextEditingController();
  final _focus = FocusNode();
  final _round = GameRound();
  List<SpellingWord> _words = const [];
  SpellingWord? _current;
  var _misses = 0;
  var _mood = AxolotlMood.happy;
  var _busy = false;
  var _showSummary = false;
  var _roundPoints = 0;
  String? _feedback;

  bool get _infinite =>
      HabitScope.of(context).playsLeft(AppConfig.spellingGame) <= 0;

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
    final words = await SpellingCatalog.load();
    if (!mounted) return;
    setState(() => _words = words);
    _next();
  }

  void _next() {
    if (_words.isEmpty) return;
    setState(() {
      _current = _words[_random.nextInt(_words.length)];
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
      ).tryAwardGamePlay(AppConfig.spellingGame);
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

    if (answersMatch(guess, current.word)) {
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
      _feedback = _misses >= 2
          ? 'Було «${current.word}». ${S.tryAgain}'
          : S.tryAgain;
    });
    if (_misses >= 2) {
      _busy = true;
      await Future<void>.delayed(const Duration(milliseconds: 1600));
      if (!mounted) return;
      await _finishItem(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final word = _current;
    return GameScaffold(
      title: S.spelling,
      mood: _mood,
      child: word == null
          ? const Center(child: CircularProgressIndicator())
          : _showSummary
          ? GameRoundSummary(
              correct: _round.correct,
              wrong: _round.wrong,
              points: _roundPoints,
              gameId: AppConfig.spellingGame,
              onContinue: _continueAfterRound,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              children: [
                const GamePlaysBanner(gameId: AppConfig.spellingGame),
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
                        word.hint,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
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
