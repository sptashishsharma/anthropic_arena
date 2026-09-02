# Claude Design handoff brief — Final Demo Presentation

Open Claude Design with the **SPTech design system**, paste the PROMPT block,
then paste **BRIEF D** underneath in the same message.

**17 slides, 16:9.** Designed to be presented in ~15 minutes by two people.
Speaker notes are included per slide — they are for the presenter, not for the
slide surface.

---

## PROMPT — paste this first

```
Using the SPTech design system, design a 17-slide presentation deck.

Rules:
- One artboard per slide, 16:9 landscape (1920 x 1080 px).
- This is a PRESENTATION, not a document. Slides carry few words in large type.
  Never put a paragraph on a slide. If a slide looks text-heavy, cut words —
  do not shrink the type.
- Minimum body text size equivalent to 20pt. Headlines much larger.
- Use SPTech brand colours and type styles only. Do not invent colours.
- Slide 1 (title) and slide 17 (closing) are full-bleed brand slides using the
  primary brand colour and the SPTech logo.
- Every content slide: small slide title top-left, SPTech logo small in a
  consistent corner, slide number bottom-right.
- Render [BIGSTAT] blocks as one very large number with a short caption beneath
  it — the number should dominate the slide.
- Render [DIAGRAM] blocks as clean boxes-and-arrows visuals in design-system
  colours, filling most of the slide.
- Render [DEMO] slides as a near-empty holding slide: just the title and a
  short prompt line, because a live demo runs at that point.
- Render [QUOTE] blocks as a large centred pull-quote.
- Ignore the "Speaker notes" text when designing the slide surface — it is
  presenter guidance only. If the tool supports a notes field, put it there.
- Tables are allowed but keep them to a maximum of 4 rows on a slide.

Content follows.
```

---
---

# BRIEF D — Final Demo Presentation

---

## Slide 1 — Title

**Anthropic Arena**

Learn · Play · Compete

Team Claude Commanders — SPTECH USA, Jaipur
Ashish Sharma · Harsh
2 September 2026

*Speaker notes: Both presenters on screen. Ashish opens.*

---

## Slide 2 — The Problem

Title: **Certification is expensive to fail**

[BIGSTAT]
**$200**
per Salesforce exam attempt

Three short lines beneath:

- People fail not because they don't know the material
- They fail because they have never sat it under real conditions
- Free practice material has no timer, no scoring, no memory

*Speaker notes: Ashish. Lead with the money. Everyone in the room has either
paid this or approved the expense. Then pivot: the gap is confidence, not
knowledge.*

---

## Slide 3 — Two Drivers

Title: **Why this project, now**

Two columns side by side.

Left column, heading **Certification cost**:
Our consultants need Salesforce credentials. Every attempt costs real money and
a failed attempt costs it twice.

Right column, heading **Claude adoption**:
SPTECH is moving to AI-assisted delivery. We wanted to prove it on something
real, not a toy.

[QUOTE]
So we built a real product, with Claude, that solves a real cost.

*Speaker notes: Ashish. This links the project to organisational strategy —
it's not a side project, it's a demonstration of the direction.*

---

## Slide 4 — What We Built

Title: **Anthropic Arena**

One line, large:
A Flutter app — web, Android and iOS from a single codebase

Two pillars shown as two large panels side by side:

**Pillar 1 — Certifications**
Timed practice exams under real conditions

**Pillar 2 — Learning**
Anthropic course material as a game

Beneath both, one line:
One engine · one progress store · one analytics layer

*Speaker notes: Harsh takes over here. Emphasise "one engine" — that's the
design insight, not two apps bolted together.*

---

## Slide 5 — Pillar 1: Certifications

Title: **We reproduce the exam, not just the questions**

Four short points, each on its own line with an icon:

- Official pass mark, time limit and question count
- Live countdown that auto-submits at 0:00
- Multi-select scored all-or-nothing, exactly like the real exam
- Per-topic weak-spot analysis across attempts

[QUOTE]
Confidence before you spend $200.

*Speaker notes: Harsh. The all-or-nothing scoring is the detail that shows we
studied the real exam. Mention it deliberately.*

---

## Slide 6 — Pillar 2: Learning

Title: **Gamification is the delivery mechanism**

One line, large:
Dry material gets abandoned. The same material behind levels gets finished.

Table — maximum 4 rows, two columns: **Mechanic** | **What it changes**

| Mechanic | What it changes |
|---|---|
| Level gating | Foundations actually get covered |
| Daily streaks | A reason to come back tomorrow |
| XP and rank tiers | Progress is visible and cumulative |
| Leaderboard | Light social pressure among colleagues |

*Speaker notes: Harsh. Be clear gamification is NOT our innovation — it's how
we get completion rates up. Don't oversell it.*

---

## Slide 7 — Live Demo

[DEMO]
Title: **Live Demo**

Single line: anthropic-arena.web.app

*Speaker notes: SIX MINUTES. Order: sign in with Microsoft → Learn tab → course
→ level map → play a level → result screen with stars and XP → Ranking →
Analysis (weak spots) → Certifications → start a timed exam → show the countdown
and a multi-select question → submit → result with per-topic breakdown.
Harsh drives, Ashish narrates. Do not explain architecture here — that's the
next section.*

---

## Slide 8 — Architecture

Title: **Local-first, Firebase behind interfaces**

[DIAGRAM]
Four stacked layers with arrows flowing down, plus a sources row.

PRESENTATION — 5 tabs, all ConsumerWidgets
STATE — Riverpod: AuthController · ProgressController · leaderboardProvider
DOMAIN — XpRules · Badges · Ranks (pure, no I/O)
DATA — ContentRepository «interface» · CertificationRepository «interface»
SOURCES — Bundled JSON · SharedPreferences · Firebase Auth · Cloud Firestore

*Speaker notes: Ashish takes the technical section. One sentence: "every
significant decision follows from local-first."*

---

## Slide 9 — The Offline Switch

Title: **One boolean drives everything**

[DIAGRAM]
Firebase.initializeApp → decision diamond.
YES branch → live auth, Firestore mirror, live leaderboard.
NO branch → local account, prefs only, demo standings.
Both branches converge into a single box: IDENTICAL UI.

One line beneath:
iOS is not registered with Firebase. It takes the offline path automatically —
no code branch of its own.

*Speaker notes: Ashish. This is the slide that shows architectural thinking.
The app works on aeroplane wifi and at a conference. That's deliberate.*

---

## Slide 10 — Technology Choices

Title: **What we chose, and what we rejected**

Table — 4 rows, four columns: **Decision** | **Chose** | **Rejected** | **Why**

| Decision | Chose | Rejected | Why |
|---|---|---|---|
| Framework | Flutter | React Native | One codebase, three platforms |
| State | Riverpod | setState, BLoC | Testable without widgets |
| Content | JSON behind an interface | Hardcoded Dart | Offline, swappable, validated |
| Exam scoring | All-or-nothing | Partial credit | Matches the real exam |

*Speaker notes: Ashish. Being able to name what you rejected is what separates
a decision from a default.*

---

## Slide 11 — Security

Title: **Seven gates on every write**

[DIAGRAM]
A vertical chain: Authenticated? → Owns this document? → Not a guest? → Fields
match the allowlist? → Name valid? → XP non-negative? → ALLOW. Any failure exits
sideways to a red DENY.

One line beneath:
Answer history never leaves the device. The cloud holds an 11-field public
projection.

*Speaker notes: Ashish. If asked about the Firebase API keys being in the repo:
they are client keys, they ship in every client by design, and security is
enforced by these rules — not by hiding config.*

---

## Slide 12 — A Bug We Found

Title: **A silent failure, and what it taught us**

Three lines, generously spaced:

1. An empty catch handler discarded a Firestore permission error
2. The leaderboard froze for 17 days while the UI looked perfectly healthy
3. Found by querying the database directly and comparing field sets

[QUOTE]
Fail loudly in the log, quietly in the UI.

*Speaker notes: Ashish. Do not skip this slide. Volunteering a real bug you
found, diagnosed and fixed reads as engineering maturity. Expect a follow-up
question and welcome it.*

---

## Slide 13 — Testing

Title: **33 tests, and content that validates itself**

[BIGSTAT]
**33**
automated tests across 8 files

Three short points:

- Game rules unit-tested directly — no widgets needed
- Content validation: a malformed question fails the build, not production
- Two regression tests exist because those bugs happened once

*Speaker notes: Harsh covers testing. Have the three demo test cases ready to
run if asked: streak reset, multi-select all-or-nothing, and the long-email
overflow test.*

---

## Slide 14 — How We Used Claude

Title: **Claude Code and Claude Design**

Two columns.

Left, heading **Claude Design**:
- Neon and glassmorphism visual system
- Logo generation and automation
- Splash screen design
- Level-map connection animations

Right, heading **Claude Code**:
- Backend and Firebase integration
- State management and game engine
- Test suite
- CLAUDE.md — a 213-line agent instruction file

[QUOTE]
The project is itself the evidence for the productivity argument.

*Speaker notes: Both. Harsh covers the Claude Design column, Ashish the Claude
Code column. Mention CLAUDE.md specifically — a persistent instruction file is
what made the AI collaboration consistent across weeks.*

---

## Slide 15 — Team Contribution

Title: **Who built what**

Two columns.

Left, heading **Ashish Sharma**:
Development · Database and Firebase · State management and game engine ·
Security rules · Claude Code workflow

Right, heading **Harsh**:
Design and UI direction · Claude Design system · Testing · Question sorting and
content curation

One line beneath:
Both members can explain the whole system, not just their own half.

*Speaker notes: Say this line out loud — the demo rules require it explicitly.*

---

## Slide 16 — Future Scope

Title: **What's next, and what we deliberately deferred**

Table — 4 rows, two columns: **Limitation** | **Path forward**

| Limitation | Path forward |
|---|---|
| 8 of 41 credentials have banks | Content work — the app already lists the rest |
| Content updates need a release | FirestoreContentRepository, no UI change |
| iOS not registered with Firebase | Console registration, about an hour |
| Leaderboard capped at top 50 | Composite index and pagination |

[QUOTE]
Every one of these is a swap behind an interface that already exists.

*Speaker notes: Harsh closes. Frame these as deliberate deferrals with known
fixes, not as things we forgot.*

---

## Slide 17 — Closing

Full-bleed brand slide.

**Thank you**

anthropic-arena.web.app
github.com/sptashishsharma/anthropic_arena

Questions

*Speaker notes: Both stay on screen for Q&A. See the Q&A prep sheet.*
