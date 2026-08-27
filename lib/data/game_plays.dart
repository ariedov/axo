import 'dart:convert';

import 'today.dart';

class GamePlaysSnapshot {
  const GamePlaysSnapshot({required this.day, required this.counts});

  final String day;
  final Map<String, int> counts;

  int used(String gameId) => counts[gameId] ?? 0;

  GamePlaysSnapshot increment(String gameId) {
    return GamePlaysSnapshot(
      day: day,
      counts: {...counts, gameId: used(gameId) + 1},
    );
  }

  Map<String, dynamic> toJson() => {'day': day, 'counts': counts};

  factory GamePlaysSnapshot.fromJson(Map<String, dynamic> json) {
    final raw = json['counts'] as Map<String, dynamic>? ?? {};
    return GamePlaysSnapshot(
      day: json['day'] as String,
      counts: {
        for (final entry in raw.entries) entry.key: (entry.value as num).toInt(),
      },
    );
  }

  factory GamePlaysSnapshot.empty([DateTime? now]) {
    return GamePlaysSnapshot(day: todayStamp(now), counts: const {});
  }
}

abstract class GamePlaysRepository {
  Future<GamePlaysSnapshot> loadToday();
  Future<void> save(GamePlaysSnapshot snapshot);
}

class LocalGamePlaysRepository implements GamePlaysRepository {
  LocalGamePlaysRepository(
    this._read,
    this._write, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  static const _key = 'game_plays';

  final Future<String?> Function(String key) _read;
  final Future<void> Function(String key, String value) _write;
  final DateTime Function() _now;

  @override
  Future<GamePlaysSnapshot> loadToday() async {
    final today = todayStamp(_now());
    final raw = await _read(_key);
    if (raw == null) return GamePlaysSnapshot(day: today, counts: const {});

    final saved = GamePlaysSnapshot.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
    if (saved.day == today) return saved;
    final rolled = GamePlaysSnapshot(day: today, counts: const {});
    await save(rolled);
    return rolled;
  }

  @override
  Future<void> save(GamePlaysSnapshot snapshot) {
    return _write(_key, jsonEncode(snapshot.toJson()));
  }
}

class InMemoryGamePlaysRepository implements GamePlaysRepository {
  InMemoryGamePlaysRepository([GamePlaysSnapshot? snapshot])
    : snapshot = snapshot ?? GamePlaysSnapshot.empty();

  GamePlaysSnapshot snapshot;

  @override
  Future<GamePlaysSnapshot> loadToday() async => snapshot;

  @override
  Future<void> save(GamePlaysSnapshot snapshot) async {
    this.snapshot = snapshot;
  }
}
