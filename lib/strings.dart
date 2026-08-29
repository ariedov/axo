class S {
  static const hello = 'Привіт!';
  static const todaysTasks = 'Завдання на сьогодні';
  static const miniGames = 'Міні-ігри';
  static const timesTables = 'Множення';
  static const timesTablesHint = 'Порахуй';
  static const spelling = 'Правопис';
  static const spellingHint = 'Напиши слово';
  static const english = 'Англійська';
  static const englishHint = 'Переклади';
  static const translateToUk = 'Як українською?';
  static const translateToEn = 'Як англійською?';
  static const bothWays = 'Обидва';
  static const enLang = 'EN';
  static const uaLang = 'UA';
  static const done = 'Зробив!';
  static const waiting = 'Чекає маму чи тата';
  static const verified = 'Підтверджено';
  static const verify = 'Перевірити';
  static const notYet = 'Ще не готово';
  static const parentTitle = 'Для мами і тата';
  static const parentPrompt = 'Введи пароль, щоб підтвердити завдання';
  static const passwordHint = 'Пароль';
  static const wrongPassword = 'Неправильний пароль';
  static const awardPoints = 'Нарахувати бали';
  static const sendBack = 'Повернути';
  static const cancel = 'Скасувати';
  static const addTask = 'Додати завдання';
  static const addTodayTaskPrompt =
      'Введи пароль, щоб додати завдання на сьогодні';
  static const editTask = 'Змінити завдання';
  static const taskTitle = 'Назва';
  static const taskPoints = 'Бали';
  static const save = 'Зберегти';
  static const delete = 'Видалити';
  static const howMany = 'Скільки буде?';
  static const check = 'Перевірити';
  static const correct = 'Молодець!';
  static const tryAgain = 'Спробуй ще раз';
  static const keepGoing = 'Давай далі!';
  static const writeTheWord = 'Напиши слово';
  static const next = 'Далі';
  static const easy = 'Легко';
  static const normal = 'Нормально';
  static const hard = 'Складно';
  static const allDone = 'Усі завдання на сьогодні готові!';
  static const practiceOnly =
      'Перші 3 раунди (по 10 завдань) дають бали. Далі можна грати скільки завгодно.';
  static const gamePointsLeft = 'Раунди з балами сьогодні';
  static const gamePointsGone = 'Сьогодні балів більше немає — граємо для тренування';

  static String gameRoundsProgress(int used, int max) => '$used/$max';
  static const plusGamePoints = 'балів за гру';
  static const roundDone = 'Раунд завершено!';
  static const correctCount = 'Правильно';
  static const wrongCount = 'Помилки';
  static const practiceMode = 'Тренування';
  static const parentSection = 'Батьківський розділ';
  static const parentSectionPrompt = 'Введи пароль, щоб відкрити налаштування';
  static const onboardingHello = 'Привіт! Я Аксо.';
  static const onboardingParentsBody =
      'Цей розділ — для мами і тата. Тут ви налаштуєте додаток, перш ніж віддати телефон дитині.';
  static const onboardingBody =
      'Мама або тато: придумайте пароль і скільки балів дати на старт. Паролем ви підтверджуватимете завдання.';
  static const onboardingPrivacy =
      'Усі дані лишаються на цьому пристрої. Без реклами, без акаунтів і без інтернету.';
  static const onboardingGoalHello = 'За що збираємо бали?';
  static const onboardingGoalBody =
      'На що дитина збиратиме бали? Можна поставити нову ціль тут.';
  static const onboardingDoneHello = 'Усе готово!';
  static const onboardingDoneBody =
      'Налаштування завершено. Далі Аксо — для дитини: завдання, ігри й цілі. Мама й тато підтверджують виконане паролем.';
  static const understood = 'Зрозуміло';
  static const choosePassword = 'Придумайте пароль';
  static const repeatPassword = 'Повторіть пароль';
  static const startingPoints = 'Початкові бали';
  static const invalidPoints = 'Вкажіть ціле число балів';
  static const passwordTooShort = 'Щонайменше 4 символи';
  static const passwordsDontMatch = 'Паролі не збігаються';
  static const letsGo = 'Поїхали!';
  static const pickGameMode = 'Оберіть режим';

  static String pointsPerRound(int n) => '${pointsWord(n)} за раунд';
  static const ok = 'Гаразд';
  static const currentPassword = 'Поточний пароль';
  static const newPassword = 'Новий пароль';
  static const passwordChanged = 'Пароль змінено';
  static const changePassword = 'Змінити пароль';
  static const bonusPoints = 'Бонус і штраф';
  static const bonusPointsHint =
      'Нарахуйте або зніміть будь-яку кількість балів.';
  static const bonusPointsPrompt =
      'Введи пароль, щоб нарахувати або зняти бали';
  static const addPoints = 'Додати';
  static const removePoints = 'Зняти';
  static const pointsAmount = 'Скільки балів';

  static String pointsNow(int n) => 'Зараз ${pointsWord(n)}';

  static String pointsAdjusted(int delta) {
    if (delta > 0) return 'Нараховано ${pointsWord(delta)}';
    return 'Знято ${pointsWord(-delta)}';
  }

  static const noPointsToRemove = 'Немає балів, щоб зняти';
  static const backup = 'Резервна копія';
  static const backupHint =
      'Збережіть дані на випадок зміни телефону. Пароль у файл не потрапляє.';
  static const exportBackup = 'Експортувати';
  static const exportDone = 'Файл збережено';
  static const exportFailed = 'Не вдалося зберегти файл';
  static const importBackup = 'Імпортувати';
  static const importFailed = 'Не вдалося відкрити файл';
  static const importInvalid =
      'Це не файл Аксо, або він з новішої версії додатка';
  static const importReplaceTitle = 'Замінити дані?';
  static const importReplaceBody =
      'Усі поточні бали, завдання, цілі та історія на цьому телефоні будуть замінені даними з файлу. Пароль лишиться той самий. Це не можна скасувати.';
  static const importConfirm = 'Замінити';
  static const importDone = 'Дані відновлено';
  static const privacy = 'Приватність';
  static const privacyBody =
      'Аксо працює лише на цьому телефоні. Завдання, бали, цілі та батьківський пароль зберігаються локально. Ми не збираємо і не надсилаємо дані, не показуємо рекламу і не використовуємо рекламний ідентифікатор.';
  static const dailyTasks = 'Щоденні завдання';
  static const dailyTasksHint =
      'Ці завдання з’являються щоранку. Бали дитина отримує лише після вашої перевірки.';
  static const reorderTasksHint =
      'Потягніть за смужки зліва, щоб змінити порядок.';
  static const goals = 'Цілі';
  static const goalsHint =
      'На що дитина збирає бали. Коли вистачить — можна витратити.';
  static const addGoal = 'Додати ціль';
  static const editGoal = 'Змінити ціль';
  static const goalCost = 'Вартість у балах';
  static const spendGoal = 'Видати';
  static const goalReady = 'Можна отримати!';
  static const notEnoughPoints = 'Ще не вистачає балів';
  static const spentGoal = 'Ціль отримано!';
  static const spendGoalPrompt = 'Видати цю ціль і списати бали?';
  static const noGoalsYet = 'Поки немає цілей — додайте щось смачненьке.';
  static const completedGoals = 'Видані цілі';
  static const completedGoalsHint =
      'Цілі, які вже видали дитині.';
  static const noCompletedGoals = 'Поки немає виданих цілей.';

  static String completedGoalOn(String iso) {
    final date = DateTime.tryParse(iso);
    if (date == null) return iso;
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return 'Видано $day.$month.${date.year}';
  }
  static const calendar = 'Календар';
  static const previousMonth = 'Попередній місяць';
  static const nextMonth = 'Наступний місяць';
  static const calendarFull = 'Усі завдання';
  static const calendarPartial = 'Частина';
  static const weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд'];
  static const months = [
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

  static String dayTasksProgress(int done, int total) => '$done з $total';

  static String todayTaskPoints(int earned, int possible) =>
      '$earned / ${pointsWord(possible)}';

  static String pointsWord(int n) {
    final abs = n.abs();
    final mod10 = abs % 10;
    final mod100 = abs % 100;
    if (mod10 == 1 && mod100 != 11) return '$n бал';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
      return '$n бали';
    }
    return '$n балів';
  }

  static String plusPoints(int n) => '+${pointsWord(n)}';

  static String goalProgress(int have, int need) =>
      '${pointsWord(have)} / ${pointsWord(need)}';

  static String pointsToGo(int n) => 'Ще ${pointsWord(n)}';

  static String mascotLine({
    required int remaining,
    required int waiting,
    required int verified,
  }) {
    if (remaining == 0 && waiting == 0) {
      return 'Ти сьогодні супер! Я пишаюся тобою!';
    }
    if (waiting > 0 && remaining == 0) {
      return 'Я скажу мамі й татові, що ти все зробив!';
    }
    if (waiting > 0) {
      return 'Клас! Тепер чекаємо перевірку — і ще трохи роботи.';
    }
    if (verified > 0) {
      return 'Гарний старт! Давай зробимо ще одне.';
    }
    return 'Привіт! Давай виконаємо завдання разом!';
  }
}
