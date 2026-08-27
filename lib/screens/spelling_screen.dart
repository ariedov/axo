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
import '../widgets/answer_flash.dart';
import '../widgets/axolotl_mascot.dart';
import '../widgets/game_input_body.dart';
import '../widgets/game_round_summary.dart';
import '../widgets/game_scaffold.dart';
import '../widgets/game_score_bar.dart';
import '../widgets/game_setup_body.dart';
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
  var _playing = false;

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
  }

  void _next() {
    if (_words.isEmpty) return;
    setState(() {
      _current = _words[_random.nextInt(_words.length)];
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
        AppConfig.spellingGame,
        points: AppConfig.spellingRoundPoints,
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

    if (answersMatch(guess, current.word)) {
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
    setState(() {
      _misses = misses;
      _mood = AxolotlMood.cheer;
      if (misses >= 2) _busy = true;
    });
    _keepKeyboard();
    await showAnswerFlash(
      context,
      message: misses >= 2 ? 'Було «${current.word}». ${S.tryAgain}' : S.tryAgain,
      success: false,
      hold: Duration(milliseconds: misses >= 2 ? 1100 : 700),
    );
    if (!mounted) return;
    if (misses >= 2) await _finishItem(false);
  }

  @override
  Widget build(BuildContext context) {
    final word = _current;
    return GameScaffold(
      title: S.spelling,
      mood: _mood,
      showMascot: !_playing || _showSummary,
      child: _words.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _showSummary
          ? GameRoundSummary(
              correct: _round.correct,
              wrong: _round.wrong,
              points: _roundPoints,
              gameId: AppConfig.spellingGame,
              onContinue: _continueAfterRound,
            )
          : !_playing
          ? GameSetupBody(
              gameId: AppConfig.spellingGame,
              onStart: _start,
              rewardHint: S.pointsPerRound(AppConfig.spellingRoundPoints),
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
                      const SizedBox(height: 6),
                      Text(
                        word.hint,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
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
