import 'dart:convert';

import '../config.dart';

class GameLimitSnapshot {
  const GameLimitSnapshot({
    this.rewardedPlays = AppConfig.rewardedPlays,
    this.playLimitMinutes = AppConfig.playLimitMinutes,
  });

  final int rewardedPlays;
  final int playLimitMinutes;

  Map<String, dynamic> toJson() => {
    'rewardedPlays': rewardedPlays,
    'playLimitMinutes': playLimitMinutes,
  };

  factory GameLimitSnapshot.fromJson(Map<String, dynamic> json) {
    return GameLimitSnapshot(
      rewardedPlays:
          (json['rewardedPlays'] as num?)?.toInt() ?? AppConfig.rewardedPlays,
      playLimitMinutes:
          (json['playLimitMinutes'] as num?)?.toInt() ??
          AppConfig.playLimitMinutes,
    );
  }
}

abstract class GameLimitRepository {
  Future<GameLimitSnapshot> load();
  Future<void> save(GameLimitSnapshot snapshot);
}

class LocalGameLimitRepository implements GameLimitRepository {
  LocalGameLimitRepository(this._read, this._write);

  static const _key = 'game_limit';

  final Future<String?> Function(String key) _read;
  final Future<void> Function(String key, String value) _write;

  @override
  Future<GameLimitSnapshot> load() async {
    final raw = await _read(_key);
    if (raw == null) return const GameLimitSnapshot();
    return GameLimitSnapshot.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> save(GameLimitSnapshot snapshot) {
    return _write(_key, jsonEncode(snapshot.toJson()));
  }
}

class InMemoryGameLimitRepository implements GameLimitRepository {
  InMemoryGameLimitRepository([this.snapshot = const GameLimitSnapshot()]);

  GameLimitSnapshot snapshot;

  @override
  Future<GameLimitSnapshot> load() async => snapshot;

  @override
  Future<void> save(GameLimitSnapshot snapshot) async {
    this.snapshot = snapshot;
  }
}
