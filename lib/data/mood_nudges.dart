import '../config.dart';
import 'axo_state.dart';

/// When to tell the child Axo is proud. Only scheduled while the app is in
/// the background, so the celebration never interrupts the app itself.
DateTime? proudNudgeAt({
  required DateTime now,
  required bool fullToday,
  required bool inForeground,
  required bool enabled,
  required String today,
  required String? lastProudDay,
}) {
  if (!enabled || inForeground || !fullToday || lastProudDay == today) {
    return null;
  }
  return now.add(AppConfig.axoProudNudgeDelay);
}

/// A warm "I miss you" nudge after a few quiet days. Never mentions losing
/// a streak, and repeats at most once every [AppConfig.axoMissesRepeatDays].
DateTime? missesNudgeAt({
  required DateTime now,
  required bool enabled,
  required String? lastActiveDay,
  required String? lastMissesDay,
  required String today,
}) {
  if (!enabled || lastActiveDay == null) return null;
  if (daysSinceStamp(lastActiveDay, today) < AppConfig.axoMissesAfterDays) {
    return null;
  }
  if (lastMissesDay != null &&
      daysSinceStamp(lastMissesDay, today) < AppConfig.axoMissesRepeatDays) {
    return null;
  }
  final at = DateTime(now.year, now.month, now.day, AppConfig.axoMissesHour);
  return at.isAfter(now) ? at : at.add(const Duration(days: 1));
}

/// The evening reminder text becomes streak-aware only when there is still
/// something the child can do today.
bool shouldUseStreakNudge({
  required bool enabled,
  required int streak,
  required int pending,
}) {
  return enabled && streak > 0 && pending > 0;
}
