import 'package:flutter/material.dart';

import 'habit_store.dart';

class HabitScope extends InheritedNotifier<HabitStore> {
  const HabitScope({
    super.key,
    required HabitStore store,
    required super.child,
  }) : super(notifier: store);

  static HabitStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<HabitScope>();
    assert(scope != null, 'HabitScope not found');
    return scope!.notifier!;
  }
}
