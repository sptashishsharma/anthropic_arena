# Anthropic Arena

A gamified, level-based learning app built with Flutter — **Android, iOS and
web from a single codebase**.

**Learn · Play · Compete**

Built by SPTECH USA · Jaipur, for the Quantum Clash tournament
(team Claude Commanders).

- **Live web app:** https://anthropic-arena.web.app
- **Version:** 0.5.0 (build 5)

---

## What it does

The app has **two pillars** that share one game engine, one design system and
one progress store.

### 1. Learning — Anthropic Skill Jar as a game

Course material is turned into a winding level map. Answer multiple-choice
questions, earn XP, keep a daily streak, collect stars and badges, and climb a
global leaderboard. A level unlocks only once the previous one is passed.

### 2. Certifications — timed Salesforce practice exams

A catalogue of Salesforce credentials grouped by category. Each exam mirrors the
real thing: the official pass mark, time limit and question count, a live
countdown that **auto-submits at 0:00**, and multi-select questions scored
all-or-nothing on an exact match. Results feed a per-credential analytics view.

Certifications are **gated behind a real (non-guest) account** — guests can play
the learning pillar but never reach the exam banks.

---

## The five tabs

| Tab | What it does |
|-----|--------------|
| **Learn** | Daily-goal ring, continue-where-you-left-off card, course list → level map → quiz. |
| **Certifications** | Credentials by category, exam-set picker, timed exam, scored result with full review. Locked for guests. |
| **Ranking** | All-time and weekly leaderboards, podium top-3, your own row highlighted. |
| **Analysis** | XP-per-day chart, recent scores, accuracy, weak-spot detection by topic, plus a separate Certification section. |
| **Profile** | Identity, rank tier, badge collection, theme (dark/light/auto), reminders, reset, sign out. |

## Game systems

- **XP** — per correct answer, plus a pass bonus (+25) and a perfect bonus (+50)
- **Stars** — 1 at the pass mark, 2 at 85%, 3 only for a perfect run
- **Streaks** — one finished level a day keeps it alive
- **Rank tiers** — seven XP tiers: Recruit → Bronze → Silver → Gold → Platinum → Diamond → Legend
- **Badges** — 10 unlockable, each a predicate over stored progress, with progress bars on the locked ones
- **Share cards** — brag images generated from your stats

## Quiz & exam engines

Course quizzes randomise question order each run, support Previous / Skip /
Next, offer a "Get unstuck" resource link per question, and end with a full
answer review including explanations.

Certification exams draw a random subset from the chosen question bank, run a
countdown timer with a question palette for jumping around, auto-submit when
time expires, and score multi-select answers as all-or-nothing.

Brand videos play at splash and level-complete, with graceful fallbacks when a
platform can't play them.

---

## Content

Questions never live in Dart — they ship as bundled JSON and are validated by
the test suite.

### Courses — 6 courses, 42 levels, 294 questions

| Course | Levels | Questions |
|--------|-------:|----------:|
| Claude Foundations | 10 | 72 |
| Prompting Mastery | 9 | 66 |
| AI Fluency at Work | 4 | 26 |
| Claude Platform | 2 | 13 |
| Building with the API | 6 | 40 |
| Tools, MCP & RAG | 11 | 77 |

### Certifications — 41 credentials, 7 categories, 395 questions

Categories: Administrator & App Builder, Architect, Artificial Intelligence,
Associate / Foundations, Consultant, Developer, Marketing.

**8 credentials currently have question banks.** The rest are catalogued but
render as "Coming soon" until a bank is added; retired credentials are shown
but not takeable.

| Credential | Questions |
|------------|----------:|
| Platform Developer I | 195 |
| Platform Administrator | 150 |
| Platform Developer II | 10 |
| Agentforce Specialist | 8 |
| CPQ Specialist | 8 |
| Data Cloud (Data 360) Consultant | 8 |
| Sales Cloud Consultant | 8 |
| Service Cloud Consultant | 8 |

---

## Architecture

**Local-first, with Firebase layered behind swappable interfaces.**

The app is fully playable offline — accounts, progress, XP and streaks all
persist on-device via `shared_preferences`. Firebase is additive, never
required. The entire online/offline decision flows from two providers in
`lib/state/providers.dart`:

- `firebaseReadyProvider` — whether `Firebase.initializeApp` succeeded
- `prefsProvider` — the `SharedPreferences` instance

Every auth and progress method branches on that flag: the Firebase path when
it's ready, a device-local path otherwise.

**Riverpod is the single source of truth.** Three controllers carry the app:

| Provider | Role |
|----------|------|
| `AuthController` | Sign-in (guest / email / Google / Microsoft / Apple), mirrors a public profile to Firestore so the leaderboard can see it |
| `ProgressController` | The game engine — scores an attempt, computes stars and XP, updates the streak, awards badges, persists, syncs |
| `leaderboardProvider` | Live Firestore standings when online, demo standings otherwise; always splices in your own row |

**Content is behind an interface.** `ContentRepository` is implemented today by
`AssetContentRepository` (bundled JSON, works offline); a
`FirestoreContentRepository` can replace it at the provider without touching a
single widget. `CertificationRepository` mirrors the pattern.

**Game balance is centralised.** All scoring lives in
`lib/gamification/xp_rules.dart` and the badge catalogue in
`lib/gamification/badges.dart` — tune balance there, not in the controllers.

**UI treatment** is neon / glassmorphism (`GlassSurface` + animated
`NeonBackground`) over the brand palette: gold `#F5A623` on near-black
`#0A0C10`. The shell is responsive — a bottom bar on phones, a persistent
navigation rail from 900pt up.

See **[CLAUDE.md](CLAUDE.md)** for full architecture notes and gotchas.

---

## Project layout

```
lib/
  main.dart, app.dart            entry point, Firebase bootstrap, themes
  core/
    app_info.dart                version + credit strings
    auth_config.dart             which Microsoft tenants may sign in
    layout.dart                  breakpoints, content shell, responsive grid
    theme/                       brand colours + Material 3 themes
    widgets/                     glass, neon background, cards, chips, rings,
                                 streak heatmap, video player, motion helpers
  data/
    models/                      Course/Level/Question, Certification/ExamSet,
                                 Player, UserProgress + attempt records
    content_repository.dart      bundled-JSON courses (Firestore-ready interface)
    certification_repository.dart  same pattern for certifications
    leaderboard.dart             demo standings used when offline
  state/providers.dart           all Riverpod state: auth, progress, leaderboard
  gamification/
    xp_rules.dart                XP formula, star thresholds (tune balance here)
    badges.dart                  badge catalogue
    ranks.dart                   XP tiers
    reminder_service.dart        daily streak notifications (Android only)
  features/                      one folder per screen
    splash, auth, home, learn, quiz, certification,
    ranking, analysis, profile, share
assets/
  content/courses.json           294 course questions
  content/certifications.json    395 certification questions
  images/                        logo set
  videos/                        splash, loader, level-complete, offline
test/                            8 files, 33 tests
tools/                           content authoring scripts
```

---

## Running it

Requires the **Flutter SDK** (Dart `^3.5.0`) on PATH.

```powershell
flutter pub get              # after cloning or editing pubspec.yaml
flutter run -d chrome        # preview in a browser
flutter run                  # on a connected Android device/emulator
flutter test                 # full suite
flutter analyze lib test     # lint
```

Headless preview, no Chrome needed:

```powershell
flutter run -d web-server --web-port 8080 --web-hostname 127.0.0.1
```

### Building for release

```powershell
flutter build web --release  # produces build/web
flutter build apk --release  # signed release APK
```

> **Android build note.** `android/build.gradle.kts` redirects Gradle's output
> to `C:\dev\builds\anthropic_arena` (out of the OneDrive tree). Because of
> that, `flutter build apk` **always ends with a misleading "Gradle build
> failed to produce an .apk file"**. That message is cosmetic — the signed APK
> really is produced, at
> `C:\dev\builds\anthropic_arena\app\outputs\flutter-apk\app-release.apk`.

### Deploying the web app

```powershell
flutter build web --release
firebase login               # one-time, interactive browser OAuth
firebase deploy              # hosting serves build/web, also deploys firestore.rules
```

> **OneDrive note.** This folder syncs to OneDrive, which can lock Flutter's
> regenerated `ephemeral` build directories and fail a build with "Flutter
> failed to delete a directory". Fix: delete `ios\Flutter\ephemeral` and retry,
> or pause OneDrive sync. For daily development, consider a working copy
> outside OneDrive.

---

## Testing

**33 tests across 8 files.** Content is validated automatically, so a bad
question row fails the build rather than shipping silently.

| File | Covers |
|------|--------|
| `content_test.dart` | Course JSON: unique ids, 4 options, valid answer index, sane pass marks |
| `certification_test.dart` | Cert JSON: categories present, playable tracks, 2–5 options, in-range answers; plus multi-select scoring |
| `xp_rules_test.dart` | Star thresholds and the XP formula, including both bonuses |
| `progress_test.dart` | Scoring, level unlocking, streak continuation and reset, persistence across restarts, badge awards |
| `leaderboard_test.dart` | Your own row ranks by score rather than being appended; zero-score players hidden; weekly scope |
| `cert_gate_test.dart` | Guests see the sign-in gate; controls stay tappable at three screen sizes |
| `widget_test.dart` | Sign-in options, Microsoft sign-in as non-guest, guest lands on a 5-tab shell, nav labels, course list |
| `profile_overflow_test.dart` | Long work emails and long chip labels can't overflow on a small phone |

```powershell
flutter test                                    # everything
flutter test test/certification_test.dart       # one file
flutter test --plain-name "content contains"    # one test
```

---

## Platform status

| Platform | Firebase | Notes |
|----------|----------|-------|
| **Web** | Registered | Live at anthropic-arena.web.app, installable as a PWA |
| **Android** | Registered | Signed release APK; the only platform with streak notifications |
| **iOS** | Not registered | Builds and runs **local-only** — see FIREBASE_SETUP.md |

Sign-in methods: **Guest**, **Email/password**, **Google** (web), **Microsoft /
Entra ID** (web + Android), and Apple as a local demo stub. Which Microsoft
accounts are accepted is controlled by `AuthConfig.microsoftTenant`.

Firestore holds public player profiles for the leaderboard — readable by all,
writable only by their owner, and closed to anonymous accounts. Rules live in
`firestore.rules` and deploy with `firebase deploy`.

---

## Updating content

### Course questions

Two authoring paths, both in `tools/`:

```powershell
# CSV/Excel -> courses.json
python tools/import_questions.py questions.csv --out assets/content/courses.json

# the team's MCQ workbook -> courses.json + questions_master.csv
node tools/convert_mcq_bank.js        # needs: npm install xlsx
```

Then run `flutter test` — content validation catches bad rows before they ship.

### Certification banks

Edit `assets/content/certifications.json`. To add a new exam set to a
credential, append to its `sets` array:

```json
{
  "id": "admin-set-2",
  "label": "Spring 26 Pattern",
  "dateIso": "2026-01-01",
  "questions": [
    { "id": "...", "topic": "...", "question": "...",
      "options": ["..."], "correctIndexes": [0] }
  ]
}
```

Each attempt draws `scoredCount` random questions from the chosen set.

---

## Documentation

| Document | What it covers |
|----------|----------------|
| **[CLAUDE.md](CLAUDE.md)** | Full architecture, commands, content pipeline, gotchas |
| **[FIREBASE_SETUP.md](FIREBASE_SETUP.md)** | Backend wiring checklist and the exact seams to swap |
| **[MICROSOFT_LOGIN_SETUP.md](MICROSOFT_LOGIN_SETUP.md)** | Azure + Firebase console steps for Entra ID sign-in |

---

## Known limitations & future scope

- **iOS is not registered with Firebase** — that build runs local-only
- **Streak reminders are Android-only**; the web build explains why rather than failing silently
- **Content is bundled JSON**, so updating questions needs an app release — `FirestoreContentRepository` is the designed-in fix and needs no UI changes
- **Only 8 of 41 credentials have question banks**; the remaining 33 are catalogued but not yet playable
- **Apple sign-in is a local demo stub**, not a real identity provider
- **Leaderboard is capped at the top 50** players
- Attempt history is bounded on-device (200 quiz attempts, 100 exam attempts) and is not yet synced to Firestore
