import 'dart:math';

class TimesTablesProblem {
  const TimesTablesProblem(this.a, this.b);

  final int a;
  final int b;

  int get answer => a * b;

  factory TimesTablesProblem.generate(Random random, int min, int max) {
    final a = min + random.nextInt(max - min + 1);
    final b = min + random.nextInt(max - min + 1);
    return TimesTablesProblem(a, b);
  }

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
