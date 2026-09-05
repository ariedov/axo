import 'package:flutter/material.dart';

import '../data/game_catalog.dart';
import '../state/habit_scope.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets/game_card.dart';
import '../widgets/game_plays_banner.dart';

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(S.miniGames)),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.peach, Color(0xFFFFE4EC)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListView(
                padding: const EdgeInsets.only(top: 8, bottom: 28),
                children: [
                  if (HabitScope.of(context).gameLimitEnabled)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                      child: Text(
                        S.practiceOnly(
                          HabitScope.of(context).rewardedPlays,
                          HabitScope.of(context).playLimitMinutes,
                        ),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  if (HabitScope.of(context).gamesLocked)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(24, 0, 24, 12),
                      child: GamePlaysBanner(),
                    ),
                  for (var i = 0; i < miniGames.length; i += 2)
                    GameCardsRow(
                      games: miniGames.sublist(
                        i,
                        i + 2 > miniGames.length ? miniGames.length : i + 2,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
