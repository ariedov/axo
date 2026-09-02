import 'package:flutter/material.dart';

import '../state/habit_scope.dart';
import '../strings.dart';
import '../theme.dart';
import 'game_plays_banner.dart';

class GameSetupBody extends StatelessWidget {
  const GameSetupBody({
    super.key,
    required this.gameId,
    required this.onStart,
    this.options = const [],
    this.rewardHint,
  });

  final String gameId;
  final VoidCallback onStart;
  final List<Widget> options;
  final String? rewardHint;

  @override
  Widget build(BuildContext context) {
    return GameLimitClock(
      builder: (context) {
        final store = HabitScope.of(context);
        final canPlay = !store.gamesLocked;
        final training = store.playsLeft(gameId) <= 0;
        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GamePlaysBanner(gameId: gameId),
                    if (rewardHint != null && !training) ...[
                      const SizedBox(height: 16),
                      Text(
                        rewardHint!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          color: AppColors.goldDeep,
                        ),
                      ),
                    ],
                    if (options.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text(
                        S.pickGameMode,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...options,
                    ],
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: canPlay ? onStart : null,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Text(S.letsGo),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class GameModeChip extends StatelessWidget {
  const GameModeChip({
    super.key,
    required this.selected,
    required this.onTap,
    required this.points,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final int points;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        selected: selected,
        selectedColor: AppColors.blush,
        showCheckmark: false,
        onSelected: (_) => onTap(),
        label: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            child,
            const SizedBox(height: 2),
            Text(
              S.plusPoints(points),
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: selected ? AppColors.goldDeep : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
