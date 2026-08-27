/// Backend hook: replace [LocalPointsRepository] with an API client later.
/// Gameplay should only increase points through [award].
abstract class PointsRepository {
  Future<int> fetchTotal();
  Future<int> award({required int amount, required String taskId});
  Future<int> setTotal(int amount);
  Future<int?> spend({required int amount, required String goalId});
}

class LocalPointsRepository implements PointsRepository {
  LocalPointsRepository(this._read, this._write);

  static const _key = 'points_total';

  final Future<int> Function(String key, int fallback) _read;
  final Future<void> Function(String key, int value) _write;

  @override
  Future<int> fetchTotal() => _read(_key, 0);

  @override
  Future<int> award({required int amount, required String taskId}) async {
    final next = await fetchTotal() + amount;
    await _write(_key, next);
    return next;
  }

  @override
  Future<int> setTotal(int amount) async {
    await _write(_key, amount);
    return amount;
  }

  @override
  Future<int?> spend({required int amount, required String goalId}) async {
    final current = await fetchTotal();
    if (amount <= 0 || current < amount) return null;
    final next = current - amount;
    await _write(_key, next);
    return next;
  }
}

class InMemoryPointsRepository implements PointsRepository {
  InMemoryPointsRepository([this.total = 0]);

  int total;

  @override
  Future<int> fetchTotal() async => total;

  @override
  Future<int> award({required int amount, required String taskId}) async {
    total += amount;
    return total;
  }

  @override
  Future<int> setTotal(int amount) async {
    total = amount;
    return total;
  }

  @override
  Future<int?> spend({required int amount, required String goalId}) async {
    if (amount <= 0 || total < amount) return null;
    total -= amount;
    return total;
  }
}
