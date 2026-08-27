import 'package:flutter/material.dart';

import '../theme.dart';
import 'axolotl_mascot.dart';

class GameScaffold extends StatelessWidget {
  const GameScaffold({
    super.key,
    required this.title,
    required this.mood,
    required this.child,
    this.footer,
  });

  final String title;
  final AxolotlMood mood;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
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
              child: Column(
                children: [
                  AxolotlMascot(mood: mood, size: 120),
                  Expanded(child: child),
                  ?footer,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
