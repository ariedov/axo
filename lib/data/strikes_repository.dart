import 'dart:convert';

import '../config.dart';

class StrikeSnapshot {
  const StrikeSnapshot({
    this.count = 0,
    this.day,
    this.penaltyPoints = AppConfig.defaultPenaltyPoints,
  });

  final int count;
  final String? day;
  final int penaltyPoints;

  Map<String, dynamic> toJson() => {
    'count': count,
    'day': day,
    'penaltyPoints': penaltyPoints,
  };

  factory StrikeSnapshot.fromJson(Map<String, dynamic> json) {
    return StrikeSnapshot(
      count: (json['count'] as num?)?.toInt() ?? 0,
      day: json['day'] as String?,
      penaltyPoints:
          (json['penaltyPoints'] as num?)?.toInt() ??
          AppConfig.defaultPenaltyPoints,
    );
  }
}

abstract class StrikesRepository {
  Future<StrikeSnapshot> load();
  Future<void> save(StrikeSnapshot snapshot);
}

class LocalStrikesRepository implements StrikesRepository {
  LocalStrikesRepository(this._read, this._write);

  static const _key = 'strikes_state';

  final Future<String?> Function(String key) _read;
  final Future<void> Function(String key, String value) _write;

  @override
  Future<StrikeSnapshot> load() async {
    final raw = await _read(_key);
    if (raw == null) return const StrikeSnapshot();
    return StrikeSnapshot.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> save(StrikeSnapshot snapshot) {
    return _write(_key, jsonEncode(snapshot.toJson()));
  }
}

class InMemoryStrikesRepository implements StrikesRepository {
  InMemoryStrikesRepository([this.snapshot = const StrikeSnapshot()]);

  StrikeSnapshot snapshot;

  @override
  Future<StrikeSnapshot> load() async => snapshot;

  @override
  Future<void> save(StrikeSnapshot snapshot) async {
    this.snapshot = snapshot;
  }
}
