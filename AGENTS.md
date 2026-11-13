# Axo

Flutter habit tracker for kids. Dart package name is `app` (`package:app/...`), not `axo`. No backend: SharedPreferences only. Do not add accounts, analytics, or network data collection.

UI copy is in `lib/strings.dart` (`S`), Ukrainian and English. A saved parent choice wins; otherwise the device locale is used when it is `uk` or `en`, and Ukrainian otherwise. `flutter_localizations` follows that locale. Tunables live in `lib/config.dart`. Trust that over README / `docs/play-listing.md` when they disagree.

## Commands

```bash
flutter pub get
dart format .
flutter analyze
flutter test
flutter test --plain-name 'exact test name'
```

No PR CI. `.github/workflows/release.yml` runs only on tag push. Always `analyze` + `test` locally.

## Layout

- `lib/state/habit_store.dart` — domain + persistence orchestration. UI reads it via `HabitScope.of(context)`.
- `lib/data/` — models and repos. `Local*` wrap SharedPreferences callbacks; `InMemory*` are for tests (keep both in sync).
- `lib/widgets/game_card.dart` `miniGameScreen()` — game routing.
- `assets/data/` — seed tasks, spelling words, translations.
- Tests: one file, `test/widget_test.dart`. Helpers: `testStore()`, `pumpParentSettings()`, `openParentSetting()`.

## Domain

Task flow: pending → `submit` → parent `verify` (awards points) or `reject` (back to pending). Parent gate is `askParent()`. Password is optional: skip at onboarding or turn off in parent settings. `askParent()` succeeds immediately when unset.

Tasks are required unless `optional` (`HabitTask.isMandatory`); calendar completion, pending count, and the all-done bonus count only required tasks scheduled that day. `todayOnly` one-offs do not roll to the next day and stay out of the parent task sheets, but count toward their day. The all-done bonus is awarded at most once per day (`DayHistory.bonusDays`). It is the daily bonus plus a streak bonus (1 point per consecutive full day, capped at `streakBonusMaxPoints`, default 20). Either part can be off or zero. `verify` returns the total (0 if none). Task editor: main screen defaults to a one-off (no days selected), parent settings to every day; saving with no day selected is blocked outside the main screen.

Games: 10 items per round (`AppConfig.roundLength`). Two caps: a global window (`rewardedPlays` in `playLimitMinutes`) and a per-game daily cap. After the daily cap, practice mode (no points). Parent can turn limits off (`gameLimitEnabled`, default on); then play has no stops and always awards points. Award through `tryAwardGamePlay`. New game: id/points in `AppConfig`, catalog entry, screen (follow `GameScaffold` / `GameSetupBody` / `GameRound`), route in `miniGameScreen()`, strings on `S`, tests in `widget_test.dart`.

Badges: `lib/data/badges.dart` holds the catalog and thresholds (`HabitBadge`, `BadgeKind`: tasks, best streak, good things, games, perfect days, points, redeemed goals, active days, timer minutes, good-day streak, perfect weekends, days with Axo). Stats are derived from `DayHistory` (task counts, `bestStreak`, `goodStreak`, highlight count, `activeDays`, `perfectWeekends`, full days) plus `Achievements` (games played, lifetime points earned, timer minutes). `AchievementsRepository` persists earned badge ids → day stamps and those counters. `awardNewBadges()` in the store announces each badge once and returns it for the dialog. Celebration order after a full day: good-thing prompt → completion bonus → badges. Home shows one scrollable row with the current badge per category, ordered by earned tiers then progress (`badgeKindsByAchievement`), grey when nothing is earned yet; the chevron opens `BadgesScreen` with every tier.

Good things: "something good that happened" notes live in `DayHistory.highlights` (keyed by day stamp, max `dayHighlightMaxLength`). `recordGoodThing()` (in `day_highlight_dialog.dart`) opens the dialog for today with the existing note prefilled, saves it, then awards badges. The home screen has a `GoodThingButton` under the required tasks so the note can be written before every task is done, and a `GoodThingsCard` under the mascot opens `GoodThingsScreen` — every note, newest first, with weekday + date.

Backup format 2, `app: axo`. Never export the parent password; import keeps the existing password. Newer format throws. Timer history and the parent enable flag ride along in `data.timer`. Badge ids and the games counter ride along as `data.achievements`. Evening reminder prefs ride along as `eveningReminderEnabled` / `Hour` / `Minute`. Streak bonus prefs ride along as `streakBonusEnabled` / `streakBonusMaxPoints`. The day-highlight prompt can be turned off with `dayHighlightEnabled`. Language rides along as `language` (`uk` or `en`); if the field is missing, import keeps the current language.

Timer: FAB on home (parent can hide it). Duration + optional reason, counts up, pause/resume/abandon, screen stays on. History is in parent settings. While running, a persistent OS notification is shown (id `ReminderId.timer`) backed by an Android `mediaPlayback` foreground service (keeps music + countdown alive in background); the one-off done alarm replaces it (+3s buffer so in-app completion cancels first). The service notification has a mute action that toggles timer music. Onboarding ends with an explain dialog, then a permission request.

Reminders are local-only (no push server). Evening leftovers ping required pending+submitted tasks; parent-gated time defaults to 21:00. Android/iOS only — web cannot schedule notifications. Inject `ReminderScheduler`; tests use `InMemoryReminderScheduler`.

## UI / assets

Interactive widgets used in tests need stable `Key`s (see existing `Key('settings-…')`, `Key('game-$id')`). Home widget tests set a tall `tester.view.physicalSize`.

Spelling/translation prompts use Material icons via `PictureIcons`, not emoji (Nunito has no color-emoji glyphs). Every `emoji` in `assets/data/spelling_words.json` and `translations.json` must be in that map — covered by the test `every spelling and translation picture has an icon`.

## Release

Version is `pubspec.yaml` (`1.2.4+10`). Tag push builds APK, AAB, and GitHub Pages at `/{repo}/` (`--base-href`, plus `build/web/.nojekyll`). Android signing: local `android/key.properties` (see `key.properties.example`); do not commit keystore or `key.properties`. Icons: `dart run flutter_launcher_icons`.
