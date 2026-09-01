import 'package:flutter/material.dart';

import '../config.dart';
import '../strings.dart';
import '../theme.dart';

class MiniGame {
  const MiniGame({
    required this.id,
    required this.title,
    required this.hint,
    required this.icon,
    required this.color,
  });

  final String id;
  final String title;
  final String hint;
  final IconData icon;
  final Color color;
}

const miniGames = [
  MiniGame(
    id: AppConfig.timesTablesGame,
    title: S.timesTables,
    hint: S.timesTablesHint,
    icon: Icons.calculate_rounded,
    color: AppColors.teal,
  ),
  MiniGame(
    id: AppConfig.spellingGame,
    title: S.spelling,
    hint: S.spellingHint,
    icon: Icons.spellcheck_rounded,
    color: AppColors.pink,
  ),
  MiniGame(
    id: AppConfig.englishGame,
    title: S.english,
    hint: S.englishHint,
    icon: Icons.translate_rounded,
    color: AppColors.goldDeep,
  ),
  MiniGame(
    id: AppConfig.divisionGame,
    title: S.division,
    hint: S.divisionHint,
    icon: Icons.percent_rounded,
    color: AppColors.tealDark,
  ),
  MiniGame(
    id: AppConfig.memoryGame,
    title: S.memory,
    hint: S.memoryHint,
    icon: Icons.grid_view_rounded,
    color: AppColors.pinkDark,
  ),
];

List<MiniGame> pickRecentMiniGames(
  List<String> recentIds, {
  int limit = 2,
  List<MiniGame> catalog = miniGames,
}) {
  final picked = <MiniGame>[];
  final seen = <String>{};

  void add(MiniGame game) {
    if (picked.length >= limit) return;
    if (!seen.add(game.id)) return;
    picked.add(game);
  }

  for (final id in recentIds) {
    for (final game in catalog) {
      if (game.id == id) {
        add(game);
        break;
      }
    }
  }
  for (final game in catalog) {
    add(game);
  }
  return picked;
}
