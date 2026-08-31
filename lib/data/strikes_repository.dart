import '../config.dart';

abstract class StrikesRepository {
  Future<int> fetchStrikes();
  Future<int> setStrikes(int count);
  Future<int> fetchPenaltyPoints();
  Future<int> setPenaltyPoints(int amount);
}

class LocalStrikesRepository implements StrikesRepository {
  LocalStrikesRepository(this._read, this._write);

  static const strikesKey = 'strikes_count';
  static const penaltyKey = 'penalty_points';

  final Future<int> Function(String key, int fallback) _read;
  final Future<void> Function(String key, int value) _write;

  @override
  Future<int> fetchStrikes() => _read(strikesKey, 0);

  @override
  Future<int> setStrikes(int count) async {
    await _write(strikesKey, count);
    return count;
  }

  @override
  Future<int> fetchPenaltyPoints() =>
      _read(penaltyKey, AppConfig.defaultPenaltyPoints);

  @override
  Future<int> setPenaltyPoints(int amount) async {
    await _write(penaltyKey, amount);
    return amount;
  }
}

class InMemoryStrikesRepository implements StrikesRepository {
  InMemoryStrikesRepository({
    this.strikes = 0,
    this.penaltyPoints = AppConfig.defaultPenaltyPoints,
  });

  int strikes;
  int penaltyPoints;

  @override
  Future<int> fetchStrikes() async => strikes;

  @override
  Future<int> setStrikes(int count) async {
    strikes = count;
    return strikes;
  }

  @override
  Future<int> fetchPenaltyPoints() async => penaltyPoints;

  @override
  Future<int> setPenaltyPoints(int amount) async {
    penaltyPoints = amount;
    return penaltyPoints;
  }
}
