class TimesTablesProblem {
  const TimesTablesProblem(this.a, this.b);

  final int a;
  final int b;

  int get answer => a * b;

  static List<TimesTablesProblem> all(int min, int max) {
    return [
      for (var a = min; a <= max; a++)
        for (var b = min; b <= max; b++) TimesTablesProblem(a, b),
    ];
  }

  @override
  bool operator ==(Object other) =>
      other is TimesTablesProblem && a == other.a && b == other.b;

  @override
  int get hashCode => Object.hash(a, b);
}
