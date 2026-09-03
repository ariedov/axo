import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/habit_scope.dart';
import '../strings.dart';
import '../theme.dart';
import 'labeled_field.dart';
import 'settings_sheet.dart';

Future<void> showBonusPointsSheet(BuildContext context) {
  return showParentSheet(
    context: context,
    builder: (context) => const _BonusPointsSheet(),
  );
}

class _BonusPointsSheet extends StatefulWidget {
  const _BonusPointsSheet();

  @override
  State<_BonusPointsSheet> createState() => _BonusPointsSheetState();
}

class _BonusPointsSheetState extends State<_BonusPointsSheet> {
  var _dirty = false;

  @override
  Widget build(BuildContext context) {
    return SettingsSheetScaffold(
      title: S.bonusPoints,
      hint: S.bonusPointsHint,
      dirty: _dirty,
      child: SingleChildScrollView(
        child: BonusPointsSection(
          showHeading: false,
          showHint: false,
          onDirtyChanged: (value) {
            if (value == _dirty) return;
            setState(() => _dirty = value);
          },
        ),
      ),
    );
  }
}

class BonusPointsSection extends StatefulWidget {
  const BonusPointsSection({
    super.key,
    this.showHeading = true,
    this.showHint = true,
    this.onDirtyChanged,
  });

  final bool showHeading;
  final bool showHint;
  final ValueChanged<bool>? onDirtyChanged;

  @override
  State<BonusPointsSection> createState() => _BonusPointsSectionState();
}

class _BonusPointsSectionState extends State<BonusPointsSection> {
  final _amount = TextEditingController();

  @override
  void initState() {
    super.initState();
    _amount.addListener(_refresh);
  }

  @override
  void dispose() {
    _amount
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() {
    widget.onDirtyChanged?.call(_canAdjust);
    if (mounted) setState(() {});
  }

  bool get _canAdjust {
    final amount = int.tryParse(_amount.text.trim()) ?? 0;
    return amount > 0;
  }

  Future<void> _adjust(bool add) async {
    final amount = int.tryParse(_amount.text.trim()) ?? 0;
    if (amount <= 0) return;
    final applied = await HabitScope.of(context).adjustPoints(
      add ? amount : -amount,
    );
    if (!mounted) return;
    _amount.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          applied == 0 ? S.noPointsToRemove : S.pointsAdjusted(applied),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final points = HabitScope.of(context).totalPoints;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showHeading) ...[
          const Text(
            S.bonusPoints,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
        ],
        if (widget.showHint) ...[
          const Text(
            S.bonusPointsHint,
            style: TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
        ],
        Text(
          S.pointsNow(points),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: AppColors.pinkDark,
          ),
        ),
        const SizedBox(height: 12),
        LabeledField(
          key: const Key('bonus-amount'),
          controller: _amount,
          label: S.pointsAmount,
          keyboardType: const TextInputType.numberWithOptions(
            signed: false,
            decimal: false,
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (_canAdjust) _adjust(true);
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _canAdjust ? () => _adjust(false) : null,
                child: const Text(S.removePoints),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: _canAdjust ? () => _adjust(true) : null,
                child: const Text(S.addPoints),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
