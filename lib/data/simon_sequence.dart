import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';
import 'memory_deck.dart';

class SimonSequence {
  static const faces = [
    MemoryFace(icon: Icons.pets_rounded, color: AppColors.pinkDark),
    MemoryFace(icon: Icons.star_rounded, color: AppColors.goldDeep),
    MemoryFace(icon: Icons.local_florist_rounded, color: AppColors.teal),
    MemoryFace(icon: Icons.wb_sunny_rounded, color: AppColors.tealDark),
  ];

  static List<int> ofLength(int length, Random random, {required int pads}) {
    return [for (var i = 0; i < length; i++) random.nextInt(pads)];
  }

  static List<int> grow(List<int> current, Random random, {required int pads}) {
    return [...current, random.nextInt(pads)];
  }
}
