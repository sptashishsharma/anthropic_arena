# Claude AI Utilization

**Project:** Anthropic Arena · **Date:** 2 September 2026
**Team:** Claude Commanders — SPTECH USA, Jaipur

---

## 1. Why this matters to the project

SPTECH USA is pushing Claude adoption company-wide to cut manual work and raise
productivity. Anthropic Arena was deliberately built as **evidence for that
argument** — a real, shipped, multi-platform application, built with Claude
rather than demonstrated on a toy example.

The project therefore has two outputs: the product, and the working method.

## 2. Division of labour

Two Claude products were used, each on the half of the project it fits.

| | **Claude Design** | **Claude Code** |
|---|---|---|
| **Owner** | Harsh | Ashish |
| Neon + glassmorphism visual system | ✅ | |
| Logo generation and automation | ✅ | |
| Splash screen design | ✅ | |
| Level-map connection animations | ✅ | |
| Screen layouts and UI direction | ✅ | |
| Backend and Firebase integration | | ✅ |
| State management (Riverpod) | | ✅ |
| Game engine and scoring rules | | ✅ |
| Content pipeline and tooling | | ✅ |
| Test suite | | ✅ |
| Security rules | | ✅ |

## 3. Claude Design — the visual system

The application's entire look was designed with Claude Design against the
**SPTech design system**.

**Neon / glassmorphism treatment.** Rather than a stock Material theme, the app
uses translucent `GlassSurface` panels over an animated `NeonBackground`, on a
gold `#F5A623` and near-black `#0A0C10` palette. This is implemented in
`lib/core/widgets/glass.dart` and applied consistently across all five tabs.

**Logo automation.** The logo set was generated and produced as a full family —
icon, mark, and wordmark, in dark, light and gold variants (6 assets) — rather
than one image resized by hand. The Android launcher icon and PWA icons are
generated from that source via `flutter_launcher_icons`.

**Splash design.** The splash sequence and its brand video treatment, with
static fallbacks for platforms that cannot play video.

**Level-map connection animations.** The winding level map is not a list — the
path between levels, and the way nodes connect and unlock, was designed as a
motion problem rather than a layout problem.

**Design-to-code handoff.** Designs came across as specifications Claude Code
implemented directly, which is why the theme is centralised in
`lib/core/theme/` and the glass treatment is a reusable widget rather than
per-screen styling.

## 4. Claude Code — implementation

Claude Code was used for the engineering half: application code, backend
integration, state management, tests and tooling.

**The whole project is in version control**, so the AI-assisted workflow is
auditable — 24 commits from 7 July to 2 September, each a coherent unit of work
with a descriptive message.

### CLAUDE.md — the key artifact

The most important thing we produced for this workflow is not code. It is
**`CLAUDE.md`, a 213-line instruction file** that Claude Code reads at the start
of every session.

It documents:

- What the project is and the two pillars
- Every build, test and deploy command, with exact syntax
- The architecture, and the rule that new backend features must branch on
  `firebaseReadyProvider` rather than assuming Firebase exists
- The certifications subsystem in detail, including the login gate and why it
  must not be removed
- The content pipeline and how to regenerate questions
- **Gotchas** — the OneDrive lock, the misleading APK build message, the
  Android-only reminders, the certification bank provenance

**Why it matters:** without it, each session starts from zero and rediscovers
the same constraints — or worse, contradicts an earlier decision. With it, work
across weeks stays consistent. When a session was told to add a backend
feature, it followed the local-first pattern because the file said to.

This is the single highest-leverage thing we did with AI on this project.

## 5. How we worked

**Small, reviewable units.** Each commit is one coherent change with a message
explaining the reasoning, not just the diff. `Fix white band below the level map
on short courses` is a bug and its fix; `UI overhaul: responsive shell, rank
tiers, motion, share cards` is a feature set.

**Specify behaviour, not implementation.** Prompts described the desired
outcome and the constraints, leaving the approach open. For example, when
adding the certifications pillar, the requirement given was *"exams must match
real conditions — official pass mark, time limit, auto-submit at zero,
multi-select scored all-or-nothing"*, not a list of classes to write.

**Tests as the acceptance criterion.** Content validation tests were written
alongside the content pipeline, so a malformed question fails the build. The
suite grew to 33 tests without a separate testing phase.

**Regressions get a test.** When the profile chip overflowed with long work
emails, the fix shipped with `profile_overflow_test.dart` so it cannot silently
return.

**Documentation kept current with the code.** `FIREBASE_SETUP.md` and
`MICROSOFT_LOGIN_SETUP.md` were written as those features were built, not
retrofitted.

## 6. Example prompts

Representative of how work was actually specified:

**Architectural constraint**
> "The app must be fully playable offline. Accounts, progress, XP and streaks
> persist on-device. Firebase should add the leaderboard and sync, but its
> absence must degrade the app, not break it. Every auth and progress method
> branches on a single readiness flag."

**Feature with domain fidelity as the requirement**
> "Add a certifications pillar. Exams must reproduce real conditions: the
> official pass mark, time limit and question count per credential, a countdown
> that auto-submits at 0:00, and multi-select questions scored all-or-nothing on
> an exact match. Gate the whole tab behind a non-guest account."

**Debugging from a symptom**
> "The leaderboard hasn't updated since August. The UI shows no error. Find out
> why."

That last one produced the most valuable result on the project — see below.

## 7. A worked example: finding a silent production bug

Worth presenting, because it shows AI-assisted work as investigation rather than
code generation.

**Symptom:** none. The app looked healthy.

**Investigation:**
1. Compared the fields `_mirrorProfile` writes (11) against the `hasOnly()`
   allowlist in `firestore.rules` (8) — three keys unaccounted for
2. Queried the production Firestore REST API directly. **8 profiles, none
   containing `xpWeek`, `weekKey` or `photoUrl`**
3. Checked timestamps: no profile updated since 6 August. Cross-referenced
   against git — v0.5.0, which introduced those fields, shipped 6 August
4. Found the cause of the silence: `.catchError((_) {})` discarding the
   permission error

**Verification:** played a level and re-queried. Database byte-identical — the
write had definitely failed.

**Fix:** added the three keys to the allowlist, added a type check on `xpWeek`,
and commented the coupling so the two lists stay in step.

**Confirmed:** after publishing the rules, a fresh attempt wrote all 11 fields
with `weekKey: 2026-W36` and a current timestamp. The weekly leaderboard worked
for the first time.

**Principle adopted:** *fail loudly in the log, quietly in the UI.*

## 8. What the AI did not do

Stated plainly, because the honest version is more credible:

- **The idea, the problem framing and the business case are ours.** The
  observation that a $200 exam fee makes confidence valuable came from working
  in a Salesforce consultancy, not from a model.
- **Content curation and question sorting** were done by Harsh. Deciding what
  belongs in which level, and at what difficulty, is judgement.
- **Design direction** — the decision to go neon/glass over stock Material, and
  to treat the level map as a motion problem, were human calls that Claude
  Design then executed.
- **Verification.** Every claim in this documentation set was checked against
  the codebase or the live database rather than asserted.

## 9. What we learned

**A persistent instruction file is the highest-leverage artifact.** `CLAUDE.md`
did more for consistency than any individual prompt.

**Specify outcomes and constraints, not implementations.** The best results came
from stating what must be true, not how to build it.

**AI is strongest at investigation, not just generation.** The leaderboard bug
had no visible symptom and had survived 27 days. Systematically comparing code
against production data found it in minutes.

**Verify against reality.** The bug looked fine in the UI. It was only provable
by querying the database directly.

**Version control is what makes the workflow auditable.** Every decision has a
commit and a message explaining why.
