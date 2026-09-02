# Team Contribution & Timeline

**Project:** Anthropic Arena · **Date:** 2 September 2026
**Team:** Claude Commanders — SPTECH USA, Jaipur

---

## 1. Team

| Member | Role |
|---|---|
| **Ashish Sharma** | Development · Database · Backend |
| **Harsh** | Design · UI direction · Testing · Content |

## 2. Contribution split

### Ashish Sharma — Development & Database

| Area | Delivered |
|---|---|
| **Application development** | Flutter app across web, Android and iOS — 9,230 lines of Dart in 42 files |
| **State management** | All 14 Riverpod providers; `AuthController`, `ProgressController`, leaderboard |
| **Game engine** | `recordAttempt()` — scoring, stars, XP, streaks, badge evaluation, persistence |
| **Database** | Firestore schema, the public profile projection, leaderboard queries |
| **Authentication** | Guest, Email, Google, and Microsoft / Entra ID including the Azure configuration |
| **Security** | `firestore.rules` — ownership, guest exclusion, field allowlist, type validation |
| **Content pipeline** | `import_questions.py` and `convert_mcq_bank.js` |
| **Build & release** | Android signing, Firebase Hosting deployment, PWA configuration |
| **Claude Code workflow** | Authored `CLAUDE.md`, the 213-line agent instruction file |
| **Documentation** | README, technical documentation, solution design, Firebase and Microsoft setup guides |

### Harsh — Design, UI & Testing

| Area | Delivered |
|---|---|
| **Visual system** | Neon / glassmorphism treatment across all five tabs |
| **Claude Design workflow** | Design work against the SPTech design system |
| **Logo** | Full logo family — icon, mark, wordmark in dark / light / gold (6 assets), automated |
| **Splash design** | Splash sequence and brand video treatment with static fallbacks |
| **Level-map animations** | Connection and unlock motion between level nodes |
| **UI direction** | Screen layouts, responsive behaviour, rank tier visual language |
| **Testing** | Test scenarios, manual QA across devices and screen sizes |
| **Content curation** | Question sorting — which questions belong in which level, and at what difficulty |
| **Visual QA** | Found the layout defects that became regression tests |

### Shared

Both members contributed to the project idea, scope decisions, and the final
demo. **Both can explain the whole system, not only their own half** — as the
demo rules require.

## 3. A note on git authorship

The repository was created part-way through the project and commits were
authored under a shared identity while the AI-assisted workflow was in use.
**`git log` therefore does not attribute work to individual team members.** The
split above is the accurate record. Individual authorship applies from
`04b06e2` onward.

## 4. Timeline

**7 July 2026 → 2 September 2026** — eight weeks, 24 commits.

### Phase 1 — Foundation (7 July)

The core application built and working in a single day.

| Commit | Milestone |
|---|---|
| `3420f92` | Complete Flutter app: courses, quiz engine, XP / streaks / badges, leaderboard, analysis, brand assets, import tooling |
| `8ffba38` | Visual QA polish and test hardening |
| `618978a` | **Real content loaded — 294 questions, 6 courses, 42 levels** |
| `94cb3e9` | **Firebase wired on web** — real auth, Firestore sync, live leaderboard |
| `5919f92` | PWA branding, release APK signing, Hosting deploy config |

### Phase 2 — Multi-platform (9 July)

| Commit | Milestone |
|---|---|
| `8d23028` | **v0.2.0 — Android registered with Firebase**, live auth and leaderboard in the APK |
| `980332a` | **v0.3.0** — working streak reminders, guest-free leaderboard, full PWA name |
| `d7b331a` | Provider labelling fix |

### Phase 3 — The second pillar (29 July)

| Commit | Milestone |
|---|---|
| `197fdd0` | **Certifications pillar added**, with its non-guest sign-in gate |
| `0f05958` | PWA install prompt for web visitors |

### Phase 4 — Organisation sign-in (6 August)

| Commit | Milestone |
|---|---|
| `692248a` | Microsoft / Entra ID sign-in |
| `51f8733` | Azure + Firebase setup guide written alongside the feature |
| `9fbb0cb` | Microsoft sign-in on mobile |
| `f61529e` | **v0.4.0 shipped** — Microsoft sign-in live on web and Android |

### Phase 5 — UI overhaul (6 August)

| Commit | Milestone |
|---|---|
| `573c90e` | Responsive shell, rank tiers, motion, share cards |
| `5ec197a` | **v0.5.0 shipped** on web and Android |

### Phase 6 — Stabilisation (7–11 August)

| Commit | Milestone |
|---|---|
| `0a88ab1` | Layout fix: white band below the level map |
| `a340f31` | Overflow fix: long work emails in the profile chip — **shipped with a regression test** |

### Phase 7 — Documentation & release readiness (23 August – 2 September)

| Commit | Milestone |
|---|---|
| `04b06e2` | README updated to v0.5.0 |
| `f2e6b16` | Project idea and solution design documents |
| `c3819eb` | Claude Design handoff briefs |
| `8919b46` | Technical documentation |
| `276966c` | Final demo presentation |
| `61792f5` | **Firestore rules fix** — profile writes restored |

## 5. Milestones against the deadline

| Milestone | Target | Delivered | Status |
|---|---|---|---|
| Working prototype | Week 1 | 7 July | ✅ On time |
| Real content loaded | Week 1 | 7 July | ✅ On time |
| Firebase backend live | Week 1 | 7 July | ✅ Ahead |
| Android release | Week 2 | 9 July | ✅ On time |
| Certifications pillar | Week 4 | 29 July | ✅ On time |
| Organisation sign-in | Week 5 | 6 August | ✅ On time |
| UI overhaul (v0.5.0) | Week 5 | 6 August | ✅ On time |
| Documentation complete | Deadline | 2 September | ✅ On time |
| **Final deadline** | **2 September 2026** | — | ✅ **Met** |

**Three versioned releases** were shipped during the project — v0.3.0, v0.4.0
and v0.5.0 — each deployed to live web and a signed Android APK, not just merged
to a branch.

## 6. Working method

**Ship early, ship often.** A working end-to-end app existed on day one and was
improved from there, rather than integrating at the end.

**Deploy every milestone.** Each version went live on Firebase Hosting and as a
signed APK. There was never an untested "it works on my machine" state.

**Documentation alongside features.** `FIREBASE_SETUP.md` and
`MICROSOFT_LOGIN_SETUP.md` were written when those features were built.

**Fix with a test.** UI bugs found in QA shipped with regression tests.

## 7. Deliverables

| Deliverable | Status |
|---|---|
| Live web application | ✅ anthropic-arena.web.app |
| Signed Android APK | ✅ v0.5.0 |
| Source repository | ✅ github.com/sptashishsharma/anthropic_arena |
| README | ✅ Current to v0.5.0 |
| Project idea document | ✅ |
| Solution design + 5 diagrams | ✅ |
| Technical documentation | ✅ |
| Testing strategy | ✅ |
| Claude AI utilisation | ✅ |
| Team contribution & timeline | ✅ This document |
| Presentation deck | ✅ 17 slides |
| Automated tests | ✅ 33 passing |
