abstract class ParentAuth {
  Future<String?> read();
  Future<void> write(String password);
}

class LocalParentAuth implements ParentAuth {
  LocalParentAuth(this._read, this._write);

  static const key = 'parent_password';

  final Future<String?> Function(String key) _read;
  final Future<void> Function(String key, String value) _write;

  @override
  Future<String?> read() => _read(key);

  @override
  Future<void> write(String password) => _write(key, password);
}

class InMemoryParentAuth implements ParentAuth {
  InMemoryParentAuth([this.password]);

  String? password;

  @override
  Future<String?> read() async => password;

  @override
  Future<void> write(String password) async {
    this.password = password;
  }
}
