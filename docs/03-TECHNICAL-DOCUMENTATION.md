# Technical Documentation

**Project:** Anthropic Arena · **Version:** 0.5.0 (build 5) · **Date:** 2 September 2026
**Team:** Claude Commanders — SPTECH USA, Jaipur

---

## 1. Technology stack

| Layer | Technology | Version |
|---|---|---|
| Framework | Flutter (Dart) | SDK `^3.5.0` |
| State management | `flutter_riverpod` | `^3.3.2` |
| Backend — auth | `firebase_auth` | `^6.5.4` |
| Backend — database | `cloud_firestore` | `^6.6.0` |
| Backend — core | `firebase_core` | `^4.11.0` |
| Local storage | `shared_preferences` | `^2.5.0` |
| Charts | `fl_chart` | `^1.2.0` |
| Typography | `google_fonts` | `^6.2.1` |
| Video | `video_player` | `^2.11.1` |
| Notifications | `flutter_local_notifications` | `^22.0.1` |
| Sharing | `share_plus` | `^13.3.0` |
| Deep links | `url_launcher` | `^6.3.1` |
| Effects | `confetti` | `^0.8.0` |
| Linting | `flutter_lints` | `^5.0.0` |
| Hosting | Firebase Hosting | — |

**14 runtime dependencies.** No custom backend server, no ORM, no code
generation step.

## 2. Codebase at a glance

| Metric | Value |
|---|---|
| Dart source | **9,230 lines** across 42 files |
| Files tracked in git | 154 |
| Automated tests | 33 across 8 files |
| Course content | 294 questions (6 courses, 42 levels) |
| Certification content | 395 questions (41 credentials catalogued) |
| Repository | `github.com/sptashishsharma/anthropic_arena` (private) |

## 3. Repository structure

```
anthropic_arena/
├── lib/
│   ├── main.dart              bootstrap: Firebase init, prefs, ProviderScope
│   ├── app.dart               MaterialApp, themes, routing
│   ├── core/                  cross-cutting concerns (3 + 8 files)
│   │   ├── app_info.dart      version and credit strings
│   │   ├── auth_config.dart   Microsoft tenant restriction
│   │   ├── layout.dart        breakpoints, responsive shell
│   │   ├── theme/             brand colours, Material 3 themes
│   │   └── widgets/           glass, neon bg, cards, rings, video, motion
│   ├── data/                  models + repositories (3 + 4 files)
│   │   ├── models/            Course, Certification, Player, UserProgress
│   │   ├── content_repository.dart
│   │   ├── certification_repository.dart
│   │   └── leaderboard.dart
│   ├── state/providers.dart   ALL app state — 14 providers
│   ├── gamification/          XpRules, badges, ranks, reminders (4 files)
│   └── features/              one folder per screen (16 files)
│       ├── splash/  auth/  home/  learn/  quiz/
│       └── certification/  ranking/  analysis/  profile/  share/
├── assets/
│   ├── content/               courses.json · certifications.json
│   ├── images/                logo set (6 PNGs)
│   └── videos/                splash, loader, level-complete, offline
├── test/                      8 test files
├── tools/                     content authoring scripts
├── android/  ios/  web/       platform projects
├── firestore.rules            database security rules
├── firebase.json              hosting + rules deployment config
└── docs/                      project documentation
```

**Architectural rule:** dependencies point inward. `features/` may read
`state/`, `state/` may read `data/` and `gamification/`, and `gamification/` is
pure — it depends on nothing but models.

## 4. State management

All application state lives in **`lib/state/providers.dart`** as Riverpod
providers. There are 14:

### Infrastructure

| Provider | Type | Purpose |
|---|---|---|
| `prefsProvider` | `SharedPreferences` | Injected at startup via `ProviderScope` override |
| `firebaseReadyProvider` | `bool` | Whether `Firebase.initializeApp` succeeded — the online/offline switch |

### Content

| Provider | Purpose |
|---|---|
| `contentRepositoryProvider` | The `ContentRepository` implementation in use |
| `coursesProvider` | Async list of courses |
| `certificationRepositoryProvider` | The `CertificationRepository` in use |
| `certificationsProvider` | Async catalogue of credentials |

### Session & preferences

| Provider | Purpose |
|---|---|
| `themeProvider` | Dark / light / system, persisted |
| `remindersProvider` | Streak notification opt-in (Android only) |
| `onboardingSeenProvider` | First-run flag |

### Core controllers

| Provider | Purpose |
|---|---|
| `authProvider` | Identity and the Firestore profile mirror |
| `progressProvider` | The game engine |
| `leaderboardProvider` | Standings, live or demo |
| `leaderboardScopeProvider` | All-time vs weekly |
| `leaderboardIsLiveProvider` | Whether standings are live or demo data |

### `AuthController` — public API

```dart
Future<String?> signInGuest()
Future<String?> signInEmail({required String email, required String password, ...})
Future<String?> signInGoogle()
Future<String?> signInMicrosoft()
Future<String?> signInDemoApple()
void  rename(String name)
void  syncProgress()
Future<void> signOut()
```

Each sign-in method returns `null` on success or an **error message string** on
failure — errors are values, not exceptions, so the UI renders them directly.

`syncProgress()` calls the private `_mirrorProfile`, which writes an 11-field
public profile to `users/{uid}`. **Guests never sync** — enforced in both
`_mirrorProfile` and `leaderboardProvider`.

### `ProgressController` — the game engine

`recordAttempt()` is the single most important method in the codebase. In order,
it:

1. Computes stars via `XpRules.starsFor(scorePct, passMark)`
2. Computes XP via `XpRules.xpFor(...)`
3. Updates the daily streak
4. Appends to bounded attempt history and per-day XP
5. Evaluates every badge predicate for new unlocks
6. Persists `UserProgress` to `SharedPreferences`
7. Calls `authProvider.syncProgress()` — best-effort, cannot fail the operation

`recordCertAttempt()` mirrors this for exams. `isUnlocked(course, level)` gates
each level on the previous one having passed. `resetAll()` clears progress.

## 5. Game rules — `lib/gamification/xp_rules.dart`

The entire game balance is 30 lines. **Tune here, nowhere else.**

```dart
static const passBonus    = 25;
static const perfectBonus = 50;
static const dailyGoalXp  = 100;

static int starsFor(int scorePct, int passMark)
static int xpFor({...})
```

| Rule | Value |
|---|---|
| Base XP | Per correct answer |
| Pass bonus | +25 at or above the pass mark |
| Perfect bonus | +50 for a flawless run |
| 0 stars | Below the pass mark |
| 1 star | At the pass mark |
| 2 stars | 85% or above |
| 3 stars | 100% only |
| Daily goal | 100 XP |

Companion files: `badges.dart` (10 badges, each a predicate over
`UserProgress`), `ranks.dart` (7 XP tiers), `reminder_service.dart` (Android
notifications).

## 6. Data formats

### `assets/content/courses.json`

```json
{
  "courses": [{
    "id": "claude-foundations",
    "title": "Claude Foundations",
    "levels": [{
      "id": "cf-1",
      "passMark": 70,
      "questions": [{
        "id": "cf-1-q1",
        "topic": "Context windows",
        "question": "...",
        "options": ["A", "B", "C", "D"],
        "correctIndex": 2,
        "explanation": "...",
        "resource": "https://..."
      }]
    }]
  }]
}
```

**Constraints enforced by `test/content_test.dart`:** unique ids, exactly 4
options, `correctIndex` in range, pass marks within sane percentages.

### `assets/content/certifications.json`

```json
{
  "certifications": [{
    "id": "admin",
    "name": "Platform Administrator",
    "category": "Administrator & App Builder",
    "passMark": 68,
    "timeLimitMinutes": 105,
    "scoredCount": 60,
    "retired": false,
    "sets": [{
      "id": "admin-set-1",
      "label": "Spring 26 Pattern",
      "dateIso": "2026-01-01",
      "questions": [{
        "id": "adm-1",
        "topic": "Sharing and Visibility",
        "question": "...",
        "options": ["A", "B", "C", "D", "E"],
        "correctIndexes": [1, 3]
      }]
    }]
  }]
}
```

**Differences from course questions:** 2–5 options rather than exactly 4;
`correctIndexes` is a **list** — more than one entry makes it multi-select,
scored all-or-nothing on an exact set match.

`Certification.fromJson` also accepts a legacy flat `"questions": [...]` shape,
auto-wrapped into a single "Practice set".

### Firestore — `users/{uid}`

| Field | Type | Notes |
|---|---|---|
| `name` | string | ≤ 40 chars |
| `tag` | string | Player handle |
| `provider` | string | Sign-in method |
| `photoUrl` | string | Optional |
| `xp` | int | ≥ 0 |
| `xpWeek` | int | ≥ 0, rolling weekly |
| `weekKey` | string | ISO week identifier |
| `streakDays` | int | |
| `levelsCompleted` | int | |
| `badges` | int | Count |
| `updatedAt` | timestamp | |

⚠️ **This list must stay in step with the `hasOnly()` allowlist in
`firestore.rules`.** A mismatch rejects the entire write. See §10.

## 7. Environment setup

```powershell
# 1. Install the Flutter SDK (Dart ^3.5.0) and add it to PATH
# 2. Clone and fetch dependencies
git clone https://github.com/sptashishsharma/anthropic_arena.git
cd anthropic_arena
flutter pub get

# 3. Verify
flutter analyze lib test
flutter test
```

Optional, for deployment: Node.js, then `npm install -g firebase-tools` and
`firebase login`.

## 8. Build and run

| Task | Command |
|---|---|
| Browser preview | `flutter run -d chrome` |
| Headless preview | `flutter run -d web-server --web-port 8080 --web-hostname 127.0.0.1` |
| Android device | `flutter run` |
| Full test suite | `flutter test` |
| One test file | `flutter test test/certification_test.dart` |
| One test by name | `flutter test --plain-name "content contains"` |
| Lint | `flutter analyze lib test` |
| Web release | `flutter build web --release` |
| Android release | `flutter build apk --release` |

### Deployment

```powershell
flutter build web --release
firebase deploy                        # hosting + firestore rules
firebase deploy --only firestore:rules # rules alone, no rebuild needed
```

Rules can also be published from the Firebase Console without any CLI.

## 9. Configuration

| Setting | Location |
|---|---|
| Firebase project keys | `lib/firebase_options.dart` (web + Android registered; iOS not) |
| Android Firebase config | `android/app/google-services.json` |
| Microsoft tenant restriction | `AuthConfig.microsoftTenant` in `lib/core/auth_config.dart` |
| App version | `pubspec.yaml` → `version: 0.5.0+5` |
| Signing keystore | `android/key.properties` — **git-ignored** |
| Security rules | `firestore.rules` |
| Hosting config | `firebase.json` |

**Firebase client keys are not secrets.** They ship in every client by design;
security comes from `firestore.rules`.

## 10. Known issues and gotchas

### The Firestore allowlist trap

`_mirrorProfile` writes 11 fields; `firestore.rules` uses `hasOnly()`, which
rejects the **entire write** if a single unlisted key is present. This bit us
once: `xpWeek` and `weekKey` were added in v0.5.0 but not to the rules, and
because the write was wrapped in `.catchError((_) {})` it failed **silently for
17 days**. The leaderboard froze while the UI looked healthy.

**If you add a field to `_mirrorProfile`, add it to `firestore.rules` in the
same commit.**

### Misleading Android build output

`android/build.gradle.kts` redirects Gradle's output to
`C:\dev\builds\anthropic_arena`, outside the OneDrive tree. Because of that,
`flutter build apk` **always** ends with `Gradle build failed to produce an
.apk file`. **That message is cosmetic** — the signed APK is at:

```
C:\dev\builds\anthropic_arena\app\outputs\flutter-apk\app-release.apk
```

### OneDrive file locking

The project folder syncs to OneDrive, which can lock Flutter's regenerated
`ephemeral` directories and fail a build with *"Flutter failed to delete a
directory"*. Fix: delete `ios\Flutter\ephemeral` and retry, or pause sync. This
is also why the Gradle output is redirected.

### Platform differences

| Behaviour | Web | Android | iOS |
|---|---|---|---|
| Firebase | ✅ | ✅ | ❌ local-only |
| Streak notifications | ❌ | ✅ | ❌ |
| Google sign-in | ✅ | ❌ | ❌ |
| Microsoft sign-in | ✅ | ✅ | ❌ |

`RemindersController.setEnabled` returns a user-facing explanation on
unsupported platforms rather than failing silently.

### Error handling

Three sites currently discard errors. One has been fixed; the pattern is worth
avoiding:

| Location | Status |
|---|---|
| `providers.dart:215` — profile sync | Caused the leaderboard bug |
| `providers.dart:361` — sign-out cleanup | Low risk |
| `reminder_service.dart:60` — notification scheduling | Low risk |

**Principle adopted: fail loudly in the log, quietly in the UI.**

## 11. Content authoring

| Script | Input → Output |
|---|---|
| `tools/import_questions.py` | CSV/Excel → `courses.json` (add `--upload` for Firestore) |
| `tools/convert_mcq_bank.js` | `Anthropic_MCQ_Bank.xlsx` → `courses.json` + `questions_master.csv` (needs `npm install xlsx`) |

Certification banks are edited directly in `certifications.json`. After any
content change, run `flutter test` — validation catches malformed rows before
they ship.

## 12. Extension points

Designed-in seams requiring **no UI changes**:

| To do this | Implement | Swap at |
|---|---|---|
| Serve content from the cloud | `FirestoreContentRepository` | `contentRepositoryProvider` |
| Sync attempt history | Write to `users/{uid}/attempts` | Rules already exist |
| Add a credential | Append to `certifications.json` | No code change |
| Add an exam set | Append to that credential's `sets` array | No code change |
| Change game balance | Edit `xp_rules.dart` | No code change |
| Add a badge | Append a predicate to `badges.dart` | No code change |

## 13. Related documents

| Document | Covers |
|---|---|
| `README.md` | Overview, features, quick start |
| `docs/01-PROJECT-IDEA.md` | Problem statement, business value |
| `docs/02-SOLUTION-DESIGN.md` | Architecture and diagrams |
| `docs/04-TESTING.md` | Test strategy and cases |
| `CLAUDE.md` | AI-agent working instructions |
| `FIREBASE_SETUP.md` | Backend wiring checklist |
| `MICROSOFT_LOGIN_SETUP.md` | Entra ID configuration |
