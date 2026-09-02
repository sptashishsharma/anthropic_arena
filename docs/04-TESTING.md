# Testing Strategy

**Project:** Anthropic Arena · **Version:** 0.5.0 · **Date:** 2 September 2026

---

## 1. Approach

**33 automated tests across 8 files**, run with `flutter test`.

The strategy has three layers, chosen so the most valuable tests are also the
cheapest to run:

| Layer | Tests what | Why this layer |
|---|---|---|
| **Content validation** | The question JSON itself | A bad question is a production defect; catch it at build time |
| **Unit — game rules** | Scoring, XP, streaks, badges, unlocking | Pure logic, no widgets, runs in milliseconds |
| **Widget** | Sign-in, navigation, gating, overflow | Guards the paths a user actually walks |

**Deliberate choice: the game engine is tested without any UI.** Because
`ProgressController` and `XpRules` have no widget dependencies, the rules that
matter most are verified directly. We are not driving a UI to assert that 85%
earns two stars.

## 2. Content validation — testing the data, not just the code

This is the most valuable idea in the suite and worth explaining in the demo.

All 689 questions ship as JSON. A malformed row — a duplicate id, three options
instead of four, an answer index pointing past the end of the list — would
reach a learner as a broken or unanswerable question.

So the **content is a test subject**. `flutter test` parses every question and
asserts:

| Check | Courses | Certifications |
|---|---|---|
| Ids are unique | ✅ | ✅ |
| Option count | Exactly 4 | 2–5 |
| Answer index in range | ✅ `correctIndex` | ✅ every `correctIndexes` entry |
| Pass marks are sane percentages | ✅ | ✅ |
| Every cert has a category | — | ✅ |
| At least 8 playable tracks | — | ✅ |

**Effect:** a content author can regenerate `courses.json` from a spreadsheet
and the build tells them immediately if a row is malformed. Bad content fails
the build rather than shipping silently.

## 3. Test inventory

### `content_test.dart` — 4 tests
Course JSON integrity: content loads with at least one course; every question
has 4 options and a valid index; ids are unique across all content; pass marks
are sane percentages.

### `certification_test.dart` — 5 tests
Catalogue present with a category on every credential; every question has valid
options and in-range answers; unique ids, sane pass marks and time limits; plus
two scoring tests — **multi-select is all-or-nothing**, and an exact
multi-select match counts as correct and passes.

### `xp_rules_test.dart` — 7 tests
The game balance, asserted exactly:

| Test | Asserts |
|---|---|
| 0 stars below pass mark | Failing earns nothing |
| 1 star at pass mark | Bare pass |
| 2 stars at 85+ | Strong pass |
| 3 stars only for a perfect run | Mastery is distinct from passing |
| Base XP per correct answer | Core formula |
| Pass bonus at pass mark | +25 |
| Perfect run earns both bonuses | +25 and +50 |

### `progress_test.dart` — 5 tests
The game engine end to end: a perfect attempt scores, passes and unlocks the
next level; a failed attempt leaves the next level locked; **the streak counts
consecutive days and resets after a gap**; progress persists across container
restarts; the course-champion badge unlocks after passing every level.

### `leaderboard_test.dart` — 4 tests
Your own row is **ranked by score, not appended to the bottom** — a real bug
class in leaderboards; a mid-table score lands in the correct slot; players
with no score are hidden; weekly scope ranks on the rolling 7-day total.

### `cert_gate_test.dart` — 5 tests
Guests see the sign-in gate and the exam catalogue never mounts for them; the
secondary link opens the full sign-in page; **gate controls stay tappable at
three screen sizes** (360×640, 800×600, 412×732) — one test parameterised over
a size list.

### `widget_test.dart` — 5 tests
The login screen shows all sign-in options; Microsoft sign-in enters as a
non-guest account; guest sign-in lands on the home shell with 5 tabs; the bottom
bar shrinks its labels on small phones; the learning tab lists the bundled
courses.

### `profile_overflow_test.dart` — 3 tests
The profile header survives a long work email on a small phone; an absurdly long
email still cannot overflow; `StatChip` truncates rather than growing past its
parent.

## 4. Regression tests from real bugs

Two of the eight files exist **because those bugs actually happened**:

| File | Bug it locks down |
|---|---|
| `profile_overflow_test.dart` | Long work emails (`firstname.lastname@sptechusa.com`) overflowed the profile chip on small phones — commit `a340f31` |
| Layout tests in `cert_gate_test.dart` | Gate controls became untappable at certain sizes |

**Policy: a UI bug that reaches a user gets a test before it gets a fix.** That
is why the suite tests three specific screen sizes rather than one.

## 5. Demo test cases

Three tests are worth running live, chosen to show different kinds of value:

**1. Real business logic**
```powershell
flutter test --plain-name "streak counts consecutive days and resets after a gap"
```
Streak logic is date arithmetic with an easy off-by-one. This proves it.

**2. Domain fidelity**
```powershell
flutter test --plain-name "multi-select is all-or-nothing"
```
Shows the exam engine matches how Salesforce actually scores — the product
differentiator, asserted in code.

**3. Engineering maturity**
```powershell
flutter test --plain-name "profile header survives a long work email"
```
A test written *in response to* a real bug. This is the one to highlight.

## 6. Manual test checklist

Covered by hand before each release, since they involve real credentials or
platform behaviour automation can't reach:

- [ ] Microsoft / Entra ID sign-in on web and Android
- [ ] Google sign-in on web
- [ ] Guest → real account upgrade preserves XP and streak
- [ ] Certifications tab locked for guests, unlocked after sign-in
- [ ] Exam countdown auto-submits at 0:00
- [ ] Leaderboard shows your own rank correctly
- [ ] Firestore profile write lands (verified against the database, not the UI)
- [ ] Offline: aeroplane mode still allows play, progress survives
- [ ] Streak notification fires on Android
- [ ] Android release APK installs and runs

## 7. Static analysis

```powershell
flutter analyze lib test
```

`flutter_lints ^5.0.0` via `analysis_options.yaml`, applied to test code as
well as `lib/`.

## 8. What isn't covered, and why

Stated honestly:

| Gap | Reason | Mitigation |
|---|---|---|
| No integration tests against live Firebase | Would need a test project and seeded accounts | Manual checklist + direct database verification |
| No iOS test runs | iOS isn't registered with Firebase | Local-only path is covered by the same unit tests |
| Security rules not unit-tested | Would need the Firebase emulator suite | **This gap caused a real bug** — see below |
| No load or performance testing | Not warranted at current scale | Content reads are local; backend footprint is one small document per user |

### The lesson: the untested gap is where the bug was

The Firestore rules were the one part of the system with no automated test —
and that is exactly where a 27-day production failure came from. The rules'
field allowlist drifted out of step with the client payload, and because the
client swallowed the error, nothing surfaced.

**The fix for the class, not just the instance:** the Firebase emulator suite
supports unit-testing security rules. Adding a test that writes the real
`_mirrorProfile` payload and asserts it is accepted would have caught this in
CI on the day it was introduced.

That is the top item on the testing roadmap.

## 9. Roadmap

1. **Security-rules tests** via the Firebase emulator — the known gap
2. **CI on push** — run `flutter test` and `flutter analyze` on every commit
3. **Golden tests** for the neon/glass components to catch visual regressions
4. **Integration tests** against a dedicated Firebase test project
