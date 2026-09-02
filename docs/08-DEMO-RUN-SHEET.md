# Demo Run-Sheet

**For Ashish & Harsh only — not a submission document.**
Print this or keep it open on a second device during the demo.

---

## 0. Before you walk in — do this the night before, not the morning of

- [ ] Confirm the Firestore rules fix is **published** (Firebase Console → Firestore → Rules → confirm current version includes `xpWeek`, `weekKey`, `photoUrl`)
- [ ] Play one full level on a **real account** and confirm it appears on the leaderboard
- [ ] Confirm **anthropic-arena.web.app** loads on the venue's wifi, not just at home
- [ ] Have a **second network ready** — phone hotspot — in case venue wifi fails
- [ ] Sign into a **real (non-guest) test account** on the demo device *before* you're on stage — don't do sign-in flow live if you can avoid the wait
- [ ] Have one course level **already close to passing** so the live quiz doesn't run long
- [ ] Have a **certification exam bookmarked** and ready to start (Platform Administrator or Platform Developer I — both have full banks)
- [ ] Fully charge the demo device; disable notifications and Do Not Disturb
- [ ] Have the **GitHub repo open in a tab**, in case someone asks to see code
- [ ] Have **this run-sheet and the Q&A sheet below** open on a phone, not the shared screen
- [ ] Decide who plugs in / shares screen first

## 1. Timing overview — total ~19 minutes + Q&A

| Time | Segment | Slides | Who |
|---|---|---|---|
| 0:00–0:30 | Intro | 1 | Both |
| 0:30–2:30 | The problem & why | 2–3 | Ashish |
| 2:30–4:30 | What we built | 4–6 | Harsh |
| **4:30–10:30** | **Live demo** | 7 | **Harsh drives, Ashish narrates** |
| 10:30–14:30 | Architecture & decisions | 8–11 | Ashish |
| 14:30–15:30 | The bug we found | 12 | Ashish |
| 15:30–16:30 | Testing | 13 | Harsh |
| 16:30–17:30 | Claude AI usage | 14 | Both |
| 17:30–18:30 | Team & future scope | 15–16 | Harsh |
| 18:30–19:00 | Closing | 17 | Both |
| — | **Q&A** | — | Both |

**If running long, cut from here first:** slide 10 (technology choices — can be answered in Q&A instead), not from the live demo or the bug slide. Those two are what make this demo memorable.

## 2. Live demo — exact click path

Do this in this order, no improvising. If something doesn't load, don't debug live — say "let me show you that on the next slide" and move on.

1. Open **anthropic-arena.web.app** — already signed in
2. **Learn tab** → open a course → show the level map
3. Tap the level that's already near-complete → answer the remaining questions
4. Show the **result screen** — stars, XP earned
5. Tap into the **answer review** — show one explanation
6. Switch to **Ranking tab** → point out your row, highlighted
7. Switch to **Analysis tab** → show the XP chart and one weak-spot topic
8. Switch to **Certifications tab** → pick a credential with a full bank
9. Start the exam → show the **countdown timer** and the **question palette**
10. Answer one **multi-select question** — narrate the all-or-nothing rule out loud
11. **Submit** (don't wait for the timer) → show the result and per-topic breakdown

**Total: ~6 minutes.** Rehearse this exact sequence at least twice before demo day so it takes 6 minutes, not 12.

**If the leaderboard doesn't update live:** don't panic-debug on stage. Say "profile sync can take a moment" and move to Analysis — you already confirmed it works from your pre-demo check.

## 3. What each person must be ready to explain

**The rule is explicit: both of you must be able to explain the whole project, not just your own part.** Judges may ask either of you anything.

**Ashish should be able to explain**, in addition to the technical parts:
- Why gamification was chosen, and the $200 cost argument
- What Claude Design contributed (neon/glass, logo, splash, level-map animation)
- Question sorting and content curation decisions

**Harsh should be able to explain**, in addition to the design parts:
- The offline-first architecture in plain terms
- Why multi-select scoring is all-or-nothing
- What the Firestore rules bug was and how it was found

**Do one full run-through with roles swapped** before demo day — whoever is weaker on a section, drill that section once more.

## 4. Q&A — business questions

**Q: Who is this for?**
A: SPTECH consultants preparing for Salesforce certification, plus anyone completing the Anthropic Skill Jar training internally.

**Q: Why gamify this instead of just posting the questions?**
A: Completion. Dry material with a progress bar gets abandoned; the same material behind levels, streaks and a leaderboard gets finished. Gamification isn't the innovation — it's the delivery mechanism.

**Q: What's the actual business value?**
A: Direct cost avoidance — each exam attempt is ~$200, and preventing one failed attempt pays for the effort of building this. Beyond that, faster time-to-certified and more billable, certified consultants.

**Q: Why certifications specifically, not something else?**
A: SPTECH is a Salesforce consultancy — certification is how we prove capability to clients, and exam anxiety plus cost was a real, named problem, not a hypothetical one.

**Q: What did this cost to build?**
A: No paid infrastructure beyond Firebase's free Spark tier. Development time across 8 weeks, using Claude Code and Claude Design.

**Q: Is this something we'd actually roll out?**
A: [Answer honestly based on your own view — this is a judgement call, not a technical fact.]

**Q: How do you know it actually helps people pass?**
A: We don't have exam outcome data yet — that would be the natural next metric to track. What we can show today is engagement: streaks, completion, and per-topic weak-spot detection that targets revision.

## 5. Q&A — technical questions

**Q: Why Flutter?**
A: One codebase compiles to web, Android and iOS. Web specifically gives us a zero-install demo link — anyone can try it without downloading anything.

**Q: Why Riverpod over other state management?**
A: The game engine (scoring, streaks, badges) needs to be unit-tested without spinning up widgets. Riverpod controllers are plain Dart classes we can test directly — that's why we have 33 fast tests instead of slow widget tests for logic.

**Q: What happens if Firebase goes down?**
A: Nothing breaks. The app is local-first — accounts, progress, XP and streaks all live on-device. Firebase only adds the leaderboard and cross-device sync. That's a deliberate architecture decision, not an accident.

**Q: Tell us about a bug you hit.**
A: [This is your best answer — walk through the leaderboard bug exactly as told on slide 12: security rules had an allowlist that fell out of sync with what the app was writing, the write was silently rejected for weeks, we found it by querying the database directly rather than trusting the UI, and fixed both the rules and the silent error-swallowing that hid it.]

**Q: How do you secure the backend?**
A: Firestore security rules enforce ownership, block guest writes, allowlist exactly which fields can be written, and validate types and ranges — all server-side, not trusted to the client. Answer history never leaves the device at all; only a small public profile syncs.

**Q: Aren't your Firebase API keys exposed in the repo?**
A: Yes, deliberately — those are client keys, meant to ship inside every client app. They're extractable from the compiled app regardless of whether they're in the repo. Actual security is enforced by the Firestore rules, not by hiding configuration.

**Q: How would this scale to thousands of users?**
A: All 689 questions ship inside the app bundle, so content reads generate zero backend load regardless of user count. Each learner is one small Firestore document, written only on level completion. The known ceiling is the leaderboard's top-50 cap, and the fix — pagination — is a small, scoped change.

**Q: What would you do differently?**
A: Add automated tests for the security rules using the Firebase emulator. That's the one part of the system with no test coverage, and it's exactly where the production bug came from.

**Q: What's not finished?**
A: iOS isn't registered with Firebase yet, so it runs local-only. Only 8 of 41 certifications have question banks so far. Both are named explicitly in our future-scope slide — they're deferred, not forgotten.

## 6. If something breaks

| Problem | Do this |
|---|---|
| Wifi fails | Switch to phone hotspot immediately, don't troubleshoot on stage |
| App won't load | Have a **screen recording of the full demo path** ready as backup — mention "let me show you a recording of this" |
| Leaderboard doesn't update | Move on to Analysis tab; you already verified it works pre-demo |
| A question you can't answer | Say so plainly: "good question, we haven't tested that yet — here's what we'd expect" — don't guess and present it as fact |
| Running out of time | Cut slide 10, never cut the live demo or the bug story |

## 7. Closing line

Land on: *"The project is live at anthropic-arena.web.app, the code and every document are in our repository, and we're both happy to go deeper on any part of it."*
