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
    final a = min + random.nextInt(max - min + 1);
    final b = min + random.nextInt(max - min + 1);
    if (random.nextBool()) {
      return DivisionProblem(dividend: a * b, divisor: a, answer: b);
    }
    return DivisionProblem(dividend: a * b, divisor: b, answer: a);
  }
}
