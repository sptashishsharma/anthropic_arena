# Claude Design handoff brief — User Guide

Open Claude Design with the **SPTech design system**, paste the PROMPT block,
then paste **BRIEF E** underneath in the same message.

---

## PROMPT — paste this first

```
Using the SPTech design system, lay out the following as a friendly end-user
guide. The reader is a colleague using the app for the first time, not a
developer.

Rules:
- One artboard per page, A4 portrait (794 x 1123 px).
- Page 1 is a cover: app name, tagline "Learn · Play · Compete", the words
  "User Guide", version 0.5.0, and the SPTech logo.
- Page 2 is a contents page.
- Every following page: running header with "User Guide" left and "Anthropic
  Arena" right, page number bottom right.
- Warmer and more spacious than a technical document. Generous white space,
  larger body text, short lines. This should feel welcoming.
- Use SPTech colours and type styles only. Do not invent colours.
- Render [TIP] blocks as a friendly highlighted panel with a lightbulb icon.
- Render [WARNING] blocks as a highlighted panel in the alert colour with a
  warning icon.
- Render [STEPS] blocks as a clear numbered sequence with generous spacing.
- Render tables as styled tables with a coloured header row.
- Where a block is marked [SCREENSHOT: description], leave a clearly outlined
  placeholder box of roughly that shape with the description as caption text,
  so screenshots can be dropped in later.
- Break onto a new page rather than shrinking type to fit.

Content follows.
```

---
---

# BRIEF E — User Guide

---

**Page 1 — Cover**

**Anthropic Arena**
Learn · Play · Compete

**User Guide**
Version 0.5.0

SPTECH USA · Jaipur

---

**Page 2 — Contents**

1. Getting started
2. Signing in
3. The five tabs
4. Learning: courses, levels and quizzes
5. Certifications: practice exams
6. Ranking
7. Analysis
8. Profile and settings
9. How scoring works
10. Frequently asked questions
11. Troubleshooting

---

**Page 3 — Getting Started**

Heading: *On a computer*

Open **anthropic-arena.web.app** in any modern browser. Nothing to install.

[TIP]
**Install it as an app.** In Chrome or Edge, an install icon appears in the
address bar. Click it and Anthropic Arena opens in its own window, works
offline, and gets a desktop shortcut.

Heading: *On Android*

Either open the web address and tap Install when prompted, or install the
release APK supplied by your team.

Heading: *On iPhone or iPad*

Open the web address in Safari, tap Share, then Add to Home Screen.

[WARNING]
On iOS the app runs in local-only mode. Your progress is saved on the device,
but you will not appear on the shared leaderboard.

Heading: *Works offline*

Once loaded, the app works without a connection. Every question is stored inside
the app. Progress saves on your device and syncs when you are back online.

---

**Page 4 — Signing In**

Table — three columns: **Option** | **Best for** | **Notes**

| Option | Best for | Notes |
|---|---|---|
| Microsoft | Colleagues at work | Uses your existing work account — recommended |
| Google | Personal use on web | Web only |
| Email and password | Anyone | Create a password on first use |
| Guest | A quick look | Limited — see below |
| Apple | Demo only | Not a full sign-in yet |

Heading: *Guest mode limits*

Guest sign-in is one tap and lets you try the learning pillar straight away. But
guests cannot open the Certifications tab, cannot appear on the leaderboard, and
cannot sync progress to another device.

[TIP]
**Upgrading from guest does not lose your progress.** Go to Profile, sign out,
then sign in with Microsoft, Google or email. Your XP, streak and stars carry
over.

---

**Page 5 — The Five Tabs**

On a phone these appear along the bottom. On a tablet or desktop they become a
menu down the left side.

[SCREENSHOT: the app home screen showing the five-tab navigation]

Table — two columns: **Tab** | **What it's for**

| Tab | What it's for |
|---|---|
| Learn | Courses, levels and quizzes |
| Certifications | Timed practice exams — sign-in required |
| Ranking | Leaderboards |
| Analysis | Your statistics and weak spots |
| Profile | Identity, badges and settings |

---

**Page 6 — Learning: The Learn Tab**

At the top of the Learn tab you will find three things:

- **Daily goal ring** — fills as you earn XP. The target is 100 XP a day.
- **Continue card** — jumps straight back to where you left off.
- **Course list** — six courses, 42 levels, 294 questions in total.

[SCREENSHOT: the Learn tab showing the daily goal ring and course list]

Heading: *The level map*

Tap a course to open its level map — a winding path of level nodes.

Table — two columns: **Node appearance** | **Meaning**

| Node appearance | Meaning |
|---|---|
| Lit up | Unlocked, ready to play |
| Dimmed with a lock | Locked — pass the previous level first |
| Showing 1 to 3 stars | Completed, with your best result |

[TIP]
Levels unlock in order. You cannot skip ahead, so foundations always get
covered.

---

**Page 7 — Playing a Quiz**

Each question shows four options. Tap one to select it.

Table — two columns: **Control** | **What it does**

| Control | What it does |
|---|---|
| Next | Confirm and move on |
| Previous | Go back and change an earlier answer |
| Skip | Come back to it later |
| Get unstuck | Opens a resource link for that topic |

Question order is shuffled every attempt, so replaying is not memorising a
sequence.

Heading: *After the quiz*

You will see your score, stars earned and XP gained — plus a full review: every
question, what you answered, the correct answer, and an explanation.

[TIP]
**Read the review.** It is where the actual learning happens.

You can replay any level at any time to improve your stars. Your best result is
always kept.

---

**Page 8 — Certifications**

[WARNING]
Sign-in required. Guests see a sign-in prompt instead of the exam catalogue.

Heading: *Choosing a credential*

Credentials are grouped by category: Administrator and App Builder, Architect,
Artificial Intelligence, Associate and Foundations, Consultant, Developer, and
Marketing.

41 credentials are listed. 8 currently have question banks, totalling 395
questions. The rest show "Coming soon".

Table — two columns: **Credential** | **Questions**

| Credential | Questions |
|---|---|
| Platform Developer I | 195 |
| Platform Administrator | 150 |
| Platform Developer II | 10 |
| Agentforce Specialist | 8 |
| CPQ Specialist | 8 |
| Data Cloud (Data 360) Consultant | 8 |
| Sales Cloud Consultant | 8 |
| Service Cloud Consultant | 8 |

---

**Page 9 — Taking an Exam**

The exam mirrors the real thing.

[STEPS]
1. Pick a credential, and an exam set if more than one is offered
2. The exam opens with the official question count and a live countdown
3. Answer questions in any order — use the palette to jump around
4. Submit when ready, or let the timer auto-submit at 0:00

Table — two columns: **Feature** | **Detail**

| Feature | Detail |
|---|---|
| Pass mark | The official mark for that credential |
| Time limit | The official limit, counting down live |
| Auto-submit | At 0:00, whatever you have answered is scored |
| Question palette | Jump to any question, see what is unanswered |
| Random draw | Questions differ every attempt |

[WARNING]
**Multi-select questions are scored all-or-nothing.** Every correct option must
be ticked, and no incorrect ones. Three right out of four scores zero. This is
exactly how the real Salesforce exam scores, and it is the single most common
reason people fail.

---

**Page 10 — Your Exam Result**

You will see your score, pass or fail against the official mark, a per-topic
breakdown, and a full review of every question.

[SCREENSHOT: an exam result screen showing the score and per-topic breakdown]

[TIP]
**The per-topic breakdown is the most useful part of the whole app.** It tells
you which subject areas to revise, instead of re-reading everything.

---

**Page 11 — Ranking and Analysis**

Heading: *Ranking*

Two leaderboards, switchable at the top: All-time ranks by total XP ever earned;
Weekly ranks by XP earned this week and resets on Monday.

The top three appear on a podium. Your own row is always highlighted, wherever
you are in the table. Guests do not appear, players with no score are hidden,
and the board shows the top 50.

Heading: *Analysis*

Table — two columns: **Section** | **Shows**

| Section | Shows |
|---|---|
| XP per day | A chart of your activity over time |
| Recent scores | Your last attempts |
| Overall accuracy | Percentage correct across everything |
| Weak spots | Topics you get wrong most often |
| Certifications | Best score and per-topic trend for each credential |

[TIP]
**Weak spots is the section to act on.** It names the topics costing you marks.

---

**Page 12 — Profile and Settings**

Table — two columns: **Item** | **What it does**

| Item | What it does |
|---|---|
| Name and tag | Your leaderboard identity — tap the name to change it |
| Rank tier | Recruit through to Legend, by total XP |
| Badges | Ten to collect; locked ones show a progress bar |
| Theme | Dark, Light, or match your device |
| Streak reminders | A daily nudge — Android only |
| Share card | Generates an image of your stats to share |
| Reset progress | Erases everything, cannot be undone |
| Sign out | Also how you upgrade from a guest account |

---

**Page 13 — How Scoring Works**

Two tables side by side if space allows.

Table one — two columns: **Action** | **XP**

| Action | XP |
|---|---|
| Each correct answer | Base XP |
| Passing a level | +25 bonus |
| A perfect run | +50 extra bonus |
| Daily goal | 100 XP |

Table two — two columns: **Stars** | **Requires**

| Stars | Requires |
|---|---|
| No stars | Below the pass mark |
| One star | Reaching the pass mark |
| Two stars | 85 percent or above |
| Three stars | 100 percent — a perfect run |

Heading: *Streaks*

Complete at least one level a day to keep your streak alive. Miss a day and it
resets to zero.

Heading: *Badges*

Ten badges for milestones — first level, streak lengths, perfect runs,
completing every level in a course, and more. Locked badges show how close you
are.

---

**Page 14 — Frequently Asked Questions**

Render each as a bold question with a short answer beneath.

**Do I need an internet connection?**
Only for the first load. After that everything works offline and syncs when you
reconnect.

**Will I lose progress if I switch from guest to a real account?**
No. Sign out, then sign in properly — XP, streak and stars all carry over.

**Why can't I open Certifications?**
You are signed in as a guest. Sign out and sign in with Microsoft, Google or
email.

**Why am I not on the leaderboard?**
Guests are excluded, and so are players with no score. Sign in properly and
complete one level.

**Can I retake a level?**
Yes, as often as you like. Your best result is kept.

**Why does my score come out at zero on some exam questions?**
They are probably multi-select. Partial answers score zero, the same as the real
exam.

**Why do some credentials say "Coming soon"?**
Their question banks are not written yet. 8 of 41 are playable today.

**Is my data private?**
Your answers and attempt history never leave your device. Only a small public
profile — name, XP, streak, badge count — is shared, and only so the leaderboard
can work.

---

**Page 15 — Troubleshooting**

Render each as a bold problem with a short answer beneath.

**The app won't load.**
Check your connection for the first load, then refresh. If it persists, clear
the site data and reload.

**My progress disappeared.**
Progress is stored per device and per account. Check you are signed into the
same account. Guest progress lives only on that device and browser.

**My score isn't on the leaderboard.**
Confirm you are not a guest, that you have completed at least one level, and
that you are online.

**The exam timer ran out before I finished.**
That is intended — the real exam does the same. Use the question palette to pace
yourself next time.

**Videos don't play.**
Some browsers block autoplay. The app falls back to a static image
automatically. Nothing is broken.

**I'm on iPhone and there's no leaderboard.**
iOS runs in local-only mode for now. Everything else works and your progress is
saved on the device.

---

**Page 16 — Need Help**

Centred closing page.

**Need help?**

Contact the project team

**Claude Commanders**
SPTECH USA · Jaipur

Ashish Sharma · Harsh

anthropic-arena.web.app
