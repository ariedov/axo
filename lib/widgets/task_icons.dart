import 'package:flutter/material.dart';

import '../theme.dart';

class TaskIcons {
  static const choices = <String, IconData>{
    'star': Icons.star_rounded,
    'gift': Icons.card_giftcard_rounded,
    'hygiene': Icons.water_drop_rounded,
    'bed': Icons.bed_rounded,
    'food': Icons.restaurant_rounded,
    'homework': Icons.menu_book_rounded,
    'read': Icons.auto_stories_rounded,
    'toys': Icons.toys_rounded,
    'walk': Icons.directions_run_rounded,
    'help': Icons.cleaning_services_rounded,
    'night': Icons.nights_stay_rounded,
    'music': Icons.music_note_rounded,
    'cook': Icons.soup_kitchen_rounded,
  };

  static IconData of(String key) {
    return choices[key] ??
        switch (key) {
          '🦷' || '🧼' || '💧' => Icons.water_drop_rounded,
          '🛏️' => Icons.bed_rounded,
          '🥣' => Icons.restaurant_rounded,
          '📚' => Icons.menu_book_rounded,
          '📖' => Icons.auto_stories_rounded,
          '🧸' => Icons.toys_rounded,
          '🏃' => Icons.directions_run_rounded,
          '🧹' => Icons.cleaning_services_rounded,
          '🌙' => Icons.nights_stay_rounded,
          '⭐' => Icons.star_rounded,
          '🎵' => Icons.music_note_rounded,
          '🧑‍🍳' => Icons.soup_kitchen_rounded,
          _ => Icons.star_rounded,
        };
  }

  static String canonical(String? key) {
    if (key != null && choices.containsKey(key)) return key;
    final icon = of(key ?? 'star');
    for (final entry in choices.entries) {
      if (entry.value == icon) return entry.key;
    }
    return 'star';
  }
}

class TaskGlyph extends StatelessWidget {
  const TaskGlyph(this.icon, {super.key, this.size = 28, this.color});

  final String icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Icon(TaskIcons.of(icon), size: size, color: color ?? AppColors.pinkDark);
  }
}

class PictureIcons {
  static String normalize(String emoji) => emoji.replaceAll('\uFE0F', '');

  static const _icons = <String, IconData>{
    '👩': Icons.woman_rounded,
    '👨': Icons.man_rounded,
    '🏠': Icons.home_rounded,
    '🐱': Icons.pets_rounded,
    '🐶': Icons.pets_rounded,
    '🏫': Icons.school_rounded,
    '📗': Icons.menu_book_rounded,
    '☀': Icons.wb_sunny_rounded,
    '🌙': Icons.nights_stay_rounded,
    '💧': Icons.water_drop_rounded,
    '🌳': Icons.park_rounded,
    '🌸': Icons.local_florist_rounded,
    '🍎': Icons.lunch_dining_rounded,
    '🥛': Icons.local_drink_rounded,
    '🍞': Icons.bakery_dining_rounded,
    '🐟': Icons.set_meal_rounded,
    '🐦': Icons.air_rounded,
    '🤗': Icons.volunteer_activism_rounded,
    '📖': Icons.auto_stories_rounded,
    '🌈': Icons.looks_rounded,
    '⭐': Icons.star_rounded,
    '☁': Icons.cloud_rounded,
    '🌧': Icons.umbrella_rounded,
    '❄': Icons.ac_unit_rounded,
    '⛄': Icons.ac_unit_rounded,
    '🏖': Icons.beach_access_rounded,
    '🍂': Icons.eco_rounded,
    '🌷': Icons.local_florist_rounded,
    '🌅': Icons.wb_twilight_rounded,
    '🌆': Icons.location_city_rounded,
    '❤': Icons.favorite_rounded,
    '😊': Icons.sentiment_satisfied_alt_rounded,
    '🇺🇦': Icons.flag_rounded,
    '🏛': Icons.account_balance_rounded,
    '🩷': Icons.favorite_rounded,
    '🚲': Icons.pedal_bike_rounded,
    '📓': Icons.book_rounded,
    '✏': Icons.edit_rounded,
    '🪟': Icons.window_rounded,
    '🛏': Icons.bed_rounded,
    '🧸': Icons.toys_rounded,
    '🍬': Icons.cookie_rounded,
    '🌊': Icons.waves_rounded,
    '🏞': Icons.landscape_rounded,
    '🌲': Icons.forest_rounded,
    '🐝': Icons.emoji_nature_rounded,
    '🦋': Icons.emoji_nature_rounded,
    '🎒': Icons.backpack_rounded,
    '🔴': Icons.circle,
    '🔵': Icons.circle,
    '🟢': Icons.circle,
  };

  static const _colors = <String, Color>{
    '☀': AppColors.goldDeep,
    '🌙': AppColors.ink,
    '💧': AppColors.tealDark,
    '🌳': AppColors.tealDark,
    '🌸': AppColors.pink,
    '🍎': AppColors.pinkDark,
    '🥛': AppColors.teal,
    '🍞': AppColors.goldDeep,
    '🐟': AppColors.teal,
    '🐦': AppColors.tealDark,
    '🌈': AppColors.pink,
    '⭐': AppColors.goldDeep,
    '☁': AppColors.muted,
    '🌧': AppColors.tealDark,
    '❄': AppColors.teal,
    '⛄': AppColors.teal,
    '🏖': AppColors.goldDeep,
    '🍂': Color(0xFFD17A22),
    '🌷': AppColors.pink,
    '🌅': AppColors.goldDeep,
    '❤': AppColors.pinkDark,
    '🩷': AppColors.pink,
    '🌊': AppColors.tealDark,
    '🌲': AppColors.tealDark,
    '🐝': AppColors.goldDeep,
    '🦋': AppColors.teal,
    '🔴': Color(0xFFE53935),
    '🔵': Color(0xFF1E88E5),
    '🟢': Color(0xFF43A047),
  };

  static bool knows(String emoji) => _icons.containsKey(normalize(emoji));

  static IconData of(String emoji) =>
      _icons[normalize(emoji)] ?? Icons.star_rounded;

  static Color colorOf(String emoji) =>
      _colors[normalize(emoji)] ?? AppColors.pinkDark;
}

/// Picture for spelling / translation prompts. Material icons, not emoji —
/// Nunito has no color-emoji glyphs, so those render as tofu.
class PictureGlyph extends StatelessWidget {
  const PictureGlyph(this.emoji, {super.key, this.size = 56});

  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      PictureIcons.of(emoji),
      size: size,
      color: PictureIcons.colorOf(emoji),
    );
  }
}
