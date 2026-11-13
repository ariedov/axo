import 'dart:convert';

/// Earned badges (id → day stamp) plus counters that cannot be rebuilt from
/// other history, such as game rounds played, points earned, and timer focus.
class Achievements {
  const Achievements({
    this.earned = const {},
    this.gamesPlayed = 0,
    this.pointsEarned = 0,
    this.timerMinutes = 0,
  });

  final Map<String, String> earned;
  final int gamesPlayed;
  final int pointsEarned;
  final int timerMinutes;

  String? earnedOn(String badgeId) => earned[badgeId];

  Achievements copyWith({
    Map<String, String>? earned,
    int? gamesPlayed,
    int? pointsEarned,
    int? timerMinutes,
  }) {
    return Achievements(
      earned: earned ?? this.earned,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      timerMinutes: timerMinutes ?? this.timerMinutes,
    );
  }

  Map<String, dynamic> toJson() => {
    'earned': earned,
    'gamesPlayed': gamesPlayed,
    'pointsEarned': pointsEarned,
    'timerMinutes': timerMinutes,
  };

  factory Achievements.fromJson(Map<String, dynamic> json) {
    final raw = json['earned'];
    final earned = <String, String>{};
    if (raw is Map) {
      for (final entry in raw.entries) {
        final day = entry.value;
        if (day is String && day.isNotEmpty) earned['${entry.key}'] = day;
      }
    }
    return Achievements(
      earned: earned,
      gamesPlayed: _count(json['gamesPlayed']),
      pointsEarned: _count(json['pointsEarned']),
      timerMinutes: _count(json['timerMinutes']),
    );
  }

  static int _count(Object? raw) {
    final value = (raw as num?)?.toInt() ?? 0;
    return value < 0 ? 0 : value;
  }
}

abstract class AchievementsRepository {
  Future<Achievements> load();
  Future<void> save(Achievements achievements);
}

class LocalAchievementsRepository implements AchievementsRepository {
  LocalAchievementsRepository(this._read, this._write);

  static const _key = 'achievements';

  final Future<String?> Function(String key) _read;
  final Future<void> Function(String key, String value) _write;

  @override
  Future<Achievements> load() async {
    final raw = await _read(_key);
    if (raw == null) return const Achievements();
    return Achievements.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> save(Achievements achievements) {
    return _write(_key, jsonEncode(achievements.toJson()));
  }
}

class InMemoryAchievementsRepository implements AchievementsRepository {
  InMemoryAchievementsRepository([Achievements? achievements])
    : achievements = achievements ?? const Achievements();

  Achievements achievements;

  @override
  Future<Achievements> load() async => achievements;

  @override
  Future<void> save(Achievements achievements) async {
    this.achievements = achievements;
  }
}
