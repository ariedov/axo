import 'dart:convert';

import '../config.dart';
import 'today.dart';

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

  List<GamePlay> inWindow(
    DateTime now, {
    Duration window = AppConfig.playLimitWindow,
  }) {
    final start = now.subtract(window);
    return [
      for (final play in rounds)
        if (play.at.isAfter(start)) play,
    ];
  }

  int used(DateTime now) => inWindow(now).length;

  int usedToday(String gameId, DateTime now) {
    final day = todayStamp(now);
    var n = 0;
    for (final play in rounds) {
      if (play.gameId == gameId && todayStamp(play.at.toLocal()) == day) n++;
    }
    return n;
  }

  DateTime? unlocksAt(DateTime now) {
    final recent = inWindow(now);
    if (recent.length < AppConfig.rewardedPlays) return null;
    var oldest = recent.first.at;
    for (final play in recent) {
      if (play.at.isBefore(oldest)) oldest = play.at;
    }
    return oldest.add(AppConfig.playLimitWindow);
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
    final day = todayStamp(now);
    final cutoff = now.subtract(AppConfig.playLimitWindow);
    return GamePlaysSnapshot(
      rounds: [
        for (final play in rounds)
          if (todayStamp(play.at.toLocal()) == day || !play.at.isBefore(cutoff))
            play,
      ],
    );
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
