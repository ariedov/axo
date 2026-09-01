import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

class GameKeypad extends StatelessWidget {
  const GameKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    required this.onCheck,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['⌫', '0', '✓'],
    ];

    return Column(
      children: [
        for (final row in keys)
          Row(
            children: [
              for (final key in row)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: FilledButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        if (key == '⌫') {
                          onBackspace();
                        } else if (key == '✓') {
                          onCheck();
                        } else {
                          onDigit(key);
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: key == '✓'
                            ? AppColors.teal
                            : Colors.white,
                        foregroundColor: AppColors.ink,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: const BorderSide(
                            color: AppColors.blush,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        key,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
