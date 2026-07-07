# Anthropic Arena

A gamified, level-based learning app that teaches Anthropic Skill Jar course
material as a game — for Android and iPhone from a single Flutter project.

**Learn · Play · Compete**

Built by SPTECH USA · Jaipur, for the Quantum Clash tournament
(team Claude Commanders).

## What's inside

| Tab | What it does |
|-----|--------------|
| **Learn** | Courses → winding level map → quiz play. Levels unlock as you pass the previous one. |
| **Ranking** | Leaderboard with podium top-3 and your highlighted rank. |
| **Analysis** | XP-per-day chart, recent scores, overall accuracy, and automatic weak-spot detection by topic. |
| **Profile** | Player identity, badge collection, theme (dark/light/auto), reset, sign out. |

Game systems: XP (per correct answer + pass/perfect bonuses), daily streaks,
1–3 star ratings per level, 10 unlockable badges.

Quiz engine: randomized question order, Previous / Skip / Next navigation,
"Get unstuck" resource links on every question, full answer review with
explanations after each run.

Brand videos play at splash and level-complete (see `assets/videos/`), with
graceful fallbacks when a platform can't play them.

## Project layout

```
lib/
  main.dart, app.dart          entry point, themes, routing
  core/theme/                  brand colors + Material 3 themes
  core/widgets/                shared UI (cards, chips, stars, video player)
  data/models/                 Course/Level/Question, progress, player
  data/content_repository.dart bundled-JSON content source (Firestore-ready interface)
  data/leaderboard.dart        demo standings until Firebase goes live
  state/providers.dart         Riverpod state: auth, progress engine, theme
  gamification/                XP rules + badge catalogue
  features/                    splash, auth, home, learn, quiz, ranking, analysis, profile
assets/
  content/courses.json         the question bank the app ships with
  images/                      logo set    videos/  brand videos
tools/
  import_questions.py          CSV/Excel → courses.json and/or Firestore upload
  questions_template.csv       the format course authors fill in
```

## Running it

```powershell
# from this folder (flutter must be on PATH — SDK lives at C:\dev\flutter)
flutter run -d chrome        # quick preview in a browser
flutter run                  # on a connected Android device/emulator
flutter test                 # 19 tests: content validation, game rules, widgets
flutter analyze
```

> **OneDrive note:** this folder syncs to OneDrive, which sometimes locks
> Flutter's regenerated `ephemeral` build folders and fails a build with
> "Flutter failed to delete a directory". Fix: delete
> `ios\Flutter\ephemeral` and retry, or pause OneDrive sync while developing.
> For daily development consider keeping a working copy outside OneDrive.

## Updating questions

1. Fill in `tools/questions_template.csv` (one row per question; columns for
   course, level, topic, options A–D, correct letter, explanation, resource link).
2. Regenerate the bundled content:
   ```
   python tools/import_questions.py questions.csv --out assets/content/courses.json
   ```
3. `flutter test` validates the new content automatically (unique ids,
   4 options, valid answers, sane pass marks).

Once Firebase is connected the same script pushes content live with
`--upload --key serviceAccountKey.json` — no app release needed.

## Firebase (phase 2)

The app currently runs fully offline: accounts, progress, XP and streaks are
stored on-device, and the leaderboard shows demo standings. All data access
goes through small interfaces (`ContentRepository`, the auth/progress
notifiers), so wiring Firebase swaps implementations without touching the UI.
See **FIREBASE_SETUP.md** for the step-by-step plan (Auth, Firestore,
leaderboard queries, push reminders, Crashlytics, Analytics).
