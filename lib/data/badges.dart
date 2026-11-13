/// Badges the child collects by using Axo: finishing tasks, keeping a streak,
/// writing down good things, playing games, and having perfect days.
enum BadgeKind {
  tasks,
  streak,
  goodThings,
  games,
  perfectDays,
  points,
  goals,
  activeDays,
  timerMinutes,
  goodStreak,
  perfectWeekends,
  daysWithAxo,
}

class HabitBadge {
  const HabitBadge({
    required this.kind,
    required this.target,
    required this.tier,
  });

  final BadgeKind kind;

  /// How much of [kind] is needed to earn the badge.
  final int target;

  /// 1-based position inside the kind, used for the badge name.
  final int tier;

  /// Stable id, safe to persist in a backup.
  String get id => '${kind.name}:$target';
}

const _thresholds = <BadgeKind, List<int>>{
  BadgeKind.tasks: [10, 100, 500, 1000, 2000, 5000, 10000],
  BadgeKind.streak: [5, 10, 25, 50, 100, 365],
  BadgeKind.goodThings: [1, 5, 10, 25, 50, 100, 250],
  BadgeKind.games: [10, 25, 50, 100, 250, 500, 1000],
  BadgeKind.perfectDays: [10, 25, 50, 100, 365],
  BadgeKind.points: [100, 500, 1000, 2500, 5000, 10000, 25000],
  BadgeKind.goals: [1, 3, 5, 10, 20],
  BadgeKind.activeDays: [10, 25, 50, 100, 200, 365],
  BadgeKind.timerMinutes: [30, 60, 120, 300, 600, 1200],
  BadgeKind.goodStreak: [3, 7, 14, 30, 100],
  BadgeKind.perfectWeekends: [1, 3, 10, 25, 50],
  BadgeKind.daysWithAxo: [7, 30, 100, 365, 730],
};

/// Every badge, ordered by kind and then by how hard it is.
final List<HabitBadge> badgeCatalog = [
  for (final kind in BadgeKind.values)
    for (var index = 0; index < _thresholds[kind]!.length; index++)
      HabitBadge(
        kind: kind,
        target: _thresholds[kind]![index],
        tier: index + 1,
      ),
];

List<HabitBadge> badgesOf(BadgeKind kind) => [
  for (final badge in badgeCatalog)
    if (badge.kind == kind) badge,
];

/// The next badge of [kind] still to earn, or null when all are collected.
HabitBadge? nextBadgeFor(BadgeKind kind, int value) {
  for (final badge in badgesOf(kind)) {
    if (value < badge.target) return badge;
  }
  return null;
}

/// Highest badge already earned for [value], or null when none is earned yet.
HabitBadge? earnedBadgeFor(BadgeKind kind, int value) {
  HabitBadge? earned;
  for (final badge in badgesOf(kind)) {
    if (value >= badge.target) earned = badge;
  }
  return earned;
}

/// What to show for [kind]: the highest earned badge, or the first one to aim
/// for when nothing is earned yet.
HabitBadge currentBadgeFor(BadgeKind kind, int value) =>
    earnedBadgeFor(kind, value) ?? badgesOf(kind).first;

/// Kinds ordered by how far the child has got: most tiers earned first, then
/// closest to the next badge.
List<BadgeKind> badgeKindsByAchievement(BadgeStats stats) {
  final kinds = [...BadgeKind.values];
  kinds.sort((a, b) {
    final byTier = _tierOf(b, stats).compareTo(_tierOf(a, stats));
    if (byTier != 0) return byTier;
    final byProgress = _progressOf(b, stats).compareTo(_progressOf(a, stats));
    if (byProgress != 0) return byProgress;
    return a.index - b.index;
  });
  return kinds;
}

int _tierOf(BadgeKind kind, BadgeStats stats) =>
    earnedBadgeFor(kind, stats.of(kind))?.tier ?? 0;

double _progressOf(BadgeKind kind, BadgeStats stats) {
  final value = stats.of(kind);
  final next = nextBadgeFor(kind, value);
  if (next == null) return 1;
  return value / next.target;
}

/// Counters a badge can be checked against.
class BadgeStats {
  const BadgeStats({
    this.tasks = 0,
    this.bestStreak = 0,
    this.goodThings = 0,
    this.games = 0,
    this.perfectDays = 0,
    this.points = 0,
    this.goals = 0,
    this.activeDays = 0,
    this.timerMinutes = 0,
    this.goodStreak = 0,
    this.perfectWeekends = 0,
    this.daysWithAxo = 0,
  });

  final int tasks;
  final int bestStreak;
  final int goodThings;
  final int games;
  final int perfectDays;
  final int points;
  final int goals;
  final int activeDays;
  final int timerMinutes;
  final int goodStreak;
  final int perfectWeekends;
  final int daysWithAxo;

  int of(BadgeKind kind) => switch (kind) {
    BadgeKind.tasks => tasks,
    BadgeKind.streak => bestStreak,
    BadgeKind.goodThings => goodThings,
    BadgeKind.games => games,
    BadgeKind.perfectDays => perfectDays,
    BadgeKind.points => points,
    BadgeKind.goals => goals,
    BadgeKind.activeDays => activeDays,
    BadgeKind.timerMinutes => timerMinutes,
    BadgeKind.goodStreak => goodStreak,
    BadgeKind.perfectWeekends => perfectWeekends,
    BadgeKind.daysWithAxo => daysWithAxo,
  };
}
