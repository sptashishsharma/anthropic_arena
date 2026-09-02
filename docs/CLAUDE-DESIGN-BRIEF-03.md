# Claude Design handoff brief — Technical Documentation

Same procedure as before: open Claude Design with the **SPTech design system**,
paste the PROMPT block, then paste **BRIEF C** underneath in the same message.

---

## PROMPT — paste this first

```
Using the SPTech design system, lay out the following as a professional
technical reference document.

Rules:
- One artboard per page, A4 portrait (794 x 1123 px).
- Page 1 is a cover: document title, project name, version, team name, member
  names, date. Use the SPTech logo and primary brand colour.
- Every following page: running header with the document title on the left and
  "Anthropic Arena v0.5.0" on the right, page number bottom right.
- Use SPTech heading and body type styles. Do not invent colours outside the
  design system.
- Render every table as a styled table with a coloured header row and
  alternating row shading.
- Render blocks marked [CODE] in a monospace font on a subtle tinted panel with
  a thin border. Preserve line breaks and indentation exactly.
- Render blocks marked [CALLOUT] as a highlighted panel.
- Render blocks marked [WARNING] as a highlighted panel in the design system's
  warning or alert colour, with a warning icon.
- Render blocks marked [DIAGRAM] as a clean boxes-and-arrows diagram in
  design-system colours.
- This is a reference document — favour scannable tables over long prose.
- Break onto a new page rather than shrinking type to fit.

Content follows.
```

---
---

# BRIEF C — Technical Documentation

**Cover page**

- Title: **Technical Documentation**
- Project: Anthropic Arena · Version 0.5.0 (build 5)
- Team: Claude Commanders — SPTECH USA, Jaipur
- Members: Ashish Sharma · Harsh
- Date: 2 September 2026

---

**Page 2 — Technology Stack**

Table — three columns: **Layer** | **Technology** | **Version**

| Layer | Technology | Version |
|---|---|---|
| Framework | Flutter (Dart) | SDK 3.5.0 |
| State management | flutter_riverpod | 3.3.2 |
| Auth | firebase_auth | 6.5.4 |
| Database | cloud_firestore | 6.6.0 |
| Firebase core | firebase_core | 4.11.0 |
| Local storage | shared_preferences | 2.5.0 |
| Charts | fl_chart | 1.2.0 |
| Typography | google_fonts | 6.2.1 |
| Video | video_player | 2.11.1 |
| Notifications | flutter_local_notifications | 22.0.1 |
| Sharing | share_plus | 13.3.0 |
| Deep links | url_launcher | 6.3.1 |
| Effects | confetti | 0.8.0 |
| Linting | flutter_lints | 5.0.0 |

[CALLOUT]
14 runtime dependencies. No custom backend server, no ORM, no code-generation
step.

Second table — two columns: **Metric** | **Value**

| Metric | Value |
|---|---|
| Dart source | 9,230 lines across 42 files |
| Files tracked in git | 154 |
| Automated tests | 33 across 8 files |
| Course content | 294 questions · 6 courses · 42 levels |
| Certification content | 395 questions · 41 credentials |

---

**Page 3 — Repository Structure**

[CODE]
```
anthropic_arena/
├── lib/
│   ├── main.dart              bootstrap: Firebase, prefs, ProviderScope
│   ├── app.dart               MaterialApp, themes, routing
│   ├── core/                  theme, layout, shared widgets
│   ├── data/                  models + repositories
│   ├── state/providers.dart   ALL app state — 14 providers
│   ├── gamification/          XpRules, badges, ranks, reminders
│   └── features/              one folder per screen
├── assets/content/            courses.json · certifications.json
├── test/                      8 test files
├── tools/                     content authoring scripts
├── firestore.rules            database security rules
└── docs/                      project documentation
```

[CALLOUT]
**Architectural rule:** dependencies point inward. features/ may read state/,
state/ may read data/ and gamification/, and gamification/ is pure — it depends
on nothing but models.

---

**Page 4 — State Management**

All application state lives in a single file, lib/state/providers.dart, as 14
Riverpod providers.

Table — two columns: **Provider** | **Purpose**

| Provider | Purpose |
|---|---|
| prefsProvider | SharedPreferences, injected at startup |
| firebaseReadyProvider | The online/offline switch |
| contentRepositoryProvider | Course content source |
| coursesProvider | Async list of courses |
| certificationRepositoryProvider | Certification content source |
| certificationsProvider | Async credential catalogue |
| themeProvider | Dark / light / system |
| remindersProvider | Streak notification opt-in |
| onboardingSeenProvider | First-run flag |
| authProvider | Identity and profile mirror |
| progressProvider | The game engine |
| leaderboardProvider | Standings, live or demo |
| leaderboardScopeProvider | All-time vs weekly |
| leaderboardIsLiveProvider | Whether standings are live |

---

**Page 5 — AuthController API**

[CODE]
```dart
Future<String?> signInGuest()
Future<String?> signInEmail({email, password, ...})
Future<String?> signInGoogle()
Future<String?> signInMicrosoft()
Future<String?> signInDemoApple()
void            rename(String name)
void            syncProgress()
Future<void>    signOut()
```

[CALLOUT]
Each sign-in method returns null on success, or an error message string on
failure. **Errors are values, not exceptions** — the UI renders them directly.

Body:

syncProgress() writes an 11-field public profile to Firestore at users/{uid}.
Guests never sync — this is enforced in two places independently.

---

**Page 6 — ProgressController: The Game Engine**

recordAttempt() is the single most important method in the codebase. In order,
it performs seven steps:

1. Compute stars via XpRules.starsFor(scorePct, passMark)
2. Compute XP via XpRules.xpFor(...)
3. Update the daily streak
4. Append to bounded attempt history and per-day XP
5. Evaluate every badge predicate for new unlocks
6. Persist UserProgress to SharedPreferences
7. Call syncProgress() — best-effort, cannot fail the operation

[CALLOUT]
Step 6 happens before step 7. The learner never loses progress because of a
backend problem.

Body:

recordCertAttempt() mirrors this for exams. isUnlocked(course, level) gates each
level on the previous one having passed. resetAll() clears progress.

---

**Page 7 — Game Rules**

The entire game balance lives in one 30-line file: lib/gamification/xp_rules.dart

[CODE]
```dart
static const passBonus    = 25;
static const perfectBonus = 50;
static const dailyGoalXp  = 100;

static int starsFor(int scorePct, int passMark)
static int xpFor({...})
```

Table — two columns: **Rule** | **Value**

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

[CALLOUT]
Tune balance here and nowhere else. Companion files: badges.dart (10 badge
predicates), ranks.dart (7 XP tiers), reminder_service.dart (Android
notifications).

---

**Page 8 — Data Formats: Course Questions**

[CODE]
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

[CALLOUT]
Constraints enforced automatically by the test suite: unique ids, exactly four
options, correctIndex in range, sane pass marks. A malformed row fails the build
rather than shipping.

---

**Page 9 — Data Formats: Certification Questions**

[CODE]
```json
{
  "id": "admin",
  "name": "Platform Administrator",
  "category": "Administrator & App Builder",
  "passMark": 68,
  "timeLimitMinutes": 105,
  "scoredCount": 60,
  "sets": [{
    "id": "admin-set-1",
    "label": "Spring 26 Pattern",
    "questions": [{
      "id": "adm-1",
      "topic": "Sharing and Visibility",
      "options": ["A", "B", "C", "D", "E"],
      "correctIndexes": [1, 3]
    }]
  }]
}
```

Table — two columns: **Difference from course questions** | **Detail**

| Difference | Detail |
|---|---|
| Option count | 2 to 5, not exactly 4 |
| Answer field | correctIndexes is a list, not a single index |
| Multi-select | More than one entry makes it multi-select |
| Scoring | All-or-nothing on an exact set match |

---

**Page 10 — Firestore Schema**

Collection: users/{uid} — the public profile the leaderboard reads.

Table — three columns: **Field** | **Type** | **Notes**

| Field | Type | Notes |
|---|---|---|
| name | string | 40 characters maximum |
| tag | string | Player handle |
| provider | string | Sign-in method |
| photoUrl | string | Optional |
| xp | int | Zero or greater |
| xpWeek | int | Rolling weekly total |
| weekKey | string | ISO week identifier |
| streakDays | int | |
| levelsCompleted | int | |
| badges | int | Count |
| updatedAt | timestamp | |

[WARNING]
This list must stay in step with the hasOnly() allowlist in firestore.rules. A
mismatch rejects the entire write, silently.

---

**Page 11 — Setup, Build and Deploy**

[CODE]
```powershell
git clone https://github.com/sptashishsharma/anthropic_arena.git
cd anthropic_arena
flutter pub get
flutter analyze lib test
flutter test
```

Table — two columns: **Task** | **Command**

| Task | Command |
|---|---|
| Browser preview | flutter run -d chrome |
| Android device | flutter run |
| Full test suite | flutter test |
| One test file | flutter test test/certification_test.dart |
| Lint | flutter analyze lib test |
| Web release | flutter build web --release |
| Android release | flutter build apk --release |
| Deploy everything | firebase deploy |
| Deploy rules only | firebase deploy --only firestore:rules |

[CALLOUT]
Security rules can also be published from the Firebase Console with no CLI
installed at all.

---

**Page 12 — Known Issues and Gotchas**

[WARNING]
**The Firestore allowlist trap.** The client writes 11 fields; the rules use
hasOnly(), which rejects the entire write if one unlisted key is present. In
v0.5.0 two new fields were added to the client but not the rules, and the error
was swallowed by an empty catch handler. Result: profile writes failed silently
for 17 days and the leaderboard froze while the UI looked healthy. If you add a
field to the profile write, add it to firestore.rules in the same commit.

[WARNING]
**Misleading Android build output.** Gradle output is redirected outside the
OneDrive tree, so flutter build apk always ends with "Gradle build failed to
produce an .apk file". That message is cosmetic — the signed APK really is
produced, at C:\dev\builds\anthropic_arena\app\outputs\flutter-apk\app-release.apk

[WARNING]
**OneDrive file locking.** The project folder syncs to OneDrive, which can lock
Flutter's regenerated ephemeral directories and fail a build. Fix: delete
ios\Flutter\ephemeral and retry, or pause sync.

---

**Page 13 — Platform Differences**

Table — four columns: **Behaviour** | **Web** | **Android** | **iOS**

| Behaviour | Web | Android | iOS |
|---|---|---|---|
| Firebase | Yes | Yes | No — local only |
| Streak notifications | No | Yes | No |
| Google sign-in | Yes | No | No |
| Microsoft sign-in | Yes | Yes | No |

[CALLOUT]
Unsupported features return a user-facing explanation rather than failing
silently.

---

**Page 14 — Extension Points**

Designed-in seams that require no UI changes.

Table — three columns: **To do this** | **Implement** | **Swap at**

| To do this | Implement | Swap at |
|---|---|---|
| Serve content from the cloud | FirestoreContentRepository | contentRepositoryProvider |
| Sync attempt history | Write to users/{uid}/attempts | Rules already exist |
| Add a credential | Append to certifications.json | No code change |
| Add an exam set | Append to that credential's sets array | No code change |
| Change game balance | Edit xp_rules.dart | No code change |
| Add a badge | Append a predicate to badges.dart | No code change |

[CALLOUT]
Every row is an implementation swap behind an interface that already exists —
not a redesign. That is the payoff of the repository pattern.
