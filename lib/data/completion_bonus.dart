import 'dart:convert';

import '../config.dart';

class CompletionBonusSnapshot {
  const CompletionBonusSnapshot({
    this.enabled = AppConfig.defaultCompletionBonusEnabled,
    this.points = AppConfig.defaultCompletionBonusPoints,
  });

  final bool enabled;
  final int points;

  Map<String, dynamic> toJson() => {'enabled': enabled, 'points': points};

  factory CompletionBonusSnapshot.fromJson(Map<String, dynamic> json) {
    return CompletionBonusSnapshot(
      enabled:
          json['enabled'] as bool? ?? AppConfig.defaultCompletionBonusEnabled,
      points:
          (json['points'] as num?)?.toInt() ??
          AppConfig.defaultCompletionBonusPoints,
    );
  }
}

abstract class CompletionBonusRepository {
  Future<CompletionBonusSnapshot> load();
  Future<void> save(CompletionBonusSnapshot snapshot);
}

class LocalCompletionBonusRepository implements CompletionBonusRepository {
  LocalCompletionBonusRepository(this._read, this._write);

  static const _key = 'completion_bonus';

  final Future<String?> Function(String key) _read;
  final Future<void> Function(String key, String value) _write;

  @override
  Future<CompletionBonusSnapshot> load() async {
    final raw = await _read(_key);
    if (raw == null) return const CompletionBonusSnapshot();
    return CompletionBonusSnapshot.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> save(CompletionBonusSnapshot snapshot) {
    return _write(_key, jsonEncode(snapshot.toJson()));
  }
}

class InMemoryCompletionBonusRepository implements CompletionBonusRepository {
  InMemoryCompletionBonusRepository([
    this.snapshot = const CompletionBonusSnapshot(),
  ]);

  CompletionBonusSnapshot snapshot;

  @override
  Future<CompletionBonusSnapshot> load() async => snapshot;

  @override
  Future<void> save(CompletionBonusSnapshot snapshot) async {
    this.snapshot = snapshot;
  }
}
