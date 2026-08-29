abstract class OnboardingFlags {
  Future<bool> isComplete();
  Future<void> markComplete();
  Future<void> setComplete(bool value);
}

class LocalOnboardingFlags implements OnboardingFlags {
  LocalOnboardingFlags(this._read, this._write);

  static const key = 'onboarding_complete';

  final Future<bool?> Function(String key) _read;
  final Future<void> Function(String key, bool value) _write;

  @override
  Future<bool> isComplete() async => await _read(key) ?? false;

  @override
  Future<void> markComplete() => setComplete(true);

  @override
  Future<void> setComplete(bool value) => _write(key, value);
}

class InMemoryOnboardingFlags implements OnboardingFlags {
  InMemoryOnboardingFlags([this.complete = false]);

  bool complete;

  @override
  Future<bool> isComplete() async => complete;

  @override
  Future<void> markComplete() => setComplete(true);

  @override
  Future<void> setComplete(bool value) async {
    complete = value;
  }
}
