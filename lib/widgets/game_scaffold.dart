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
    this.showMascot = true,
  });

  final String title;
  final AxolotlMood mood;
  final Widget child;
  final Widget? footer;
  final bool showMascot;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final bottomPad = keyboard > 0 ? keyboard : media.padding.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: Text(title)),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.peach, Color(0xFFFFE4EC)],
          ),
        ),
        child: MediaQuery.removeViewInsets(
          context: context,
          removeBottom: true,
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomPad),
            child: SafeArea(
              bottom: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    children: [
                      if (showMascot) AxolotlMascot(mood: mood, size: 120),
                      Expanded(child: child),
                      ?footer,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
