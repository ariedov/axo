import 'dart:convert';

import '../config.dart';

class GamePlay {
  const GamePlay({required this.gameId, required this.at});

  final String gameId;
  final DateTime at;

  Map<String, dynamic> toJson() => {
    'gameId': gameId,
    'at': at.toUtc().toIso8601String(),
  };

  factory GamePlay.fromJson(Map<String, dynamic> json) {
    return GamePlay(
      gameId: json['gameId'] as String,
      at: DateTime.parse(json['at'] as String),
    );
  }
}

class GamePlaysSnapshot {
  const GamePlaysSnapshot({this.rounds = const []});

  final List<GamePlay> rounds;

  List<GamePlay> currentBatch(
    DateTime now, {
    Duration window = AppConfig.playLimitWindow,
    int cap = AppConfig.rewardedPlays,
  }) {
    var remaining = rounds;
    while (remaining.length >= cap) {
      final unlock = remaining[cap - 1].at.add(window);
      if (now.isBefore(unlock)) {
        return remaining.sublist(0, cap);
      }
      remaining = remaining.sublist(cap);
    }
    return remaining;
  }

  int used(DateTime now) => currentBatch(now).length;

  DateTime? unlocksAt(DateTime now) {
    final batch = currentBatch(now);
    if (batch.length < AppConfig.rewardedPlays) return null;
    return batch.last.at.add(AppConfig.playLimitWindow);
  }

  GamePlaysSnapshot increment(String gameId, DateTime at) {
    return GamePlaysSnapshot(
      rounds: [
        ...rounds,
        GamePlay(gameId: gameId, at: at),
      ],
    );
  }

  GamePlaysSnapshot pruned(DateTime now) {
    return GamePlaysSnapshot(rounds: currentBatch(now));
  }

  Map<String, dynamic> toJson() => {
    'rounds': [for (final play in rounds) play.toJson()],
  };

  factory GamePlaysSnapshot.fromJson(Map<String, dynamic> json) {
    final raw = json['rounds'];
    if (raw is! List) return const GamePlaysSnapshot();
    return GamePlaysSnapshot(
      rounds: [
        for (final item in raw) GamePlay.fromJson(item as Map<String, dynamic>),
      ],
    );
  }

  factory GamePlaysSnapshot.empty() => const GamePlaysSnapshot();
}

abstract class GamePlaysRepository {
  Future<GamePlaysSnapshot> load();
  Future<void> save(GamePlaysSnapshot snapshot);
}

class LocalGamePlaysRepository implements GamePlaysRepository {
  LocalGamePlaysRepository(this._read, this._write, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static const _key = 'game_plays';

  final Future<String?> Function(String key) _read;
  final Future<void> Function(String key, String value) _write;
  final DateTime Function() _now;

  @override
  Future<GamePlaysSnapshot> load() async {
    final raw = await _read(_key);
    if (raw == null) return const GamePlaysSnapshot();

    final saved = GamePlaysSnapshot.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
    final pruned = saved.pruned(_now());
    if (pruned.rounds.length != saved.rounds.length) {
      await save(pruned);
    }
    return pruned;
  }

  @override
  Future<void> save(GamePlaysSnapshot snapshot) {
    return _write(_key, jsonEncode(snapshot.toJson()));
  }
}

class InMemoryGamePlaysRepository implements GamePlaysRepository {
  InMemoryGamePlaysRepository([GamePlaysSnapshot? snapshot])
    : snapshot = snapshot ?? const GamePlaysSnapshot();

  GamePlaysSnapshot snapshot;

  @override
  Future<GamePlaysSnapshot> load() async => snapshot;

  @override
  Future<void> save(GamePlaysSnapshot snapshot) async {
    this.snapshot = snapshot;
  }
}
