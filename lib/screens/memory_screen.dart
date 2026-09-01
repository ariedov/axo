import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config.dart';
import '../data/game_round.dart';
import '../data/memory_deck.dart';
import '../state/habit_scope.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets/axolotl_mascot.dart';
import '../widgets/game_round_summary.dart';
import '../widgets/game_scaffold.dart';
import '../widgets/game_setup_body.dart';

class MemoryScreen extends StatefulWidget {
  const MemoryScreen({
    super.key,
    this.random,
    this.pairs = AppConfig.memoryPairs,
    this.tiles,
    this.mismatchHold = const Duration(milliseconds: 800),
  });

  final Random? random;
  final int pairs;
  final List<MemoryTile>? tiles;
  final Duration mismatchHold;

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  late final Random _random = widget.random ?? Random();
  final _round = GameRound();
  var _tiles = <MemoryTile>[];
  var _mood = AxolotlMood.happy;
  var _busy = false;
  var _showSummary = false;
  var _roundPoints = 0;
  var _playing = false;

  bool get _infinite =>
      HabitScope.of(context).playsLeft(AppConfig.memoryGame) <= 0;

  int get _columns => widget.pairs <= 4 ? 2 : 4;

  List<int> get _pairFaces {
    final faces = <int>[];
    for (final tile in _tiles) {
      if (!faces.contains(tile.faceIndex)) faces.add(tile.faceIndex);
    }
    return faces;
  }

  Set<int> get _matchedFaces => {
    for (final tile in _tiles)
      if (tile.matched) tile.faceIndex,
  };

  void _deal() {
    _tiles = widget.tiles != null
        ? [for (final tile in widget.tiles!) tile.copy()]
        : MemoryDeck.deal(_random, pairs: widget.pairs);
  }

  void _start() {
    _round.reset();
    _roundPoints = 0;
    _showSummary = false;
    _playing = true;
    _busy = false;
    _mood = AxolotlMood.happy;
    _deal();
    setState(() {});
  }

  void _continueAfterRound() {
    setState(() {
      _playing = false;
      _showSummary = false;
      _round.reset();
      _roundPoints = 0;
      _tiles = [];
    });
  }

  Future<void> _finishBoard() async {
    if (!_infinite) {
      _roundPoints = await HabitScope.of(context).tryAwardGamePlay(
        AppConfig.memoryGame,
        points: AppConfig.memoryRoundPoints,
      );
      if (!mounted) return;
      setState(() {
        _showSummary = true;
        _busy = false;
        _mood = AxolotlMood.celebrate;
      });
      return;
    }
    _deal();
    setState(() {
      _busy = false;
      _mood = AxolotlMood.happy;
    });
  }

  Future<void> _pick(int index) async {
    if (_busy || _showSummary) return;
    final tile = _tiles[index];
    if (tile.faceUp || tile.matched) return;

    setState(() => tile.faceUp = true);
    final open = _tiles.where((item) => item.faceUp && !item.matched).toList();
    if (open.length < 2) return;

    _busy = true;
    if (open[0].faceIndex == open[1].faceIndex) {
      HapticFeedback.mediumImpact();
      setState(() {
        open[0].matched = true;
        open[1].matched = true;
        _mood = AxolotlMood.celebrate;
      });
      _round.record(true);
      if (_tiles.every((item) => item.matched)) {
        await _finishBoard();
      } else {
        setState(() => _busy = false);
      }
      return;
    }

    HapticFeedback.heavyImpact();
    _round.record(false);
    await Future<void>.delayed(widget.mismatchHold);
    if (!mounted) return;
    setState(() {
      open[0].faceUp = false;
      open[1].faceUp = false;
      _mood = AxolotlMood.cheer;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: S.memory,
      mood: _mood,
      showMascot: !_playing || _showSummary,
      child: _showSummary
          ? GameRoundSummary(
              correct: _round.correct,
              wrong: _round.wrong,
              points: _roundPoints,
              gameId: AppConfig.memoryGame,
              onContinue: _continueAfterRound,
              title: S.correct,
              showCounts: false,
            )
          : !_playing
          ? GameSetupBody(
              gameId: AppConfig.memoryGame,
              onStart: _start,
              rewardHint: S.pointsPerRound(AppConfig.memoryRoundPoints),
            )
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  _PairProgress(
                    faces: _pairFaces,
                    matched: _matchedFaces,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _Board(
                      tiles: _tiles,
                      columns: _columns,
                      onPick: _pick,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _PairProgress extends StatelessWidget {
  const _PairProgress({required this.faces, required this.matched});

  final List<int> faces;
  final Set<int> matched;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('memory-progress'),
      children: [
        for (final faceIndex in faces)
          Expanded(
            child: _PairMark(
              face: MemoryDeck.faces[faceIndex],
              found: matched.contains(faceIndex),
            ),
          ),
      ],
    );
  }
}

class _PairMark extends StatelessWidget {
  const _PairMark({required this.face, required this.found});

  final MemoryFace face;
  final bool found;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.symmetric(horizontal: 3),
      height: 40,
      decoration: BoxDecoration(
        color: found ? Colors.white : AppColors.blush,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: found ? face.color.withValues(alpha: 0.7) : AppColors.blush,
          width: 2,
        ),
      ),
      child: Icon(
        face.icon,
        size: 22,
        color: found ? face.color : AppColors.muted.withValues(alpha: 0.4),
      ),
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({
    required this.tiles,
    required this.columns,
    required this.onPick,
  });

  final List<MemoryTile> tiles;
  final int columns;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final rows = (tiles.length / columns).ceil();
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        final height = (constraints.maxHeight - gap * (rows - 1)) / rows;
        final size = min(width, height);
        return Center(
          child: SizedBox(
            key: const Key('memory-board'),
            width: size * columns + gap * (columns - 1),
            height: size * rows + gap * (rows - 1),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tiles.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: gap,
                mainAxisSpacing: gap,
              ),
              itemBuilder: (context, index) {
                return _CardFace(
                  tile: tiles[index],
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

class _CardFace extends StatelessWidget {
  const _CardFace({required this.tile, required this.onTap});

  final MemoryTile tile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final face = MemoryDeck.faces[tile.faceIndex];
    final open = tile.faceUp || tile.matched;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('memory-${tile.id}'),
        onTap: open ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: open
              ? _Front(key: ValueKey('front-${tile.id}'), face: face)
              : _Back(key: ValueKey('back-${tile.id}')),
        ),
      ),
    );
  }
}

class _Front extends StatelessWidget {
  const _Front({super.key, required this.face});

  final MemoryFace face;

  @override
  Widget build(BuildContext context) {
    return Ink(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: face.color.withValues(alpha: 0.7), width: 3),
      ),
      child: Center(child: Icon(face.icon, size: 36, color: face.color)),
    );
  }
}

class _Back extends StatelessWidget {
  const _Back({super.key});

  @override
  Widget build(BuildContext context) {
    return Ink(
      decoration: BoxDecoration(
        color: AppColors.pink,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.pinkDark, width: 3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Image.asset(
          AxolotlMascot.happy,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
