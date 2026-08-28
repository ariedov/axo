abstract class OnboardingFlags {
  Future<bool> isComplete();
  Future<void> markComplete();
}

class LocalOnboardingFlags implements OnboardingFlags {
  LocalOnboardingFlags(this._read, this._write);

  static const key = 'onboarding_complete';

  final Future<bool?> Function(String key) _read;
  final Future<void> Function(String key, bool value) _write;

  @override
  Future<bool> isComplete() async => await _read(key) ?? false;

  @override
  Future<void> markComplete() => _write(key, true);
}

class InMemoryOnboardingFlags implements OnboardingFlags {
  InMemoryOnboardingFlags([this.complete = false]);

  bool complete;

  @override
  Future<bool> isComplete() async => complete;

  @override
  Future<void> markComplete() async {
    complete = true;
  }
}
