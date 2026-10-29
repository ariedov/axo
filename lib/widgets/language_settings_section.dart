import 'package:flutter/material.dart';

import '../data/app_language.dart';
import '../state/habit_scope.dart';
import '../strings.dart';
import '../theme.dart';
import 'settings_sheet.dart';

Future<void> showLanguageSettingsSheet(BuildContext context) {
  final messenger = ScaffoldMessenger.of(context);
  return showParentSheet(
    context: context,
    builder: (context) => LanguageSettingsSection(messenger: messenger),
  );
}

class LanguageSettingsSection extends StatefulWidget {
  const LanguageSettingsSection({super.key, required this.messenger});

  final ScaffoldMessengerState messenger;

  @override
  State<LanguageSettingsSection> createState() =>
      _LanguageSettingsSectionState();
}

class _LanguageSettingsSectionState extends State<LanguageSettingsSection> {
  var _selected = AppLanguage.uk;
  var _seeded = false;
  var _initial = AppLanguage.uk;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    _selected = HabitScope.of(context).language;
    _initial = _selected;
    _seeded = true;
  }

  bool get _dirty => _selected != _initial;

  Future<void> _save() async {
    await HabitScope.of(context).setLanguage(_selected);
    if (!mounted) return;
    showParentToast(widget.messenger, S.languageSaved);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSheetScaffold(
      title: S.languageTitle,
      hint: S.languageHint,
      dirty: _dirty,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final language in AppLanguage.values) _choice(language),
            const SizedBox(height: 2),
            FilledButton(
              key: const Key('save-language'),
              onPressed: _save,
              child: Text(S.save),
            ),
          ],
        ),
      ),
    );
  }

  Widget _choice(AppLanguage language) {
    final selected = _selected == language;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          key: Key('language-${language.code}'),
          onTap: () => setState(() => _selected = language),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? AppColors.pink : AppColors.blush,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    language.nativeName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_rounded, color: AppColors.pinkDark),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
