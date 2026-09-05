import 'dart:convert';

import '../config.dart';

enum TimerStatus { running, paused, completed, abandoned }

class TimerSession {
  const TimerSession({
    required this.id,
    required this.targetMillis,
    required this.startedAt,
    this.reason = '',
    this.elapsedMillis = 0,
    this.endedAt,
    this.runningSince,
    this.status = TimerStatus.running,
  });

  final String id;
  final String reason;
  final int targetMillis;
  final int elapsedMillis;
  final String startedAt;
  final String? endedAt;
  final String? runningSince;
  final TimerStatus status;

  Duration get target => Duration(milliseconds: targetMillis);

  bool get isOpen =>
      status == TimerStatus.running || status == TimerStatus.paused;

  bool get isRunning => status == TimerStatus.running;

  int elapsedMillisAt(DateTime now) {
    var ms = elapsedMillis;
    if (status == TimerStatus.running && runningSince != null) {
      final since = DateTime.tryParse(runningSince!);
      if (since != null) {
        ms += now.difference(since).inMilliseconds;
      }
    }
    if (ms < 0) return 0;
    if (ms > targetMillis) return targetMillis;
    return ms;
  }

  Duration elapsedAt(DateTime now) =>
      Duration(milliseconds: elapsedMillisAt(now));

  bool isFinishedAt(DateTime now) => elapsedMillisAt(now) >= targetMillis;

  TimerSession copyWith({
    String? reason,
    int? targetMillis,
    int? elapsedMillis,
    String? startedAt,
    String? endedAt,
    String? runningSince,
    TimerStatus? status,
    bool clearEndedAt = false,
    bool clearRunningSince = false,
  }) {
    return TimerSession(
      id: id,
      reason: reason ?? this.reason,
      targetMillis: targetMillis ?? this.targetMillis,
      elapsedMillis: elapsedMillis ?? this.elapsedMillis,
      startedAt: startedAt ?? this.startedAt,
      endedAt: clearEndedAt ? null : (endedAt ?? this.endedAt),
      runningSince: clearRunningSince
          ? null
          : (runningSince ?? this.runningSince),
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'reason': reason,
    'targetMillis': targetMillis,
    'elapsedMillis': elapsedMillis,
    'startedAt': startedAt,
    if (endedAt != null) 'endedAt': endedAt,
    if (runningSince != null) 'runningSince': runningSince,
    'status': status.name,
  };

  factory TimerSession.fromJson(Map<String, dynamic> json) {
    return TimerSession(
      id: json['id'] as String,
      reason: json['reason'] as String? ?? '',
      targetMillis: (json['targetMillis'] as num?)?.toInt() ?? 0,
      elapsedMillis: (json['elapsedMillis'] as num?)?.toInt() ?? 0,
      startedAt: json['startedAt'] as String? ?? '',
      endedAt: json['endedAt'] as String?,
      runningSince: json['runningSince'] as String?,
      status: TimerStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => TimerStatus.paused,
      ),
    );
  }
}

class TimerSnapshot {
  const TimerSnapshot({
    this.enabled = AppConfig.defaultTimerEnabled,
    this.active,
    this.history = const [],
  });

  final bool enabled;
  final TimerSession? active;
  final List<TimerSession> history;

  TimerSnapshot copyWith({
    bool? enabled,
    TimerSession? active,
    List<TimerSession>? history,
    bool clearActive = false,
  }) {
    return TimerSnapshot(
      enabled: enabled ?? this.enabled,
      active: clearActive ? null : (active ?? this.active),
      history: history ?? this.history,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    if (active != null) 'active': active!.toJson(),
    'history': [for (final session in history) session.toJson()],
  };

  factory TimerSnapshot.fromJson(Map<String, dynamic> json) {
    final rawActive = json['active'] as Map<String, dynamic>?;
    final rawHistory = json['history'] as List? ?? const [];
    return TimerSnapshot(
      enabled: json['enabled'] as bool? ?? AppConfig.defaultTimerEnabled,
      active: rawActive == null ? null : TimerSession.fromJson(rawActive),
      history: [
        for (final item in rawHistory)
          TimerSession.fromJson(item as Map<String, dynamic>),
      ],
    );
  }
}

abstract class TimerRepository {
  Future<TimerSnapshot> load();
  Future<void> save(TimerSnapshot snapshot);
}

class LocalTimerRepository implements TimerRepository {
  LocalTimerRepository(this._read, this._write);

  static const _key = 'timer';

  final Future<String?> Function(String key) _read;
  final Future<void> Function(String key, String value) _write;

  @override
  Future<TimerSnapshot> load() async {
    final raw = await _read(_key);
    if (raw == null) return const TimerSnapshot();
    return TimerSnapshot.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> save(TimerSnapshot snapshot) {
    return _write(_key, jsonEncode(snapshot.toJson()));
  }
}

class InMemoryTimerRepository implements TimerRepository {
  InMemoryTimerRepository([this.snapshot = const TimerSnapshot()]);

  TimerSnapshot snapshot;

  @override
  Future<TimerSnapshot> load() async => snapshot;

  @override
  Future<void> save(TimerSnapshot snapshot) async {
    this.snapshot = snapshot;
  }
}
