import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

class MemoryFace {
  const MemoryFace({required this.icon, required this.color});

  final IconData icon;
  final Color color;
}

class MemoryTile {
  MemoryTile({
    required this.id,
    required this.faceIndex,
    this.faceUp = false,
    this.matched = false,
  });

  final int id;
  final int faceIndex;
  bool faceUp;
  bool matched;

  MemoryTile copy() => MemoryTile(
    id: id,
    faceIndex: faceIndex,
    faceUp: faceUp,
    matched: matched,
  );
}

class MemoryDeck {
  static const faces = [
    MemoryFace(icon: Icons.pets_rounded, color: AppColors.pinkDark),
    MemoryFace(icon: Icons.star_rounded, color: AppColors.goldDeep),
    MemoryFace(icon: Icons.local_florist_rounded, color: AppColors.pink),
    MemoryFace(icon: Icons.wb_sunny_rounded, color: AppColors.gold),
    MemoryFace(icon: Icons.directions_car_rounded, color: AppColors.tealDark),
    MemoryFace(icon: Icons.sailing_rounded, color: AppColors.teal),
    MemoryFace(icon: Icons.icecream_rounded, color: AppColors.pinkDark),
    MemoryFace(icon: Icons.music_note_rounded, color: AppColors.goldDeep),
  ];

  static List<MemoryTile> deal(Random random, {required int pairs}) {
    final indexes = List<int>.generate(faces.length, (i) => i)..shuffle(random);
    final chosen = indexes.take(pairs).toList();
    final tiles = <MemoryTile>[
      for (var i = 0; i < chosen.length; i++) ...[
        MemoryTile(id: i * 2, faceIndex: chosen[i]),
        MemoryTile(id: i * 2 + 1, faceIndex: chosen[i]),
      ],
    ]..shuffle(random);
    return tiles;
  }
}
