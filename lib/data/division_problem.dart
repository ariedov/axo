import 'dart:math';

class DivisionProblem {
  const DivisionProblem({
    required this.dividend,
    required this.divisor,
    required this.answer,
  });

  final int dividend;
  final int divisor;
  final int answer;

  factory DivisionProblem.generate(Random random, int min, int max) {
    final pool = all(min, max);
    return pool[random.nextInt(pool.length)];
  }

  static List<DivisionProblem> all(int min, int max) {
    return [
      for (var a = min; a <= max; a++)
        for (var b = min; b <= max; b++)
          DivisionProblem(dividend: a * b, divisor: a, answer: b),
    ];
  }

  @override
  bool operator ==(Object other) =>
      other is DivisionProblem &&
      dividend == other.dividend &&
      divisor == other.divisor;

  @override
  int get hashCode => Object.hash(dividend, divisor);
}
