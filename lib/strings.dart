import 'config.dart';
import 'data/app_language.dart';

/// UI copy. [language] is Ukrainian unless the device locale or a parent
/// setting says otherwise. Call sites keep using `S.foo`.
class S {
  static AppLanguage language = AppLanguage.uk;

  static bool get isEnglish => language == AppLanguage.en;

  static String _t(String uk, String en) => isEnglish ? en : uk;

  static String get appName => _t(AppConfig.appName, 'Axo');
  static String get hello => _t('Привіт!', 'Hi!');
  static String get todaysTasks => _t('Завдання на сьогодні', 'Today\'s tasks');
  static String get miniGames => _t('Міні-ігри', 'Mini-games');
  static String get allGames => _t('Усі ігри', 'All games');
  static String get timesTables => _t('Множення', 'Times tables');
  static String get timesTablesHint => _t('Порахуй', 'Work it out');
  static String get spelling => _t('Правопис', 'Spelling');
  static String get spellingHint => _t('Напиши слово', 'Write the word');
  static String get english => _t('Англійська', 'English');
  static String get englishHint => _t('Переклади', 'Translate');
  static String get division => _t('Ділення', 'Division');
  static String get divisionHint => _t('Поділи', 'Divide');
  static String get memory => _t('Пам\'ять', 'Memory');
  static String get memoryHint => _t('Знайди пару', 'Find a pair');
  static String get simon => _t('Повторюй', 'Repeat');
  static String get simonHint =>
      _t('Запам\'ятай порядок', 'Remember the order');
  static String get simonWatch => _t('Дивись', 'Watch');
  static String get simonYourTurn => _t('Твій хід', 'Your turn');
  static String get translateToUk =>
      _t('Як українською?', 'How do you say it in Ukrainian?');
  static String get translateToEn =>
      _t('Як англійською?', 'How do you say it in English?');
  static String get bothWays => _t('Обидва', 'Both ways');
  static String get enLang => 'EN';
  static String get uaLang => 'UA';
  static String get done => _t('Зробив!', 'Done!');
  static String get waiting => _t('Чекає маму чи тата', 'Waiting for a parent');
  static String get verified => _t('Підтверджено', 'Approved');
  static String get verify => _t('Перевірити', 'Check');
  static String get notYet => _t('Ще не готово', 'Not yet');
  static String get parentTitle => _t('Для мами і тата', 'For parents');
  static String get parentPrompt => _t(
    'Введи пароль, щоб підтвердити завдання',
    'Enter the password to approve the task',
  );
  static String get passwordHint => _t('Пароль', 'Password');
  static String get wrongPassword =>
      _t('Неправильний пароль', 'Wrong password');
  static String get awardPoints => _t('Нарахувати бали', 'Award points');
  static String get sendBack => _t('Повернути', 'Send back');
  static String get approveCompleted =>
      _t('Підтвердити виконані', 'Approve finished tasks');
  static String get approveCompletedPrompt => _t(
    'Введи пароль, щоб підтвердити виконані завдання',
    'Enter the password to approve finished tasks',
  );
  static String get cancel => _t('Скасувати', 'Cancel');
  static String get addTask => _t('Додати завдання', 'Add a task');
  static String get addTodayTaskPrompt => _t(
    'Введи пароль, щоб додати завдання на сьогодні',
    'Enter the password to add a task for today',
  );
  static String get addDailyTaskPrompt => _t(
    'Введи пароль, щоб додати завдання',
    'Enter the password to add a task',
  );
  static String get editTask => _t('Змінити завдання', 'Edit task');
  static String get taskTitle => _t('Назва', 'Name');
  static String get taskPoints => _t('Бали', 'Points');
  static String get save => _t('Зберегти', 'Save');
  static String get close => _t('Закрити', 'Close');
  static String get delete => _t('Видалити', 'Delete');
  static String get off => _t('Вимкнено', 'Off');
  static String get unsavedSettingsTitle =>
      _t('Налаштування не збережено', 'Settings not saved');
  static String get unsavedSettingsBody =>
      _t('Точно хочете закрити?', 'Close without saving?');
  static String get howMany => _t('Скільки буде?', 'What is the answer?');
  static String get check => _t('Перевірити', 'Check');
  static String get correct => _t('Молодець!', 'Well done!');
  static String get tryAgain => _t('Спробуй ще раз', 'Try again');
  static String get keepGoing => _t('Давай далі!', 'Keep going!');
  static String get writeTheWord => _t('Напиши слово', 'Write the word');
  static String get next => _t('Далі', 'Next');
  static String get easy => _t('Легко', 'Easy');
  static String get normal => _t('Нормально', 'Normal');
  static String get hard => _t('Складно', 'Hard');
  static String get allDone =>
      _t('Усі завдання на сьогодні готові!', 'All of today\'s tasks are done!');

  static String practiceOnly(int rounds, int minutes) => _t(
    'Можна зіграти ${roundsWord(rounds)}, далі ${minutesWord(minutes)} перерви. У раунді — 10 завдань.',
    'You can play ${roundsWord(rounds)}, then take a break of ${minutesWord(minutes)}. Each round has 10 challenges.',
  );

  static String get gamePointsLeft => _t('Зіграно раундів', 'Rounds played');

  static String gamePointsGone(int rounds) => _t(
    'Наступні ${roundsWord(rounds)} через',
    'Next ${roundsWord(rounds)} in',
  );

  static String gameRoundsProgress(int used, int max) => '$used/$max';

  static String countdown(Duration d) {
    final seconds = d.isNegative ? 0 : d.inSeconds;
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  static String nextRoundsLabel(int rounds) =>
      _t('Наступні ${roundsWord(rounds)}: ', 'Next ${roundsWord(rounds)}: ');

  static String nextRoundsAt(int rounds, Duration d) =>
      '${nextRoundsLabel(rounds)}${countdown(d)}';

  static String get plusGamePoints => _t('балів за гру', 'points for the game');
  static String get roundDone => _t('Раунд завершено!', 'Round complete!');
  static String get correctCount => _t('Правильно', 'Correct');
  static String get wrongCount => _t('Неправильно', 'Wrong');
  static String get practiceMode => _t('Тренування', 'Practice');
  static String get parentSection =>
      _t('Батьківський розділ', 'Parent section');
  static String get parentSectionPrompt => _t(
    'Введи пароль, щоб відкрити налаштування',
    'Enter the password to open settings',
  );
  static String get onboardingHello => _t('Привіт! Я Аксо.', 'Hi! I\'m Axo.');
  static String get onboardingParentsBody => _t(
    'Цей розділ — для мами і тата. Тут ви налаштуєте додаток, перш ніж віддати телефон дитині.',
    'This section is for parents. Set up the app here before handing the phone to your child.',
  );
  static String get onboardingBody => _t(
    'Мама або тато: скільки балів дати на старт і, за бажанням, пароль. Паролем ви підтверджуватимете завдання.',
    'Choose starting points and, optionally, a password. You\'ll use it to approve tasks.',
  );
  static String get onboardingPrivacy => _t(
    'Усі дані лишаються на цьому пристрої. Без реклами, без акаунтів і без інтернету.',
    'All data stays on this device. No ads, no accounts, and no internet.',
  );
  static String get onboardingGoalHello =>
      _t('За що збираємо бали?', 'What are the points for?');
  static String get onboardingGoalBody => _t(
    'На що дитина збиратиме бали? Можна поставити нову ціль тут.',
    'Add a goal for your child to save up for.',
  );
  static String get onboardingDoneHello => _t('Усе готово!', 'All set!');
  static String get onboardingDoneBody => _t(
    'Налаштування завершено. Далі Аксо — для дитини: завдання, ігри й цілі. Батьківський розділ можна захистити паролем.',
    'Axo is now ready for your child: tasks, games, and goals. You can protect the parent section with a password.',
  );
  static String get understood => _t('Зрозуміло', 'Got it');
  static String get choosePassword =>
      _t('Придумайте пароль', 'Choose a password');
  static String get repeatPassword =>
      _t('Повторіть пароль', 'Repeat the password');
  static String get skipPasswordTitle => _t('Без пароля?', 'No password?');
  static String get skipPasswordBody => _t(
    'Можна продовжити без пароля. Його можна створити пізніше в батьківському розділі.',
    'You can continue without a password and add one later in the parent section.',
  );
  static String get startingPoints => _t('Початкові бали', 'Starting points');
  static String get invalidPoints =>
      _t('Вкажіть ціле число балів', 'Enter a whole number of points');
  static String get passwordTooShort =>
      _t('Щонайменше 4 символи', 'At least 4 characters');
  static String get passwordsDontMatch =>
      _t('Паролі не збігаються', 'Passwords do not match');
  static String get letsGo => _t('Поїхали!', 'Let\'s go!');
  static String get pickGameMode => _t('Оберіть режим', 'Choose a mode');

  static String pointsPerRound(int n) =>
      _t('${pointsWord(n)} за раунд', '${pointsWord(n)} per round');

  static String get ok => _t('Гаразд', 'OK');
  static String get newPassword => _t('Новий пароль', 'New password');
  static String get passwordChanged => _t('Пароль змінено', 'Password changed');
  static String get passwordOff => _t('Пароль вимкнено', 'Password turned off');
  static String get changePassword => _t('Змінити пароль', 'Change password');
  static String get parentPassword =>
      _t('Батьківський пароль', 'Parent password');
  static String get parentPasswordHint => _t(
    'Пароль захищає батьківський розділ і підтвердження завдань. Можна вимкнути.',
    'The password protects the parent section and task approval. You can turn it off.',
  );
  static String get passwordEnabled =>
      _t('Вимагати пароль', 'Require a password');
  static String get bonusPoints => _t('Бонус і штраф', 'Bonus and penalty');
  static String get bonusPointsHint => _t(
    'Нарахуйте або зніміть будь-яку кількість балів.',
    'Add or remove any number of points.',
  );
  static String get bonusPointsSubtitle =>
      _t('Додати або зняти бали', 'Add or remove points');
  static String get bonusPointsPrompt => _t(
    'Введи пароль, щоб нарахувати або зняти бали',
    'Enter the password to add or remove points',
  );
  static String get addPoints => _t('Додати', 'Add');
  static String get removePoints => _t('Зняти', 'Remove');
  static String get pointsAmount => _t('Скільки балів', 'How many points');

  static String pointsNow(int n) =>
      _t('Зараз ${pointsWord(n)}', 'Balance: ${pointsWord(n)}');

  static String pointsAdjusted(int delta) {
    if (delta > 0) {
      return _t(
        'Нараховано ${pointsWord(delta)}',
        'Added ${pointsWord(delta)}',
      );
    }
    return _t('Знято ${pointsWord(-delta)}', 'Removed ${pointsWord(-delta)}');
  }

  static String get noPointsToRemove =>
      _t('Немає балів, щоб зняти', 'No points to remove');
  static String get strikes => _t('Страйки', 'Strikes');
  static String get strike => _t('Страйк', 'Strike');
  static String get strikePrompt => _t(
    'Введи пароль, щоб дати страйк',
    'Enter the password to give a strike',
  );
  static String get penaltySettings => _t('Штраф за страйки', 'Strike penalty');
  static String get penaltySettingsHint => _t(
    'Після трьох страйків бали знімаються, а лічильник лишається 3 з 3 до наступного дня.',
    'After three strikes, points are removed, and the counter stays at 3 of 3 until the next day.',
  );
  static String get penaltyPoints => _t('Штраф у балах', 'Penalty in points');
  static String get penaltySaved => _t('Штраф збережено', 'Penalty saved');
  static String get clearStrikes => _t('Скинути страйки', 'Clear strikes');
  static String get strikesCleared => _t('Страйки скинуто', 'Strikes cleared');
  static String get invalidPenalty =>
      _t('Вкажіть ціле число балів', 'Enter a whole number of points');
  static String get gameLimitSettings => _t('Ліміт ігор', 'Game limit');
  static String get gameLimitSettingsHint => _t(
    'Скільки раундів можна зіграти підряд і скільки хвилин відпочинку після цього.',
    'How many rounds can be played in a row, and how long the break is afterwards.',
  );
  static String gameLimitSummary(int rounds, int minutes) => _t(
    '${roundsWord(rounds)} · перерва $minutes хв',
    '${roundsWord(rounds)} · $minutes-min break',
  );
  static String get gameLimitEnabled => _t('Обмежувати ігри', 'Limit games');
  static String get gameLimitRounds => _t('Раундів підряд', 'Rounds in a row');
  static String get gameLimitRest =>
      _t('Перерва в хвилинах', 'Break in minutes');
  static String get gameLimitSaved =>
      _t('Ліміт ігор збережено', 'Game limit saved');
  static String get invalidGameLimit => _t(
    'Вкажіть ціле число більше нуля',
    'Enter a whole number greater than zero',
  );
  static String get completionBonus =>
      _t('Бонус за всі завдання', 'Bonus for all tasks');
  static String get completionBonusDaily => _t('За день', 'For the day');
  static String get completionBonusHint => _t(
    'Додаткові бали, якщо дитина виконала всі обов\'язкові завдання за день.',
    'Extra points if your child finishes every required task for the day.',
  );
  static String get completionBonusEnabled =>
      _t('Нараховувати бонус', 'Award the bonus');
  static String get completionBonusPoints =>
      _t('Бонус у балах', 'Bonus in points');
  static String get streakBonusSection => _t('За серію', 'For a streak');
  static String get streakBonusEnabled =>
      _t('Нараховувати бонус за серію', 'Award a streak bonus');
  static String get streakBonusMax =>
      _t('Максимум балів за серію', 'Maximum streak points');
  static String get streakBonusHint => _t(
    '1 бал за кожен день поспіль, але не більше максимуму.',
    '1 point for each day in a row, up to the maximum.',
  );
  static String get completionBonusSaved =>
      _t('Бонус збережено', 'Bonus saved');
  static String get invalidCompletionBonus =>
      _t('Вкажіть ціле число балів', 'Enter a whole number of points');
  static String get completionBonusTitle =>
      _t('Усі завдання готові!', 'All tasks are done!');
  static String get dayHighlightToday => _t(
    'Щось хороше, що сталося сьогодні',
    'Something good that happened today',
  );
  static String get dayHighlightThatDay => _t(
    'Щось хороше, що сталося того дня',
    'Something good that happened that day',
  );
  static String get dayHighlightSkip => _t('Пропустити', 'Skip');
  static String get dayHighlightHeading => _t('Щось хороше', 'Something good');
  static String get dayHighlightSettingsHint => _t(
    'Коли всі обов\'язкові завдання виконано, Аксо питає, що хорошого сталося за день. Записи видно в календарі.',
    'When every required task is done, Axo asks what good thing happened that day. Notes show up in the calendar.',
  );
  static String get dayHighlightEnabled =>
      _t('Питати про хороше', 'Ask about something good');
  static String get dayHighlightSaved => _t('Збережено', 'Saved');

  static String completionBonusEarned(int n) => _t(
    'Аксо пишається тобою! Ось ще ${pointsWord(n)}.',
    'Axo is proud of you! You earned ${pointsWord(n)} more.',
  );

  static String streakBonusCap(int n) => _t(
    'бонус за серію до ${pointsWord(n)}',
    'streak bonus up to ${pointsWord(n)}',
  );

  static String streakBonusAwarded(int n) =>
      _t('+${pointsWord(n)} за серію', '+${pointsWord(n)} for the streak');

  static String completionBonusSummary({
    required bool enabled,
    required int points,
    required bool streakEnabled,
    required int streakMax,
  }) {
    if (!enabled && !streakEnabled) return off;
    return [
      if (enabled) plusPoints(points),
      if (streakEnabled) streakBonusCap(streakMax),
    ].join(', ');
  }

  static String strikesProgress(int n, int max) =>
      _t('$n з $max', '$n of $max');

  static String strikeGiven(int n, int max) =>
      _t('Страйк $n з $max', 'Strike $n of $max');

  static String penaltyHit(int applied) {
    if (applied == 0) {
      return _t(
        'Три страйки! $noPointsToRemove',
        'Three strikes! $noPointsToRemove',
      );
    }
    return _t(
      'Три страйки! ${pointsAdjusted(applied)}',
      'Three strikes! ${pointsAdjusted(applied)}',
    );
  }

  static String get strikePenaltyTitle => _t('Третій страйк', 'Third strike');
  static String get continueAction => _t('Продовжити', 'Continue');

  static String strikePenaltyConfirm(int n) => _t(
    'Це зніме ${pointsWord(n)} у дитини. Продовжити?',
    'This will remove ${pointsWord(n)} from your child. Continue?',
  );

  static String get backup => _t('Резервна копія', 'Backup');
  static String get backupSubtitle =>
      _t('Експорт і імпорт', 'Export and import');
  static String get backupHint => _t(
    'Збережіть дані на випадок зміни телефону. Пароль у файл не потрапляє.',
    'Save your data in case you change phones. The password is not included in the file.',
  );
  static String get exportBackup => _t('Експортувати', 'Export');
  static String get exportDone => _t('Файл збережено', 'File saved');
  static String get exportFailed =>
      _t('Не вдалося зберегти файл', 'Could not save the file');
  static String get importBackup => _t('Імпортувати', 'Import');
  static String get importFailed =>
      _t('Не вдалося відкрити файл', 'Could not open the file');
  static String get importInvalid => _t(
    'Це не файл Аксо, або він з новішої версії додатка',
    'This is not an Axo file, or it is from a newer version of the app',
  );
  static String get importReplaceTitle => _t('Замінити дані?', 'Replace data?');
  static String get importReplaceBody => _t(
    'Усі поточні бали, завдання, цілі та історія на цьому телефоні будуть замінені даними з файлу. Пароль лишиться той самий. Це не можна скасувати.',
    'All current points, tasks, goals, and history on this phone will be replaced with the data from the file. The password stays the same. This cannot be undone.',
  );
  static String get importConfirm => _t('Замінити', 'Replace');
  static String get importDone => _t('Дані відновлено', 'Data restored');
  static String get importSuccessTitle =>
      _t('Дані відновлено', 'Data restored');
  static String get importSuccessBody => _t(
    'Усі бали, завдання, цілі та історія відновлені з файлу.',
    'All points, tasks, goals, and history were restored from the file.',
  );
  static String get importErrorTitle =>
      _t('Не вдалося відновити дані', 'Could not restore data');
  static String get importErrorBody => _t(
    'Під час імпорту сталася помилка. Попередні дані збережено без змін.',
    'Something went wrong during import. The previous data was kept unchanged.',
  );
  static String get privacy => _t('Приватність', 'Privacy');
  static String get privacyBody => _t(
    'Аксо працює лише на цьому телефоні. Завдання, бали, цілі, батьківський пароль і нагадування зберігаються локально. Ми не збираємо і не надсилаємо дані, не показуємо рекламу і не використовуємо рекламний ідентифікатор.',
    'Axo works only on this phone. Tasks, points, goals, the parent password, and reminders are stored locally. We do not collect or send data, show ads, or use an advertising identifier.',
  );
  static String get resetToday => _t('Скинути сьогодні', 'Reset today');
  static String get resetTodayTitle =>
      _t('Почати сьогодні заново?', 'Start today over?');
  static String get resetTodayBody => _t(
    'Завдання знову стануть невиконаними, одноразові зникнуть. Бонус за всі завдання можна буде отримати ще раз, ліміт ігор скинеться. Бали, цілі та історія інших днів лишаться. Це не можна скасувати.',
    'Tasks will be marked as not done, and one-off tasks will disappear. The bonus for all tasks can be earned again, and the game limit will reset. Points, goals, and other days\' history are kept. This cannot be undone.',
  );
  static String get resetTodayConfirm => _t('Скинути', 'Reset');
  static String get resetTodayDone => _t('Сьогодні скинуто', 'Today was reset');
  static String get dailyTasks => _t('Щоденні завдання', 'Daily tasks');
  static String get dailyTasksHint => _t(
    'Ці завдання з’являються щоранку. Бали дитина отримує лише після вашої перевірки.',
    'These tasks appear every morning. Your child gets points only after you check their work.',
  );
  static String get optionalTasks => _t('Додаткові завдання', 'Extra tasks');
  static String get optionalTasksHint => _t(
    'Щоб заробити ще балів. Мама чи тато можуть додати справу на сьогодні.',
    'To earn more points. A parent can add a task for today.',
  );
  static String get dailyOptionalTasks =>
      _t('Щоденні додаткові завдання', 'Daily extra tasks');
  static String get dailyOptionalTasksHint => _t(
    'Ці завдання теж з’являються щоранку, але їх не обов’язково виконувати.',
    'These tasks also appear every morning, but they are optional.',
  );
  static String get reorderTasksHint => _t(
    'Потягніть за смужки зліва, щоб змінити порядок.',
    'Drag the handles on the left to change the order.',
  );
  static String get goals => _t('Цілі', 'Goals');
  static String get goalsHint => _t(
    'На що дитина збирає бали. Коли вистачить — можна витратити.',
    'What your child is saving up for. Once they have enough points, they can redeem it.',
  );
  static String get addGoal => _t('Додати ціль', 'Add a goal');
  static String get editGoal => _t('Змінити ціль', 'Edit goal');
  static String get goalCost => _t('Вартість у балах', 'Cost in points');
  static String get spendGoal => _t('Видати', 'Redeem');
  static String get spendGoalTitle => _t('Видати ціль?', 'Redeem this goal?');
  static String get goalReady => _t('Можна отримати!', 'Ready to redeem!');
  static String get notEnoughPoints =>
      _t('Ще не вистачає балів', 'Not enough points yet');
  static String get spentGoal => _t('Ціль отримано!', 'Goal redeemed!');
  static String get spendGoalPrompt => _t(
    'Видати цю ціль і списати бали?',
    'Redeem this goal and spend the points?',
  );

  static String spendGoalConfirm(String title) => _t(
    'Видати «$title» і списати бали?',
    'Redeem "$title" and spend the points?',
  );

  static String get noGoalsYet => _t(
    'Поки немає цілей — додайте щось смачненьке.',
    'No goals yet — add something fun.',
  );
  static String get completedGoals => _t('Видані цілі', 'Redeemed goals');
  static String get completedGoalsHint => _t(
    'Цілі, які вже видали дитині.',
    'Goals your child has already redeemed.',
  );
  static String get noCompletedGoals =>
      _t('Поки немає виданих цілей.', 'No goals redeemed yet.');

  static String completedGoalOn(String iso) {
    final date = DateTime.tryParse(iso);
    if (date == null) return iso;
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final stamp = '$day.$month.${date.year}';
    return _t('Видано $stamp', 'Redeemed on $stamp');
  }

  static String daysWord(int n) {
    if (isEnglish) return _enPlural(n, 'day', 'days');
    return _ukPlural(n, 'день', 'дні', 'днів');
  }

  static String streak(int n) =>
      _t('${daysWord(n)} поспіль', '${daysWord(n)} in a row');

  static String get calendar => _t('Календар', 'Calendar');
  static String get previousMonth => _t('Попередній місяць', 'Previous month');
  static String get nextMonth => _t('Наступний місяць', 'Next month');
  static String get calendarFull => _t('Усі виконано', 'All done');
  static String get calendarPartial => _t('Частково', 'Partly done');
  static String get pastDayHint => _t(
    'Можна підтвердити завдання, які зробили раніше.',
    'You can approve tasks that were done earlier.',
  );
  static String get dayLockedHint => _t(
    'День заблоковано. Завдання не можна відзначити чи підтвердити, поки мама чи тато його не розблокують.',
    'This day is locked. Tasks cannot be marked or approved until a parent unlocks it.',
  );
  static String get dayLock => _t('Заблокувати день', 'Lock day');
  static String get dayUnlock => _t('Розблокувати день', 'Unlock day');
  static String get dayLockTitle => _t('Заблокувати день?', 'Lock this day?');
  static String get dayLockBody => _t(
    'Заблокований день не можна буде змінити: завдання не можна буде відзначити чи підтвердити. Розблокувати його зможуть лише мама чи тато.',
    'A locked day cannot be changed: tasks cannot be marked or approved. Only a parent can unlock it.',
  );
  static String get dayLockConfirm => _t('Заблокувати', 'Lock');
  static String get dayLockPrompt => _t(
    'Введи пароль, щоб заблокувати день',
    'Enter the password to lock the day',
  );
  static String get dayUnlockPrompt => _t(
    'Введи пароль, щоб розблокувати день',
    'Enter the password to unlock the day',
  );

  static List<String> get weekdays => isEnglish
      ? const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
      : const ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд'];

  static String get taskDays => _t('Дні тижня', 'Days of the week');
  static String get onlyToday => _t('Лише сьогодні', 'Today only');
  static String get chooseDay => _t('Оберіть день', 'Choose a day');

  static List<String> get months => isEnglish
      ? const [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December',
        ]
      : const [
          'Січень',
          'Лютий',
          'Березень',
          'Квітень',
          'Травень',
          'Червень',
          'Липень',
          'Серпень',
          'Вересень',
          'Жовтень',
          'Листопад',
          'Грудень',
        ];

  static String monthTitle(int year, int month) => '${months[month - 1]} $year';

  static String dayTasksProgress(int done, int total) =>
      _t('$done з $total', '$done of $total');

  static String tasksForDay(String stamp) {
    final parts = stamp.split('-');
    if (parts.length != 3) return stamp;
    final date = '${parts[2]}.${parts[1]}.${parts[0]}';
    return _t('Завдання за $date', 'Tasks for $date');
  }

  static String todayTaskPoints(int earned, int possible) =>
      '$earned / ${pointsWord(possible)}';

  static String pointsWord(int n) {
    if (isEnglish) return _enPlural(n, 'point', 'points');
    return _ukPlural(n, 'бал', 'бали', 'балів');
  }

  static String roundsWord(int n) {
    if (isEnglish) return _enPlural(n, 'round', 'rounds');
    return _ukPlural(n, 'раунд', 'раунди', 'раундів');
  }

  static String minutesWord(int n) {
    if (isEnglish) return _enPlural(n, 'minute', 'minutes');
    return _ukPlural(n, 'хвилина', 'хвилини', 'хвилин');
  }

  static String plusPoints(int n) => '+${pointsWord(n)}';

  static String goalProgress(int have, int need) =>
      '${pointsWord(have)} / ${pointsWord(need)}';

  static String pointsToGo(int n) =>
      _t('Ще ${pointsWord(n)}', '${pointsWord(n)} to go');

  static String get timer => _t('Таймер', 'Timer');
  static String get timerHint => _t(
    'Дитина може запустити таймер з головного екрана. Тут видно, скільки часу пройшло.',
    'Your child can start a timer from the home screen. Here you can see how much time has passed.',
  );
  static String get timerEnabled => _t('Показувати таймер', 'Show the timer');
  static String get timerReason => _t('Причина', 'Reason');
  static String get timerReasonHint => _t('Необов\'язково', 'Optional');
  static String get timerStart => _t('Старт', 'Start');
  static String get timerPause => _t('Пауза', 'Pause');
  static String get timerResume => _t('Далі', 'Resume');
  static String get timerMute => _t('Вимкнути музику', 'Mute music');
  static String get timerUnmute => _t('Увімкнути музику', 'Unmute music');
  static String get timerAbandon => _t('Зупинити', 'Stop');
  static String get timerAbandonTitle =>
      _t('Зупинити таймер?', 'Stop the timer?');
  static String get timerAbandonBody => _t(
    'Таймер зупиниться, а запис з\'явиться в історії.',
    'The timer will stop, and a record will appear in the history.',
  );
  static String get timerDone => _t('Готово!', 'Done!');
  static String get timerDoneBody =>
      _t('Час вийшов! Я пишаюся тобою!', 'Time is up! I\'m proud of you!');

  static String timerNotificationBody(String reason) => reason.isEmpty
      ? timerDoneBody
      : _t('$reason — час вийшов!', '$reason — time is up!');

  static String timerOngoing(String reason) =>
      reason.isEmpty ? _t('Йде таймер', 'Timer running') : reason;

  static String get timerChannelDescription =>
      _t('Живий показник таймера', 'Live timer');

  static String get reminders => _t('Нагадування', 'Reminders');
  static String get remindersHint => _t(
    'Аксо нагадає на цьому телефоні, навіть якщо додаток згорнуто. Дозвольте сповіщення. На деяких телефонах система може затримати їх, щоб берегти батарею.',
    'Axo will remind you on this phone, even if the app is in the background. Allow notifications. On some phones the system may delay them to save battery.',
  );
  static String get remindersWebHint => _t(
    'Нагадування працюють у додатку на Android і iPhone, не в браузері.',
    'Reminders work in the Android and iPhone app, not in the browser.',
  );
  static String get remindersExplainTitle => _t('Нагадування', 'Reminders');
  static String get remindersExplainBody => _t(
    'Аксо нагадає ввечері, якщо залишилися справи, і повідомить, коли таймер завершиться. Сповіщення лишаються на цьому телефоні.',
    'Axo will remind you in the evening if tasks are left, and will let you know when the timer finishes. Notifications stay on this phone.',
  );
  static String get remindersAllow => _t('Дозволити', 'Allow');
  static String get remindersLater => _t('Не зараз', 'Not now');
  static String get eveningReminder =>
      _t('Вечірнє нагадування', 'Evening reminder');
  static String get eveningReminderTime => _t('Час', 'Time');
  static String get eveningReminderBody =>
      _t('У тебе ще є справи на сьогодні', 'You still have tasks for today');
  static String get remindersSaved =>
      _t('Нагадування збережено', 'Reminders saved');
  static String get notificationsDenied => _t(
    'Сповіщення вимкнені. Увімкніть їх у налаштуваннях телефону.',
    'Notifications are off. Turn them on in your phone settings.',
  );
  static String get remindersChannelDescription =>
      _t('Нагадування Аксо', 'Axo reminders');

  static String clockTime(int hour, int minute) {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String get timerNoHistory =>
      _t('Поки немає записів.', 'No records yet.');
  static String get timerCompleted => _t('Виконано', 'Finished');
  static String get timerAbandoned => _t('Зупинено', 'Stopped');
  static String get noReason => _t('Без причини', 'No reason');

  static String timerOf(String elapsed, String target) =>
      _t('$elapsed з $target', '$elapsed of $target');

  static String recordsWord(int n) {
    if (isEnglish) return _enPlural(n, 'record', 'records');
    return _ukPlural(n, 'запис', 'записи', 'записів');
  }

  static String timerWhen(String iso) {
    final date = DateTime.tryParse(iso)?.toLocal();
    if (date == null) return iso;
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day.$month.${date.year} $hour:$minute';
  }

  static String mascotLine({
    required int remaining,
    required int waiting,
    required int verified,
  }) {
    if (remaining == 0 && waiting == 0) {
      return _t(
        'Ти сьогодні супер! Я пишаюся тобою!',
        'You were amazing today! I\'m proud of you!',
      );
    }
    if (waiting > 0 && remaining == 0) {
      return _t(
        'Я скажу мамі й татові, що ти все зробив!',
        'I\'ll tell your parents you did it all!',
      );
    }
    if (waiting > 0) {
      return _t(
        'Клас! Тепер чекаємо перевірку — і ще трохи роботи.',
        'Nice! Now we wait for a parent to check — and there\'s a little more to do.',
      );
    }
    if (verified > 0) {
      return _t(
        'Гарний старт! Давай зробимо ще одне.',
        'Good start! Let\'s do one more.',
      );
    }
    return _t(
      'Привіт! Давай виконаємо завдання разом!',
      'Hi! Let\'s do the tasks together!',
    );
  }

  static String get languageTitle => _t('Мова', 'Language');
  static String get languageHint => _t(
    'Мова екранів. Якщо не змінювати, Аксо бере мову телефона.',
    'Screen language. If you do not change it, Axo uses the phone\'s language.',
  );
  static String get languageSaved => _t('Мову збережено', 'Language saved');
  static String get taskDoneWell =>
      _t('Завдання виконано добре?', 'Was the task done well?');

  static String revealedAnswer(String answer, {bool quoted = false}) {
    if (isEnglish) {
      final shown = quoted ? '"$answer"' : answer;
      return 'It was $shown. $keepGoing';
    }
    final shown = quoted ? '«$answer»' : answer;
    return 'Було $shown. $keepGoing';
  }

  static String _enPlural(int n, String one, String many) {
    return n.abs() == 1 ? '$n $one' : '$n $many';
  }

  static String _ukPlural(int n, String one, String few, String many) {
    final abs = n.abs();
    final mod10 = abs % 10;
    final mod100 = abs % 100;
    if (mod10 == 1 && mod100 != 11) return '$n $one';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
      return '$n $few';
    }
    return '$n $many';
  }
}
