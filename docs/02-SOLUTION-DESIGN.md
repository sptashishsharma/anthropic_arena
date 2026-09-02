# Solution Design

**Project:** Anthropic Arena · **Version:** 0.5.0 · **Date:** 2 September 2026

---

## 1. Design principle

> **Local-first, with Firebase layered behind swappable interfaces.**

Every significant decision in this codebase follows from that one sentence.

The application is **fully functional offline**. Accounts, progress, XP, streaks
and stars all persist on-device. Firebase is **additive** — it contributes the
leaderboard, cross-device identity and cloud sync — but its absence degrades
the app rather than breaking it.

**Why:** a demo or a training session cannot depend on conference wifi. A
learner on a commute should not lose their streak. And a backend outage should
never make the product unusable.

## 2. System architecture

```mermaid
graph TD
    subgraph P["PRESENTATION — lib/features/"]
        A1[Splash / Auth]
        A2[Home Shell<br/>5 tabs, responsive]
        A3[Learn → Level Map → Quiz]
        A4[Certifications → Exam → Result]
        A5[Ranking / Analysis / Profile]
    end

    subgraph S["STATE — Riverpod · lib/state/providers.dart"]
        B1[AuthController<br/>identity + profile mirror]
        B2[ProgressController<br/>THE GAME ENGINE]
        B3[leaderboardProvider]
        B4[firebaseReadyProvider<br/>online/offline switch]
    end

    subgraph D["DOMAIN — lib/gamification/"]
        C1[XpRules<br/>XP + star thresholds]
        C2[Badges catalogue]
        C3[Ranks — 7 tiers]
    end

    subgraph R["DATA — lib/data/"]
        E1[ContentRepository<br/>«interface»]
        E2[CertificationRepository<br/>«interface»]
    end

    subgraph X["SOURCES"]
        F1[(Bundled JSON<br/>courses · certifications)]
        F2[(SharedPreferences<br/>on-device)]
        F3[(Firebase Auth)]
        F4[(Cloud Firestore<br/>users/uid)]
    end

    P --> S
    B2 --> D
    S --> R
    E1 --> F1
    E2 --> F1
    B1 --> F2
    B2 --> F2
    B1 --> F3
    B1 --> F4
    B3 --> F4
    B4 -.governs.-> B1
    B4 -.governs.-> B2
    B4 -.governs.-> B3
```

### Layer responsibilities

| Layer | Owns | Never does |
|---|---|---|
| **Presentation** | Widgets, navigation, layout | Business rules, storage |
| **State** | Orchestration, persistence, sync | Rendering |
| **Domain** | Scoring, badges, ranks — pure functions | I/O |
| **Data** | Loading content behind interfaces | Knowing about widgets |

Every screen is a `ConsumerWidget` reading providers. No widget touches
`SharedPreferences` or Firestore directly.

## 3. The online/offline switch

The entire online/offline decision reduces to **one boolean**, set once at
startup:

```mermaid
flowchart TD
    S([App start]) --> I[main.dart:<br/>Firebase.initializeApp]
    I --> Q{Succeeded?}
    Q -->|yes| R[firebaseReadyProvider = true]
    Q -->|no / unsupported platform| L[firebaseReadyProvider = false]

    R --> RA[Auth → Firebase Auth]
    R --> RB[Progress → prefs + Firestore mirror]
    R --> RC[Leaderboard → live Firestore top 50]

    L --> LA[Auth → local device account]
    L --> LB[Progress → prefs only]
    L --> LC[Leaderboard → bundled demo standings]

    RA --> U([Identical UI])
    RB --> U
    RC --> U
    LA --> U
    LB --> U
    LC --> U
```

**The UI is identical in both modes.** No screen knows which path it is on.
iOS, which is not yet registered with Firebase, takes the right-hand path
automatically with no code branch of its own.

## 4. Core flow — completing a level

The most important sequence in the app. This is the "end-to-end" path:
frontend → state → domain → local storage → backend → database.

```mermaid
sequenceDiagram
    actor U as Learner
    participant Q as QuizScreen
    participant PC as ProgressController
    participant XR as XpRules
    participant SP as SharedPreferences
    participant AC as AuthController
    participant FS as Cloud Firestore

    U->>Q: answers final question
    Q->>PC: recordAttempt(courseId, levelId, correct, total)
    PC->>XR: starsFor(score, passMark)
    XR-->>PC: 0–3 stars
    PC->>XR: xpFor(correct, passed, perfect)
    XR-->>PC: XP (+25 pass, +50 perfect)
    PC->>PC: update streak, append history & per-day XP
    PC->>PC: evaluate badge predicates
    PC->>SP: persist UserProgress
    SP-->>PC: ok
    Note over PC,SP: Progress is now SAFE — everything below is best-effort
    PC->>AC: syncProgress()
    AC->>FS: set users/{uid} (11 fields)
    FS->>FS: security rules evaluate
    alt rules allow
        FS-->>AC: written → leaderboard updates
    else rules reject
        FS-->>AC: PERMISSION_DENIED
        Note over AC: logged, not thrown —<br/>local progress unaffected
    end
    PC-->>Q: new state
    Q->>U: stars, XP, review screen
```

**Design note.** Local persistence happens *before* the network call, and the
network call cannot fail the operation. The learner never loses progress
because of a backend problem.

**Lesson learned.** The original implementation discarded that error entirely
(`.catchError((_) {})`). A rules/payload mismatch therefore failed silently for
17 days — the leaderboard froze while the UI looked perfectly healthy. It was
found by querying Firestore directly and comparing field sets against the
client payload. The rules were corrected and the swallow replaced with a log.
**Fail loudly in the log, quietly in the UI.**

## 5. Data model

```mermaid
erDiagram
    COURSE ||--o{ LEVEL : contains
    LEVEL ||--o{ QUESTION : contains
    CERTIFICATION ||--o{ EXAMSET : "has 1..n"
    EXAMSET ||--o{ CERTQUESTION : contains
    PLAYER ||--|| USERPROGRESS : owns
    USERPROGRESS ||--o{ QUIZATTEMPT : records
    USERPROGRESS ||--o{ CERTATTEMPT : records
    PLAYER ||--o| PUBLICPROFILE : mirrors

    COURSE { string id string title int levels }
    LEVEL { string id int passMark }
    QUESTION { string id string topic list options int correctIndex string explanation }
    CERTIFICATION { string id string category int passMark int timeLimitMinutes int scoredCount bool retired }
    EXAMSET { string id string label string dateIso }
    CERTQUESTION { string id string topic list options list correctIndexes }
    PLAYER { string uid string name string tag enum provider }
    USERPROGRESS { int xp int streakDays map stars list badges map xpPerDay }
    QUIZATTEMPT { string levelId int score int stars date at }
    CERTATTEMPT { string certId string setId int score bool passed date at }
    PUBLICPROFILE { string name int xp int xpWeek string weekKey int streakDays }
```

### Storage split

| Where | What | Why |
|---|---|---|
| **Bundled JSON** | All questions | Works offline, ships with the app, validated by tests |
| **SharedPreferences** | Full progress, attempt history | Source of truth; survives offline |
| **Firestore `users/{uid}`** | 11-field public profile only | Only what the leaderboard needs |

**Deliberate:** answer history never leaves the device. The cloud holds a small
public projection, not the learner's full record. Less to secure, less to leak.

## 6. Security model

```mermaid
flowchart TD
    W[Client writes users/uid] --> A{Authenticated?}
    A -->|no| D1[DENY]
    A -->|yes| B{auth.uid == doc id?}
    B -->|no| D2[DENY — cannot write another player]
    B -->|yes| C{provider != anonymous?}
    C -->|no| D3[DENY — guests never compete]
    C -->|yes| E{keys hasOnly allowlist?}
    E -->|no| D4[DENY — no arbitrary fields]
    E -->|yes| F{name is string, ≤ 40 chars?}
    F -->|no| D5[DENY]
    F -->|yes| G{xp, xpWeek are int ≥ 0?}
    G -->|no| D6[DENY — no negative XP]
    G -->|yes| OK[ALLOW]
```

### Controls in place

| Control | Implementation |
|---|---|
| Ownership | `request.auth.uid == uid` — you may only write your own profile |
| Guest exclusion | Anonymous providers cannot write at all |
| Field allowlist | `hasOnly([...])` — 11 permitted keys, nothing else |
| Type + range checks | `xp`/`xpWeek` must be non-negative integers |
| Length cap | Display name ≤ 40 characters |
| Content immutability | `courses` collection is `allow write: if false` |
| Private history | Attempt data never leaves the device |
| Credential hygiene | Signing keystore and `key.properties` are git-ignored |
| Exam-bank gating | Certifications require a non-guest account |

**Firebase client keys are not secrets.** They ship in every client by design;
security is enforced by the rules above, not by hiding configuration.

**Tenant restriction.** `AuthConfig.microsoftTenant` controls which Microsoft /
Entra ID accounts may sign in, so the deployment can be limited to the
organisation.

## 7. Scalability

### Reads scale to zero cost

All 689 questions ship inside the app bundle. **Content reads generate no
backend traffic at all** — question load is O(1) in users. Adding 10,000
learners adds nothing to the content bill.

### The backend footprint is deliberately tiny

Per learner, the cloud holds **one document of eleven fields**. Writes occur
only on level completion, not per question.

### Known ceiling, and the fix

| Constraint | Today | Scale path |
|---|---|---|
| Leaderboard | Top 50, client-sorted | Firestore composite index + pagination |
| Weekly board | `xpWeek` + `weekKey` reset per ISO week | Already designed; needs a scheduled reset function |
| Content updates | Requires an app release | `FirestoreContentRepository` — the interface already exists |
| Attempt history | Capped on-device (200 quiz / 100 exam) | Sub-collection `users/{uid}/attempts` — rules already written |

**The seams are pre-built.** Each row above is an implementation swap behind an
existing interface, not a redesign. That is the payoff of the repository
pattern.

### Content scaling

New credentials are **data, not code**:

```
edit assets/content/certifications.json  →  flutter test  →  release
```

Two authoring pipelines already automate this — `import_questions.py`
(CSV/Excel → JSON) and `convert_mcq_bank.js` (XLSX → JSON). Adding a
credential requires no engineering.

## 8. Key technical decisions

| Decision | Chosen | Rejected | Why |
|---|---|---|---|
| Framework | **Flutter** | React Native, native ×2 | One codebase → web + Android + iOS; web enables a zero-install demo |
| State | **Riverpod** | setState, BLoC, Provider | Compile-safe, testable without widgets — the engine is unit-tested directly |
| Content | **Bundled JSON behind an interface** | Hardcoded Dart, direct Firestore | Offline-capable, swappable, test-validated |
| Persistence | **SharedPreferences** | SQLite, Hive | Progress is one small object; a database would be over-engineering |
| Backend | **Firebase** | Custom API | Auth + Firestore + Hosting with no server to operate |
| Auth | **Microsoft / Entra ID** | Email only | Colleagues sign in with existing work accounts |
| Balance | **One `XpRules` file** | Scattered constants | Tuning is one file, and unit-tested |
| Exam scoring | **All-or-nothing multi-select** | Partial credit | Matches how the real exam scores — realism is the product |

## 9. Quality gates

- **33 automated tests** across 8 files
- **Content validation in CI-style tests** — malformed questions fail the build
  rather than shipping (unique ids, option counts, in-range answers, sane pass
  marks)
- **`flutter_lints`** via `analysis_options.yaml`
- **Regression tests written from real bugs** — two overflow tests exist
  because those bugs happened once

See `03-TECHNICAL-DOCUMENTATION.md` for module-level detail and
`04-TESTING.md` for the test strategy.
