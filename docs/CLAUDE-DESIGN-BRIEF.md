# Claude Design handoff brief — Anthropic Arena

**How to use this file**

1. Open Claude Design with the **SPTech design system** selected.
2. Copy the **PROMPT** block below and paste it in.
3. Then paste **BRIEF A** (or **BRIEF B**) underneath it, in the same message.
4. Generate, review the artboards, then export to PDF.

Do one brief at a time — A and B are separate documents.

---

## PROMPT — paste this first

```
Using the SPTech design system, lay out the following as a professional
multi-page project document.

Rules:
- One artboard per page, A4 portrait (794 x 1123 px).
- Page 1 is a cover: document title, project name, team name, member names,
  date. Use the SPTech logo and primary brand colour.
- Every following page: running header with the document title on the left and
  "Anthropic Arena" on the right, page number bottom right.
- Use SPTech heading and body type styles throughout. Do not invent new colours
  outside the design system.
- Render every table as a proper styled table with a coloured header row and
  alternating row shading.
- Render every block marked [DIAGRAM] as a clean boxes-and-arrows diagram using
  design-system colours. Do not use screenshots or clip art.
- Render every block marked [CALLOUT] as a highlighted panel, visually distinct
  from body text.
- Keep body text at a readable size. Break onto a new page rather than
  shrinking type to fit.

Content follows.
```

---
---

# BRIEF A — Project Idea & Innovation

**Cover page**

- Title: **Project Idea & Innovation**
- Project: Anthropic Arena
- Team: Claude Commanders — SPTECH USA, Jaipur
- Members: Ashish Sharma · Harsh
- Date: 2 September 2026

---

**Page 2 — The Problem**

Heading: *Certification is expensive to fail*

SPTECH USA is a Salesforce consultancy. Certification is how consultants prove
capability to clients, so the organisation actively wants its people certified.
Every attempt carries a real cost.

[CALLOUT]
**≈ $200 USD per exam attempt.** Fail, and the fee is gone — a retake costs
again.

Body:

The problem is not that people don't know the material. It is that they walk in
unsure, because they have never experienced the exam under real conditions —
the countdown, the multi-select questions where one wrong checkbox voids the
whole answer, the pacing across 60 questions.

Free practice material exists, but it is static: PDFs and question lists with
no timer, no scoring, and no record of what you got wrong last time.

Heading: *A second driver — the move to AI-assisted work*

SPTECH is pushing Claude adoption company-wide to cut manual work and raise
productivity. This project was deliberately built as a demonstration of that
shift: a real, shipped application built with Claude Code and Claude Design.
How it was built is part of the point.

---

**Page 3 — What We Built**

Heading: *Anthropic Arena*

A Flutter application — web, Android and iOS from one codebase — with two
pillars sharing a single game engine.

Sub-heading: **Pillar 1 — Certifications**

- Real exam conditions: official pass mark, time limit and question count, with
  a live countdown that auto-submits at 0:00
- Faithful scoring: multi-select is all-or-nothing on an exact match, exactly as
  the real exam scores it
- Weak-spot analysis: per-credential, per-topic breakdown of what you keep
  getting wrong, so revision is targeted
- Attempt history: best score, attempts, progress over time

[CALLOUT]
The purpose is **confidence before spending $200**. Someone who has sat the
pattern five times under a timer, and has seen their weak topics named, knows
what to expect.

Sub-heading: **Pillar 2 — Learning**

The same engine applied to Anthropic Skill Jar course material: a level map,
XP, streaks, stars, badges and a leaderboard. This supports the organisation's
Claude-adoption push by making the training something people actually finish.

---

**Page 4 — Why Gamification**

Gamification is not the innovation. It is the delivery mechanism. Dry material
behind a completion bar gets abandoned; the same material behind levels, XP and
streaks gets finished, because there is a reason to come back tomorrow.

Table — two columns: **Mechanic** | **What it changes**

| Mechanic | What it changes |
|---|---|
| Level gating | You cannot skip ahead, so foundations are actually covered |
| Daily streaks | A reason to return tomorrow, not "sometime" |
| XP and rank tiers | Progress is visible and cumulative, not pass/fail |
| Stars (1–3) | Rewards mastery, not a bare pass |
| Leaderboard | Light social pressure among colleagues |
| Badges | Recognises milestones a score doesn't capture |

---

**Page 5 — What Makes It Different**

Four points, each a heading with a short paragraph:

**One engine, two problems.** Most practice tools do exams; most learning apps
do courses. Anthropic Arena runs both on the same progress store, XP system and
analytics layer. Adding a credential is a JSON file, not a new product.

**It reproduces the exam, not just the questions.** The differentiator against
free question dumps is the conditions — timer, auto-submit, exact multi-select
scoring, question palette.

**Analysis is per-topic, not per-score.** Knowing you scored 61% is not useful.
Knowing you fail consistently on Sharing and Visibility is.

**Local-first.** Fully usable offline. Firebase adds the leaderboard and sync,
but nothing breaks without it.

---

**Page 6 — Business Value**

Table — two columns: **Value** | **Detail**

| Value | Detail |
|---|---|
| Direct cost avoidance | At ~$200 per attempt, preventing one failed exam pays for the build |
| Faster time to certified | Targeted revision beats re-reading whole study guides |
| Client-facing capability | Certified consultants are what the business sells |
| Internal Claude adoption | A finishable path through the organisation's AI-enablement material |
| Reusable platform | New credentials are data, not code |

---

**Page 7 — Scope Delivered**

Table — two columns: **Area** | **Delivered**

| Area | Delivered |
|---|---|
| Platforms | Web (live), Android (signed APK), iOS (builds, local-only) |
| Learning content | 6 courses · 42 levels · 294 questions |
| Certification catalogue | 41 credentials across 7 categories |
| Certification questions | 395 across 8 playable credentials |
| Sign-in | Guest, Email, Google, Microsoft / Entra ID |
| Automated tests | 33 across 8 files |

[CALLOUT]
Live at **anthropic-arena.web.app**

---

**Page 8 — Known Limitations**

Table — two columns: **Limitation** | **Path forward**

| Limitation | Path forward |
|---|---|
| 8 of 41 credentials have question banks | Content work; the app already lists the rest |
| Content ships bundled, so updates need a release | FirestoreContentRepository — designed for, no UI change |
| iOS not registered with Firebase | Console registration, about an hour |
| Streak reminders are Android-only | Web push, or accept the platform difference |
| Cert banks derive from third-party material | Author original questions before public release |
| Leaderboard capped at top 50 | Pagination |

---
---

# BRIEF B — Solution Design

**Cover page**

- Title: **Solution Design**
- Project: Anthropic Arena · Version 0.5.0
- Team: Claude Commanders — SPTECH USA, Jaipur
- Members: Ashish Sharma · Harsh
- Date: 2 September 2026

---

**Page 2 — Design Principle**

[CALLOUT]
**Local-first, with Firebase layered behind swappable interfaces.**

Every significant decision in this codebase follows from that one sentence.

The application is fully functional offline. Accounts, progress, XP, streaks and
stars all persist on-device. Firebase is additive — it contributes the
leaderboard, cross-device identity and cloud sync — but its absence degrades the
app rather than breaking it.

**Why:** a demo cannot depend on conference wifi. A learner on a commute should
not lose their streak. A backend outage should never make the product unusable.

---

**Page 3 — System Architecture**

[DIAGRAM]
Four stacked layers, arrows flowing downward, plus a data-sources row at the
bottom.

Layer 1 — PRESENTATION (lib/features/): Splash & Auth · Home Shell (5 tabs) ·
Learn → Level Map → Quiz · Certifications → Exam → Result · Ranking · Analysis ·
Profile

Layer 2 — STATE (Riverpod): AuthController · ProgressController (the game
engine) · leaderboardProvider · firebaseReadyProvider

Layer 3 — DOMAIN (lib/gamification/): XpRules · Badges · Ranks

Layer 4 — DATA (lib/data/): ContentRepository «interface» ·
CertificationRepository «interface»

Sources row: Bundled JSON · SharedPreferences · Firebase Auth · Cloud Firestore

Show firebaseReadyProvider with dashed arrows to the other three state objects,
labelled "governs".

Table below — three columns: **Layer** | **Owns** | **Never does**

| Layer | Owns | Never does |
|---|---|---|
| Presentation | Widgets, navigation, layout | Business rules, storage |
| State | Orchestration, persistence, sync | Rendering |
| Domain | Scoring, badges, ranks | Any I/O |
| Data | Loading content behind interfaces | Knowing about widgets |

---

**Page 4 — The Online / Offline Switch**

[DIAGRAM]
A decision flow. App start → Firebase.initializeApp → decision diamond
"Succeeded?"

- YES branch → firebaseReadyProvider = true → three boxes: Auth via Firebase
  Auth · Progress via prefs + Firestore mirror · Leaderboard via live Firestore
  top 50
- NO branch → firebaseReadyProvider = false → three boxes: Auth via local
  device account · Progress via prefs only · Leaderboard via bundled demo
  standings

Both branches converge on a single box: **Identical UI**

[CALLOUT]
The UI is identical in both modes. No screen knows which path it is on. iOS,
not yet registered with Firebase, takes the offline path automatically with no
code branch of its own.

---

**Page 5 — End-to-End Flow: Completing a Level**

[DIAGRAM]
A vertical sequence diagram with these actors as columns: Learner · QuizScreen ·
ProgressController · XpRules · SharedPreferences · AuthController · Firestore

Steps in order:
1. Learner answers final question
2. QuizScreen calls recordAttempt(courseId, levelId, correct, total)
3. ProgressController asks XpRules for stars (0–3)
4. ProgressController asks XpRules for XP (+25 pass bonus, +50 perfect bonus)
5. ProgressController updates streak, history and per-day XP
6. ProgressController evaluates badge predicates
7. ProgressController persists to SharedPreferences
8. Marker line: "Progress is now SAFE — everything below is best-effort"
9. ProgressController calls AuthController.syncProgress()
10. AuthController writes 11 fields to Firestore users/{uid}
11. Security rules evaluate → allowed (leaderboard updates) or rejected (logged,
    local progress unaffected)
12. Result returns to the Learner: stars, XP, review screen

[CALLOUT]
**Design note.** Local persistence happens before the network call, and the
network call cannot fail the operation. The learner never loses progress
because of a backend problem.

---

**Page 6 — Lesson Learned**

Heading: *A silent failure, and what it taught us*

The original implementation discarded the sync error entirely, using an empty
catch handler. A mismatch between the security-rules allowlist and the client
payload therefore failed silently for 17 days — the leaderboard froze while the
UI looked perfectly healthy.

How it was found: querying Firestore directly and comparing the stored field
set against what the client sends. Every profile was missing three fields, and
no profile had been updated since the release that introduced them.

The fix: correct the rules allowlist, and replace the silent swallow with a log.

[CALLOUT]
**Principle adopted: fail loudly in the log, quietly in the UI.**

---

**Page 7 — Data Model**

[DIAGRAM]
An entity-relationship diagram.

- COURSE (1) → (many) LEVEL → (many) QUESTION
- CERTIFICATION (1) → (many) EXAMSET → (many) CERTQUESTION
- PLAYER (1) → (1) USERPROGRESS
- USERPROGRESS (1) → (many) QUIZATTEMPT
- USERPROGRESS (1) → (many) CERTATTEMPT
- PLAYER (1) → (0..1) PUBLICPROFILE, labelled "mirrors"

Table below — three columns: **Where** | **What** | **Why**

| Where | What | Why |
|---|---|---|
| Bundled JSON | All 689 questions | Works offline, ships with the app, test-validated |
| SharedPreferences | Full progress and attempt history | Source of truth, survives offline |
| Firestore users/{uid} | An 11-field public profile | Only what the leaderboard needs |

[CALLOUT]
Answer history never leaves the device. The cloud holds a small public
projection, not the learner's full record — less to secure, less to leak.

---

**Page 8 — Security Model**

[DIAGRAM]
A vertical decision chain. "Client writes users/{uid}" enters at the top and
passes through seven gates; any failure exits sideways to a red DENY box, and
passing all seven reaches a green ALLOW box.

Gates in order:
1. Authenticated?
2. auth.uid equals the document id? (cannot write another player)
3. Provider is not anonymous? (guests never compete)
4. Keys match the allowlist exactly? (no arbitrary fields)
5. Name is a string of 40 characters or fewer?
6. xp and xpWeek are integers of zero or more? (no negative XP)
7. ALLOW

Table below — two columns: **Control** | **Implementation**

| Control | Implementation |
|---|---|
| Ownership | You may only write your own profile |
| Guest exclusion | Anonymous providers cannot write at all |
| Field allowlist | Eleven permitted keys, nothing else |
| Type and range checks | XP values must be non-negative integers |
| Length cap | Display name limited to 40 characters |
| Content immutability | Course content is read-only to all clients |
| Private history | Attempt data never leaves the device |
| Credential hygiene | Signing keystore kept out of version control |
| Exam-bank gating | Certifications require a non-guest account |

[CALLOUT]
Firebase client keys are not secrets — they ship in every client by design.
Security is enforced by these rules, not by hiding configuration.

---

**Page 9 — Scalability**

Heading: *Reads scale to zero cost*

All 689 questions ship inside the app bundle, so content reads generate no
backend traffic at all. Adding ten thousand learners adds nothing to the
content bill. Per learner the cloud holds one document of eleven fields, and
writes occur only on level completion — not per question.

Table — three columns: **Constraint** | **Today** | **Scale path**

| Constraint | Today | Scale path |
|---|---|---|
| Leaderboard | Top 50, client-sorted | Composite index and pagination |
| Weekly board | Resets per ISO week | Scheduled reset function |
| Content updates | Require an app release | FirestoreContentRepository |
| Attempt history | Capped on-device | Firestore sub-collection, rules already written |

[CALLOUT]
Every row above is an implementation swap behind an interface that already
exists — not a redesign. That is the payoff of the repository pattern.

---

**Page 10 — Key Technical Decisions**

Table — four columns: **Decision** | **Chosen** | **Rejected** | **Why**

| Decision | Chosen | Rejected | Why |
|---|---|---|---|
| Framework | Flutter | React Native, native ×2 | One codebase for web, Android, iOS |
| State | Riverpod | setState, BLoC | Compile-safe and testable without widgets |
| Content | Bundled JSON behind an interface | Hardcoded Dart | Offline-capable, swappable, validated |
| Persistence | SharedPreferences | SQLite, Hive | Progress is one small object |
| Backend | Firebase | Custom API | Auth, database and hosting with no server to run |
| Auth | Microsoft / Entra ID | Email only | Colleagues use existing work accounts |
| Balance | One XpRules file | Scattered constants | Tuning is one file, unit-tested |
| Exam scoring | All-or-nothing multi-select | Partial credit | Matches the real exam — realism is the product |

---

**Page 11 — Quality Gates**

- 33 automated tests across 8 files
- Content validation inside the test suite: malformed questions fail the build
  rather than shipping. Checks unique ids, option counts, in-range answers and
  sane pass marks
- flutter_lints static analysis on every file
- Regression tests written from real bugs — two overflow tests exist because
  those bugs happened once
