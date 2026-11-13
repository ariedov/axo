import 'dart:convert';

import '../config.dart';
import 'axo_mood.dart';
import 'today.dart';

enum AxoAction { submit, verify, allDone, game, timer, highlight, strike }

/// Things Axo noticed today. Kept per day so caps reset at midnight and the
/// tally can be inspected by tests without replaying every event.
class AxoDayTally {
  const AxoDayTally({
    this.submitted = 0,
    this.verified = 0,
    this.scoredRounds = 0,
    this.timerSessions = 0,
    this.highlight = false,
    this.allDone = false,
  });

  final int submitted;
  final int verified;
  final int scoredRounds;
  final int timerSessions;
  final bool highlight;
  final bool allDone;

  AxoDayTally copyWith({
    int? submitted,
    int? verified,
    int? scoredRounds,
    int? timerSessions,
    bool? highlight,
    bool? allDone,
  }) {
    return AxoDayTally(
      submitted: submitted ?? this.submitted,
      verified: verified ?? this.verified,
      scoredRounds: scoredRounds ?? this.scoredRounds,
      timerSessions: timerSessions ?? this.timerSessions,
      highlight: highlight ?? this.highlight,
      allDone: allDone ?? this.allDone,
    );
  }

  Map<String, dynamic> toJson() => {
    'submitted': submitted,
    'verified': verified,
    'scoredRounds': scoredRounds,
    'timerSessions': timerSessions,
    'highlight': highlight,
    'allDone': allDone,
  };

  factory AxoDayTally.fromJson(Map<String, dynamic> json) {
    return AxoDayTally(
      submitted: (json['submitted'] as num?)?.toInt() ?? 0,
      verified: (json['verified'] as num?)?.toInt() ?? 0,
      scoredRounds: (json['scoredRounds'] as num?)?.toInt() ?? 0,
      timerSessions: (json['timerSessions'] as num?)?.toInt() ?? 0,
      highlight: json['highlight'] == true,
      allDone: json['allDone'] == true,
    );
  }
}

/// Axo's long-term bond with the child and today's energy.
///
/// Bond is deliberately slow and never decays, so a quiet week does not make
/// the companion feel broken. Energy resets every morning and drives the
/// sleepy/encouraging mood during the day.
class AxoState {
  const AxoState({
    this.bond = 20,
    this.energy = AppConfig.axoMorningEnergy,
    this.day,
    this.lastActiveDay,
    this.tally = const AxoDayTally(),
  });

  final int bond;
  final int energy;
  final String? day;
  final String? lastActiveDay;
  final AxoDayTally tally;

  AxoState startingDay(String today) {
    if (day == today) return this;
    return AxoState(
      bond: bond,
      energy: AppConfig.axoMorningEnergy,
      day: today,
      lastActiveDay: lastActiveDay,
      tally: const AxoDayTally(),
    );
  }

  AxoState resetDay(String today) {
    return AxoState(
      bond: bond,
      energy: AppConfig.axoMorningEnergy,
      day: today,
      lastActiveDay: lastActiveDay,
      tally: const AxoDayTally(),
    );
  }

  /// Applies one action. Returns the same instance when the daily cap is
  /// already reached, so callers can skip writing to disk.
  AxoState apply(AxoAction action, {required String today, int minutes = 0}) {
    final base = startingDay(today);
    switch (action) {
      case AxoAction.submit:
        return base._next(
          bond: _up(base.bond, 2),
          energy: _up(base.energy, 8),
          lastActiveDay: today,
          tally: base.tally.copyWith(submitted: base.tally.submitted + 1),
        );
      case AxoAction.verify:
        return base._next(
          bond: _up(base.bond, 3),
          energy: _up(base.energy, 5),
          lastActiveDay: today,
          tally: base.tally.copyWith(verified: base.tally.verified + 1),
        );
      case AxoAction.allDone:
        if (base.tally.allDone) return base;
        return base._next(
          bond: _up(base.bond, 8),
          energy: 100,
          lastActiveDay: today,
          tally: base.tally.copyWith(allDone: true),
        );
      case AxoAction.game:
        if (base.tally.scoredRounds >= AppConfig.axoScoredGamesPerDay) {
          return base;
        }
        return base._next(
          bond: _up(base.bond, 1),
          energy: _up(base.energy, 4),
          lastActiveDay: today,
          tally: base.tally.copyWith(scoredRounds: base.tally.scoredRounds + 1),
        );
      case AxoAction.timer:
        if (minutes < AppConfig.axoTimerMinMinutes ||
            base.tally.timerSessions >= AppConfig.axoTimerSessionsPerDay) {
          return base;
        }
        return base._next(
          bond: _up(base.bond, 2),
          energy: _up(base.energy, 4),
          lastActiveDay: today,
          tally: base.tally.copyWith(
            timerSessions: base.tally.timerSessions + 1,
          ),
        );
      case AxoAction.highlight:
        if (base.tally.highlight) return base;
        return base._next(
          bond: _up(base.bond, 2),
          lastActiveDay: today,
          tally: base.tally.copyWith(highlight: true),
        );
      case AxoAction.strike:
        return base._next(
          bond: _down(base.bond, 6),
          energy: _down(base.energy, 20),
          tally: base.tally,
        );
    }
  }

  AxoState _next({
    int? bond,
    int? energy,
    String? lastActiveDay,
    AxoDayTally? tally,
  }) {
    return AxoState(
      bond: bond ?? this.bond,
      energy: energy ?? this.energy,
      day: day,
      lastActiveDay: lastActiveDay ?? this.lastActiveDay,
      tally: tally ?? this.tally,
    );
  }

  static int _up(int value, int amount) {
    final next = value + amount;
    return next > 100 ? 100 : next;
  }

  static int _down(int value, int amount) {
    final next = value - amount;
    return next < 0 ? 0 : next;
  }

  Map<String, dynamic> toJson() => {
    'bond': bond,
    'energy': energy,
    'day': day,
    'lastActiveDay': lastActiveDay,
    'tally': tally.toJson(),
  };

  factory AxoState.fromJson(Map<String, dynamic> json) {
    final tally = json['tally'];
    return AxoState(
      bond: (json['bond'] as num?)?.toInt() ?? 20,
      energy: (json['energy'] as num?)?.toInt() ?? AppConfig.axoMorningEnergy,
      day: json['day'] as String?,
      lastActiveDay: json['lastActiveDay'] as String?,
      tally: tally is Map<String, dynamic>
          ? AxoDayTally.fromJson(tally)
          : const AxoDayTally(),
    );
  }
}

/// Pure mood rules, kept out of [HabitStore] so they are easy to test.
AxolotlMood axoMoodFor({
  required AxoState state,
  required bool celebrating,
  required int pending,
  required int waiting,
  required int verified,
  required int daysSinceActive,
}) {
  if (celebrating || (pending == 0 && waiting == 0 && verified > 0)) {
    return AxolotlMood.celebrate;
  }
  if (daysSinceActive >= AppConfig.axoMissesAfterDays) {
    return AxolotlMood.misses;
  }
  if (pending == 0 && waiting > 0) return AxolotlMood.waiting;
  if (pending == 0 && waiting == 0) return AxolotlMood.happy;
  if (state.energy < AppConfig.axoSleepyBelowEnergy) {
    return AxolotlMood.sleepy;
  }
  return AxolotlMood.encouraging;
}

abstract class AxoRepository {
  Future<AxoState> load();
  Future<void> save(AxoState state);
}

class LocalAxoRepository implements AxoRepository {
  LocalAxoRepository(this._read, this._write);

  static const _key = 'axo_state';

  final Future<String?> Function(String key) _read;
  final Future<void> Function(String key, String value) _write;

  @override
  Future<AxoState> load() async {
    final raw = await _read(_key);
    if (raw == null) return const AxoState();
    return AxoState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> save(AxoState state) {
    return _write(_key, jsonEncode(state.toJson()));
  }
}

class InMemoryAxoRepository implements AxoRepository {
  InMemoryAxoRepository([this.state = const AxoState()]);

  AxoState state;

  @override
  Future<AxoState> load() async => state;

  @override
  Future<void> save(AxoState state) async {
    this.state = state;
  }
}

/// Days between two day stamps (YYYY-MM-DD), using local calendar dates.
int daysSinceStamp(String? from, String to) {
  if (from == null) return 0;
  final start = dateFromStamp(from);
  final end = dateFromStamp(to);
  final days = DateTime(
    end.year,
    end.month,
    end.day,
  ).difference(DateTime(start.year, start.month, start.day)).inDays;
  return days < 0 ? 0 : days;
}
