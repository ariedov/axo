/// Parent's language choice. Null means "follow the device".
abstract class LanguageRepository {
  Future<String?> load();
  Future<void> save(String code);
}

class LocalLanguageRepository implements LanguageRepository {
  LocalLanguageRepository(this._read, this._write);

  static const key = 'language';

  final Future<String?> Function(String key) _read;
  final Future<void> Function(String key, String value) _write;

  @override
  Future<String?> load() => _read(key);

  @override
  Future<void> save(String code) => _write(key, code);
}

class InMemoryLanguageRepository implements LanguageRepository {
  InMemoryLanguageRepository([this.code]);

  String? code;

  @override
  Future<String?> load() async => code;

  @override
  Future<void> save(String code) async {
    this.code = code;
  }
}
