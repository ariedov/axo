import 'package:flutter/material.dart';

class GameInputBody extends StatelessWidget {
  const GameInputBody({
    super.key,
    this.chrome = const [],
    required this.prompt,
    required this.field,
    required this.action,
  });

  final List<Widget> chrome;
  final List<Widget> prompt;
  final Widget field;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        children: [
          ...chrome,
          ...prompt,
          const SizedBox(height: 12),
          field,
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: action,
          ),
        ],
      ),
    );
  }
}
