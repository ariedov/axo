import 'package:flutter/material.dart';

import '../config.dart';
import '../data/game_catalog.dart';
import '../screens/division_screen.dart';
import '../screens/english_screen.dart';
import '../screens/memory_screen.dart';
import '../screens/simon_screen.dart';
import '../screens/spelling_screen.dart';
import '../screens/times_tables_screen.dart';
import '../state/habit_scope.dart';
import '../strings.dart';
import '../theme.dart';

Widget miniGameScreen(String id) {
  switch (id) {
    case AppConfig.timesTablesGame:
      return const TimesTablesScreen();
    case AppConfig.spellingGame:
      return const SpellingScreen();
    case AppConfig.englishGame:
      return const EnglishScreen();
    case AppConfig.divisionGame:
      return const DivisionScreen();
    case AppConfig.memoryGame:
      return const MemoryScreen();
    case AppConfig.simonGame:
      return const SimonScreen();
    default:
      throw ArgumentError.value(id, 'id', 'unknown mini-game');
  }
}

Future<void> openMiniGame(BuildContext context, MiniGame game) async {
  await HabitScope.of(context).markGamePlayed(game.id);
  if (!context.mounted) return;
  await Navigator.push<void>(
    context,
    MaterialPageRoute<void>(builder: (_) => miniGameScreen(game.id)),
  );
}

class GameCardsRow extends StatelessWidget {
  const GameCardsRow({super.key, required this.games});

  final List<MiniGame> games;

  @override
  Widget build(BuildContext context) {
    final store = HabitScope.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: SizedBox(
        height: 168,
        child: Row(
          children: [
            for (var i = 0; i < 2; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: i < games.length
                    ? GameCard(
                        key: Key('game-${games[i].id}'),
                        game: games[i],
                        used: store.playsUsed(games[i].id),
                        max: store.rewardedPlays,
                        showLimit: store.gameLimitEnabled,
                        onTap: () => openMiniGame(context, games[i]),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class GameCard extends StatelessWidget {
  const GameCard({
    super.key,
    required this.game,
    required this.used,
    required this.max,
    required this.onTap,
    this.showLimit = true,
  });

  final MiniGame game;
  final int used;
  final int max;
  final VoidCallback onTap;
  final bool showLimit;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: game.color.withValues(alpha: 0.45),
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
            child: Column(
              children: [
                Icon(game.icon, size: 32, color: game.color),
                const SizedBox(height: 6),
                SizedBox(
                  height: 40,
                  child: Text(
                    game.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
                SizedBox(
                  height: 32,
                  child: Text(
                    game.hint,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                if (showLimit)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: used < max
                            ? AppColors.goldDeep
                            : AppColors.muted,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        S.gameRoundsProgress(used, max),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: used < max
                              ? AppColors.goldDeep
                              : AppColors.muted,
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
