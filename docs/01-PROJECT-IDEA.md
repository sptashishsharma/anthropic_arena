# Project Idea & Innovation

**Project:** Anthropic Arena
**Team:** Claude Commanders — SPTECH USA, Jaipur
**Members:** Ashish Sharma, Harsh
**Date:** 2 September 2026

---

## 1. The problem

SPTECH USA is a Salesforce consultancy. Two pressures shaped this project.

### 1.1 Certification is expensive to fail

Salesforce certification is how consultants prove capability to clients, so the
organisation actively wants its people certified. But every attempt carries a
real cost:

| | |
|---|---|
| Exam fee | **≈ $200 USD per attempt** |
| Cost of failing | The fee is spent, and a retake costs again |
| Cost to the team member | Time, and the confidence hit of an expensive failure |

The problem isn't that people don't know the material. It's that **they walk in
unsure**, because they have never experienced the exam under real conditions —
the countdown, the multi-select questions where a single wrong checkbox voids
the whole answer, the pacing across 60 questions.

Free practice material exists, but it is static: PDFs and question lists with no
timer, no scoring, no record of what you got wrong last time.

### 1.2 The organisation is moving to an AI-assisted way of working

SPTECH is pushing Claude adoption company-wide to cut manual work and raise
productivity. This project was deliberately built as a **demonstration of that
shift** — a real, shipped application built with Claude Code and Claude Design
rather than a toy example. The way it was built is part of the point.

## 2. What we built

**Anthropic Arena** — a Flutter application (web + Android + iOS from one
codebase) with two pillars sharing a single game engine.

### Pillar 1 — Certifications

A realistic practice-exam environment for Salesforce credentials:

- **Real exam conditions** — the official pass mark, time limit and question
  count per credential, with a live countdown that **auto-submits at 0:00**
- **Faithful scoring** — multi-select questions are all-or-nothing on an exact
  match, exactly as the real exam scores them
- **Weak-spot analysis** — per-credential, per-topic breakdown of what you keep
  getting wrong, so revision is targeted rather than a re-read of everything
- **Attempt history** — best score, number of attempts, progress over time

The purpose is **confidence before spending $200**. A team member who has sat
the pattern five times under a timer, and has seen their weak topics named,
walks into the real exam knowing what to expect.

### Pillar 2 — Learning

The same engine applied to Anthropic Skill Jar course material: a level map,
XP, streaks, stars, badges and a leaderboard. This supports the organisation's
Claude-adoption push — it makes learning the AI tooling something people
actually finish.

### Why gamification

Gamification is **not** the innovation here — it is the delivery mechanism. Dry
material with a completion bar gets abandoned. The same material behind levels,
XP, streaks and a visible leaderboard gets finished, because there is a reason
to come back tomorrow.

Concretely, the app applies:

| Mechanic | What it changes |
|---|---|
| Level gating | You cannot skip ahead, so foundations are actually covered |
| Daily streaks | Creates a reason to return tomorrow, not "sometime" |
| XP + rank tiers | Progress is visible and cumulative rather than pass/fail |
| Stars (1–3) | Rewards mastery, not just a bare pass |
| Leaderboard | Light social pressure among colleagues |
| Badges | Recognises milestones the score alone doesn't capture |

## 3. What makes it different

**One engine, two problems.** Most practice-exam tools do exams. Most learning
apps do courses. Anthropic Arena runs both pillars on the same progress store,
XP system and analytics layer. Adding a new certification is a JSON file, not a
new product.

**It reproduces the exam, not just the questions.** The differentiator against
free question dumps is the *conditions* — timer, auto-submit, exact
multi-select scoring, question palette. That is what builds confidence.

**Analysis is per-topic, not per-score.** Knowing you scored 61% is not useful.
Knowing you fail consistently on Sharing & Visibility is.

**Local-first.** The app is fully usable offline. Firebase adds the leaderboard
and cross-device sync, but nothing breaks without it — a deliberate
architectural choice, described in the Solution Design document.

**Built the way the organisation wants to work.** Claude Code for
implementation, Claude Design for the interface. The project is itself evidence
for the productivity argument SPTECH is making internally.

## 4. Business value

**Direct cost avoidance.** At ≈$200 per attempt, preventing a single failed
exam pays for the effort spent building this. Across a consultancy putting many
people through certification, the saving compounds.

**Faster time to certified.** Targeted revision against named weak topics is
faster than re-reading whole study guides.

**Client-facing capability.** Certified consultants are what the business
sells. Anything that raises the pass rate raises billable capability.

**Internal Claude adoption.** The learning pillar gives the organisation a
finishable path through its own AI-enablement material.

**Reusable platform.** The content pipeline means new credentials, or entirely
new subject areas, are added as data. The application does not change.

## 5. Scope delivered

| | Delivered |
|---|---|
| Platforms | Web (live), Android (signed APK), iOS (builds, local-only) |
| Learning content | 6 courses · 42 levels · **294 questions** |
| Certification catalogue | **41 credentials** across 7 categories |
| Certification questions | **395** across 8 playable credentials |
| Sign-in | Guest, Email, Google, Microsoft / Entra ID |
| Automated tests | **33** across 8 files |

Live: **https://anthropic-arena.web.app**

## 6. Known limitations

Stated honestly, with the intended fix:

| Limitation | Path forward |
|---|---|
| 8 of 41 credentials have question banks | Content work; the app already lists the rest |
| Content ships bundled, so updates need a release | `FirestoreContentRepository` — designed for, no UI change needed |
| iOS not registered with Firebase | Console registration, ~1 hour |
| Streak reminders are Android-only | Web push, or accept the platform difference |
| Cert banks derive from third-party material | Author original questions before any public release |
| Leaderboard capped at top 50 | Pagination |
