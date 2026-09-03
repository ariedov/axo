# Axo

Flutter habit tracker for kids. Dart package name is `app` (`package:app/...`), not `axo`. No backend: SharedPreferences only. Do not add accounts, analytics, or network data collection.

UI copy is Ukrainian in `lib/strings.dart` (`S`). Locale is hardcoded to `uk`; `flutter_localizations` is for Material widgets only, not app strings. Tunables live in `lib/config.dart`. Trust that over README / `docs/play-listing.md` when they disagree.

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

Task flow: pending → `submit` → parent `verify` (awards points) or `reject` (back to pending). Parent gate is `askParent()`.

`optional` and `todayOnly` are extras. Calendar completion, pending count, and the all-done bonus count only mandatory daily tasks (`HabitTask.isMandatory`). `todayOnly` does not roll to the next day. `verify` returns the completion-bonus amount (0 if none).

Games: 10 items per round (`AppConfig.roundLength`). Two caps: a global window (`rewardedPlays` in `playLimitMinutes`) and a per-game daily cap. After the daily cap, practice mode (no points). Award through `tryAwardGamePlay`. New game: id/points in `AppConfig`, catalog entry, screen (follow `GameScaffold` / `GameSetupBody` / `GameRound`), route in `miniGameScreen()`, strings on `S`, tests in `widget_test.dart`.

Backup format 2, `app: axo`. Never export the parent password; import keeps the existing password. Newer format throws.

## UI / assets

Interactive widgets used in tests need stable `Key`s (see existing `Key('settings-…')`, `Key('game-$id')`). Home widget tests set a tall `tester.view.physicalSize`.

Spelling/translation prompts use Material icons via `PictureIcons`, not emoji (Nunito has no color-emoji glyphs). Every `emoji` in `assets/data/spelling_words.json` and `translations.json` must be in that map — covered by the test `every spelling and translation picture has an icon`.

## Release

Version is `pubspec.yaml` (`1.2.3+9`). Tag push builds APK, AAB, and GitHub Pages at `/{repo}/` (`--base-href`, plus `build/web/.nojekyll`). Android signing: local `android/key.properties` (see `key.properties.example`); do not commit keystore or `key.properties`. Icons: `dart run flutter_launcher_icons`.
