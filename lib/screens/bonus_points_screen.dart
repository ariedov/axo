import 'package:flutter/material.dart';

import '../strings.dart';
import '../widgets/bonus_points_section.dart';

class BonusPointsScreen extends StatelessWidget {
  const BonusPointsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(S.bonusPoints)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: const SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: BonusPointsSection(showHeading: false),
          ),
        ),
      ),
    );
  }
}
