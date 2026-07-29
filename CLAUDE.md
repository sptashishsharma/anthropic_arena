# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Anthropic Arena is a Flutter app (Android + iOS + web from one codebase) that
teaches Anthropic Skill Jar course material as a gamified quiz. Learners move
through a level map, answer multiple-choice questions, and earn XP, streaks,
stars, and badges. State is Riverpod; content ships as bundled JSON with a
Firebase backend layered on behind swappable interfaces.

A second pillar is **Certifications**: a catalogue of Salesforce credentials
where learners sit timed, auto-submitting practice exams (multiple-choice and
multi-select) and see per-credential analytics. The whole UI uses a
**neon / glassmorphism** treatment (see [lib/core/widgets/glass.dart](lib/core/widgets/glass.dart):
`GlassSurface` + animated `NeonBackground`) layered over the original gold
(`#F5A623`) on near-black (`#0A0C10`) brand palette — the palette is intentionally
preserved; only the surface styling changed.

## Commands

Flutter SDK lives at `C:\dev\flutter` and must be on PATH.

```powershell
flutter run -d chrome        # preview in browser
# headless preview (no Chrome needed) — used for shared-link previews:
flutter run -d web-server --web-port 8080 --web-hostname 127.0.0.1
flutter run                  # run on connected Android device/emulator
flutter test                 # full suite (content validation, game rules, widgets)
flutter test test/certification_test.dart      # single test file
flutter test --plain-name "content contains"   # single test by name
flutter analyze lib test     # lint (flutter_lints via analysis_options.yaml)
flutter pub get              # after editing pubspec.yaml
```

Web deploy (Firebase Hosting, project `anthropic-arena`, live at
`https://anthropic-arena.web.app`):

```powershell
flutter build web --release  # produces build/web (the deploy artifact)
firebase login               # ONE-TIME, interactive browser OAuth (cannot be done headless)
firebase deploy              # hosting serves build/web; also deploys firestore.rules
```

Deploy is gated on `firebase login` — a browser flow that a non-interactive
session cannot perform. The CLI (`firebase-tools`) installs via
`npm install -g firebase-tools`. Once a human has logged in on the machine, the
cached credentials let `firebase deploy` run non-interactively.

Android release build:

```powershell
flutter build apk --release  # signed release APK (also: appbundle for Play Store)
```

Signing is via `android/key.properties` (keystore path + passwords, kept out of
git) consumed by `android/app/build.gradle.kts`. The current release key is
`CN=Anthropic Arena, O=SPTECH USA`.

**IMPORTANT — the APK is NOT under `build/`.** `android/build.gradle.kts`
redirects Gradle's `buildDir` to `C:\dev\builds\anthropic_arena` (out of the
OneDrive tree, to dodge sync locks — see Gotchas). Because of that redirect the
`flutter build apk` command **always ends with a misleading
`Gradle build failed to produce an .apk file … but the tool couldn't find it`** —
the tool looks in `<project>\build`, which is empty. That message is COSMETIC:
the signed APK really is produced, at
`C:\dev\builds\anthropic_arena\app\outputs\flutter-apk\app-release.apk`. Grab it
from there (or `build/app/outputs/apk/release/`); do not trust the exit message.

## Architecture

**Local-first with Firebase layered behind interfaces.** The app is fully
playable offline — accounts, progress, XP, streaks all persist on-device via
`shared_preferences`. Firebase (Auth + Firestore) is switched on per-platform
without touching the UI. The whole online/offline decision flows from two
providers in [lib/state/providers.dart](lib/state/providers.dart):

- `firebaseReadyProvider` — overridden in [lib/main.dart](lib/main.dart) with
  whether `Firebase.initializeApp` succeeded. Web today; Android/iOS run
  local-only until registered in the Firebase console.
- `prefsProvider` — the `SharedPreferences` instance, injected via
  `ProviderScope` overrides in `main()`.

Every auth/progress method branches on `_firebase` (reads `firebaseReadyProvider`):
Firebase path when ready, device-local path otherwise. When adding backend
features, follow this pattern rather than assuming Firebase exists.

**Riverpod is the single source of truth.** [lib/state/providers.dart](lib/state/providers.dart)
holds nearly all app state as Notifiers:

- `AuthController` (`authProvider`) — sign-in (guest/email/Google/Apple),
  stores `Player`, mirrors a public profile doc to Firestore `users/{uid}` so
  the leaderboard can see it. **Guests never sync and never appear on the
  leaderboard** — this rule is enforced in both `_mirrorProfile` and
  `leaderboardProvider`.
- `ProgressController` (`progressProvider`) — the game engine.
  `recordAttempt()` is the core: it scores an attempt, computes stars/XP via
  `XpRules`, updates the daily streak, appends bounded attempt history and
  per-day XP, awards new badges, persists, and calls `authProvider.syncProgress()`
  to push standings. `isUnlocked()` gates each level on the previous one passing.
- `leaderboardProvider` — returns live Firestore standings (top 50 by XP) when
  Firebase is ready, otherwise `demoRivals` from [lib/data/leaderboard.dart](lib/data/leaderboard.dart);
  in both cases it splices in the local player so they always see their own rank.

**Certifications subsystem.** A parallel, self-contained feature under
[lib/features/certification/](lib/features/certification/) and
[lib/data/models/certification.dart](lib/data/models/certification.dart):

- **Data model.** A `Certification` carries official exam params (`passMark`,
  `timeLimitMinutes`, `scoredCount`, `unscoredCount`, `category`, `note`,
  `retired`) plus one or more `ExamSet`s. Each `ExamSet` is a named, dated
  question bank (e.g. label `"Spring 26 Pattern"`); a `CertQuestion` holds
  `options` + `correctIndexes` (`isMultiSelect` = more than one correct;
  scoring is all-or-nothing exact-set match). `Certification.fromJson` accepts
  **either** the multi-set shape (`"sets": [...]`) **or** a legacy flat
  `"questions": [...]` list (auto-wrapped into one "Practice set"). Content is
  in `assets/content/certifications.json`, loaded via `CertificationRepository`
  → `certificationsProvider` (same swappable-interface pattern as courses).
- **Exam flow.** The Certifications tab groups certs by `category`. A cert with
  one playable set starts directly; with multiple sets it shows a picker. The
  exam ([cert_exam_screen.dart](lib/features/certification/cert_exam_screen.dart))
  draws a random `scoredCountFor(set)` (= min of `scoredCount` and pool size)
  questions, runs a `Timer.periodic` countdown, auto-submits at 0:00, supports
  manual submit, then routes to the result screen. `retired` / empty-bank certs
  render "Coming soon" and are not playable.
- **Scoring & analytics.** `ProgressController.recordCertAttempt(...)` scores
  the attempt (exact-match, multi-select all-or-nothing), records a
  `CertAttempt` (tagged with `setId`/`setLabel`, capped ~100) on `UserProgress`,
  and the Analysis tab renders a per-credential Certification section
  (best %, attempts, per-topic breakdown) separate from the learning analysis.
- **Login gate.** The Certifications tab is gated to **real (non-guest)
  accounts**. `CertificationTab` renders a `_SignInGate` for guests/anonymous
  users (the exam catalogue never mounts for them), and `HomeShell` shows a lock
  on the nav item until sign-in. Guest = `player.provider == AuthProvider.guest`
  (an anonymous one-tap session), so gating on non-guest is what actually keeps
  the exam banks off the open/anonymous web — see the copyright gotcha below.
  The gate's **Sign in** button follows the app-wide guest-upgrade pattern
  (shared with the Ranking tab prompt and Profile sign-out): `signOut()` to clear
  the active anonymous session, then `pushAndRemoveUntil` the `LoginScreen` on the
  root navigator. Never stack `LoginScreen` on top of a live guest session —
  progress lives under its own prefs key, so clearing auth keeps XP/streak/stars
  and the guest simply upgrades in place.

**Content pipeline.** Questions never live in Dart. They come from
`assets/content/courses.json`, loaded through the `ContentRepository` interface
([lib/data/content_repository.dart](lib/data/content_repository.dart)). The
bundled `AssetContentRepository` reads the JSON; a future `FirestoreContentRepository`
implementing the same interface swaps in at `contentRepositoryProvider`. To
change questions, edit the source spreadsheet/CSV and regenerate — see below.

**Game-balance tuning is centralized.** All scoring lives in
[lib/gamification/xp_rules.dart](lib/gamification/xp_rules.dart) (XP formula,
pass/perfect bonuses, star thresholds) and the badge catalogue in
[lib/gamification/badges.dart](lib/gamification/badges.dart) (each badge is a
predicate over `UserProgress`). Change balance there, not in the controllers.

**Layout.** `lib/core/` = theme + shared widgets; `lib/data/` = models +
repositories; `lib/features/` = one folder per screen (splash, auth, home,
learn, quiz, ranking, analysis, profile), all `ConsumerWidget`s reading providers.

## Regenerating question content

Two authoring paths, both under `tools/`:

- `import_questions.py` — CSV/Excel → `courses.json` (columns documented in the
  script header and `questions_template.csv`). Add `--upload --key serviceAccountKey.json`
  to push straight to Firestore instead (needs `firebase-admin`).
- `convert_mcq_bank.js` — converts the team's `Anthropic_MCQ_Bank.xlsx` (correct
  answers marked by bold-green cell style) into both `courses.json` and the
  editable `questions_master.csv`. Needs `npm install xlsx`.

After regenerating, `flutter test` validates the new content automatically
([test/content_test.dart](test/content_test.dart) checks unique ids, exactly 4
options, valid correct index, sane pass marks). A bad row fails the build
rather than shipping silently.

**Certification banks** are separate: `assets/content/certifications.json`,
validated by [test/certification_test.dart](test/certification_test.dart)
(catalogue present, every cert has a category, ≥8 playable tracks, unique
question ids, each question has ≥2 options with in-range `correctIndexes`).
Unlike course questions, cert questions may have 2–5 options (single- and
multi-select). To add a new exam set to a cert, append to its `"sets"` array:
`{ "id": "...", "label": "Spring 26 Pattern", "dateIso": "2026-01-01",
"questions": [ { id, topic, question, options, correctIndexes } ] }`. The exam
draws `scoredCount` random questions from the chosen set each attempt.

## Gotchas

- **OneDrive lock:** this folder syncs to OneDrive, which can lock Flutter's
  regenerated `ephemeral` build dirs and fail a build with "Flutter failed to
  delete a directory". Fix: delete `ios\Flutter\ephemeral` and retry, or pause
  OneDrive sync. Consider a working copy outside OneDrive for daily dev. This
  is also why `android/build.gradle.kts` redirects Gradle's output out of the
  tree to `C:\dev\builds\anthropic_arena` — which in turn makes
  `flutter build apk` report a false "failed to produce an .apk" (see the
  Android release build note under Commands; the APK really is produced there).
- **Streak reminders are Android-only.** `ReminderService`
  ([lib/gamification/reminder_service.dart](lib/gamification/reminder_service.dart))
  no-ops on web; `RemindersController.setEnabled` returns a user-facing message
  explaining why on unsupported platforms.
- **Firestore security rules** live in `firestore.rules` and are deployed with
  `firebase deploy`. `users` docs are publicly readable (the leaderboard needs
  it) but writable only by their owner.
- **Certification bank provenance / gating.** The seeded `admin` and `pd1`
  "Spring 26 Pattern" banks were imported from third-party exam-dump PDFs and
  are derived from Salesforce's proprietary certification content. They are
  deliberately gated behind a non-guest login (see the Certifications subsystem)
  so they are not exposed on the open, crawlable web. Do not remove that gate or
  make these banks publicly reachable without the owner's explicit sign-off;
  prefer original practice questions for anything intended to be public.
- See [FIREBASE_SETUP.md](FIREBASE_SETUP.md) for the full backend wiring
  checklist and the exact seams to swap.
