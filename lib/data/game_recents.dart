import 'dart:convert';

abstract class GameRecentsRepository {
  Future<List<String>> load();
  Future<void> save(List<String> ids);
}

class LocalGameRecentsRepository implements GameRecentsRepository {
  LocalGameRecentsRepository(this._read, this._write);

  static const _key = 'game_recents';

  final Future<String?> Function(String key) _read;
  final Future<void> Function(String key, String value) _write;

  @override
  Future<List<String>> load() async {
    final raw = await _read(_key);
    if (raw == null) return const [];
    final json = jsonDecode(raw);
    if (json is List) {
      return [for (final id in json) id as String];
    }
    final ids = (json as Map<String, dynamic>)['ids'] as List<dynamic>? ?? [];
    return [for (final id in ids) id as String];
  }

  @override
  Future<void> save(List<String> ids) {
    return _write(_key, jsonEncode({'ids': ids}));
  }
}

class InMemoryGameRecentsRepository implements GameRecentsRepository {
  InMemoryGameRecentsRepository([this.ids = const []]);

  List<String> ids;

  @override
  Future<List<String>> load() async => ids;

  @override
  Future<void> save(List<String> ids) async {
    this.ids = ids;
  }
}
