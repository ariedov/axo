import 'package:flutter/material.dart';

class AppColors {
  static const peach = Color(0xFFFFF3EC);
  static const blush = Color(0xFFFFD8E1);
  static const pink = Color(0xFFFF8BA7);
  static const pinkDark = Color(0xFFE45C7F);
  static const teal = Color(0xFF6EC9C1);
  static const tealDark = Color(0xFF3AA39A);
  static const gold = Color(0xFFFFC44D);
  static const goldDeep = Color(0xFFE39A12);
  static const ink = Color(0xFF4A3A4A);
  static const muted = Color(0xFF8B7A8B);
  static const card = Color(0xFFFFFCFA);
  static const waiting = Color(0xFFFFF1C9);
  static const done = Color(0xFFD9F5F0);
}

class AppTheme {
  static const emojiFallback = [
    'Apple Color Emoji',
    'Noto Color Emoji',
    'NotoColorEmoji',
    'Segoe UI Emoji',
  ];

  static ThemeData get cute {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.pink,
        primary: AppColors.pinkDark,
        secondary: AppColors.teal,
        surface: AppColors.card,
      ),
      scaffoldBackgroundColor: AppColors.peach,
      useMaterial3: true,
      fontFamily: 'Nunito',
    );

    final text = _withEmojiFallback(
      base.textTheme.apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
        fontFamily: 'Nunito',
      ),
    );

    return base.copyWith(
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.peach,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.pink,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.pinkDark,
          textStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: const BorderSide(color: AppColors.blush, width: 2),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.pink;
          return AppColors.blush;
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.blush, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.pink, width: 2),
        ),
      ),
    );
  }

  static TextTheme _withEmojiFallback(TextTheme theme) {
    TextStyle? patch(TextStyle? style) => style?.copyWith(
      fontFamilyFallback: emojiFallback,
    );
    return theme.copyWith(
      displayLarge: patch(theme.displayLarge),
      displayMedium: patch(theme.displayMedium),
      displaySmall: patch(theme.displaySmall),
      headlineLarge: patch(theme.headlineLarge),
      headlineMedium: patch(theme.headlineMedium),
      headlineSmall: patch(theme.headlineSmall),
      titleLarge: patch(theme.titleLarge),
      titleMedium: patch(theme.titleMedium),
      titleSmall: patch(theme.titleSmall),
      bodyLarge: patch(theme.bodyLarge),
      bodyMedium: patch(theme.bodyMedium),
      bodySmall: patch(theme.bodySmall),
      labelLarge: patch(theme.labelLarge),
      labelMedium: patch(theme.labelMedium),
      labelSmall: patch(theme.labelSmall),
    );
  }
}
