import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

Future<void> setScreenWake(bool on) async {
  try {
    await WakelockPlus.toggle(enable: on);
  } on MissingPluginException {
    return;
  } on PlatformException {
    return;
  }
}
