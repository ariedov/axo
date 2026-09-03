import 'package:flutter/material.dart';

import '../strings.dart';
import '../theme.dart';

Future<T?> showParentSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: builder,
  );
}

Future<bool> confirmDiscardSettings(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Text(S.unsavedSettingsTitle),
      content: const Text(S.unsavedSettingsBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(S.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text(S.close),
        ),
      ],
    ),
  );
  return confirmed == true;
}

Future<void> closeSettings(
  BuildContext context, {
  required bool dirty,
}) async {
  if (dirty && !await confirmDiscardSettings(context)) return;
  if (context.mounted) Navigator.pop(context);
}

void showParentToast(ScaffoldMessengerState messenger, String text) {
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(content: Text(text)));
}

class SettingsSheetScaffold extends StatelessWidget {
  const SettingsSheetScaffold({
    super.key,
    required this.title,
    this.hint,
    this.actions = const [],
    required this.child,
    this.dirty = false,
  });

  final String title;
  final String? hint;
  final List<Widget> actions;
  final Widget child;
  final bool dirty;

  Future<void> _close(BuildContext context) =>
      closeSettings(context, dirty: dirty);

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;
    final inset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: SizedBox(
            height: maxHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.blush,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    ...actions,
                    IconButton(
                      key: const Key('settings-sheet-close'),
                      tooltip: S.close,
                      onPressed: () => _close(context),
                      icon: const Icon(Icons.close_rounded),
                      color: AppColors.muted,
                    ),
                  ],
                ),
                if (hint != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    hint!,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget reorderProxyDecorator(
  Widget child,
  int index,
  Animation<double> animation,
) {
  return AnimatedBuilder(
    animation: animation,
    builder: (context, child) {
      final t = Curves.easeOut.transform(animation.value);
      return Transform.scale(
        scale: 1 + (0.02 * t),
        child: Material(
          elevation: 8 * t,
          color: Colors.transparent,
          shadowColor: AppColors.pink.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(18),
          child: child,
        ),
      );
    },
    child: child,
  );
}
