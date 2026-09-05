/// Knobs you will actually want to change.
class AppConfig {
  static const appName = 'Аксо';
  static const mascotName = 'Аксо';
  static const minPasswordLength = 4;
  static const defaultStartingPoints = 50;
  static const strikesToPenalty = 3;
  static const defaultPenaltyPoints = 10;
  static const defaultCompletionBonusEnabled = true;
  static const defaultCompletionBonusPoints = 10;

  static const timesTablesMin = 1;
  static const timesTablesMax = 10;

  static const defaultGameLimitEnabled = true;
  static const rewardedPlays = 5;
  static const playLimitMinutes = 15;
  static const playLimitWindow = Duration(minutes: playLimitMinutes);
  static const roundLength = 10;
  static const gamePlayPoints = 5;
  static const spellingRoundPoints = 5;
  static const timesTablesEasyPoints = 1;
  static const timesTablesNormalPoints = 3;
  static const timesTablesHardPoints = 5;
  static const englishOneWayPoints = 3;
  static const englishBothWaysPoints = 5;

  static const timesTablesGame = 'times_tables';
  static const spellingGame = 'spelling';
  static const englishGame = 'english';
  static const divisionGame = 'division';
  static const memoryGame = 'memory';
  static const memoryRoundPoints = 3;
  static const memoryPairs = 8;
  static const simonGame = 'simon';
  static const simonStartLength = 2;
  static const simonPads = 4;
  static const simonRoundPoints = 3;

  static const defaultTimerEnabled = true;
  static const timerDefaultMinutes = 5;
  static const timerMinMinutes = 1;
  static const timerMaxMinutes = 60;
  static const timerHistoryLimit = 100;
  static const timerPresetsMinutes = [1, 2, 5, 10, 15, 20, 30, 60];
}
