import '../config.dart';

class GameRound {
  int correct = 0;
  int wrong = 0;

  int get answered => correct + wrong;

  bool get isComplete => answered >= AppConfig.roundLength;

  void record(bool success) {
    if (success) {
      correct += 1;
    } else {
      wrong += 1;
    }
  }

  void reset() {
    correct = 0;
    wrong = 0;
  }
}
