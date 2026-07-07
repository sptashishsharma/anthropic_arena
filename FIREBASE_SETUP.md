# Connecting Anthropic Arena to Firebase

The app is built local-first: it is fully playable today with on-device
storage and bundled content. This guide is the checklist for switching on the
online backend once the Firebase account exists. Each step says **who** does
it, because the account itself must be created under your identity
(see the Technical Design, Section 5).

## 1. Create the Firebase project — *you (Ashish/Harsh)*

1. Go to <https://console.firebase.google.com> and sign in with the Google
   account that should own the app.
2. **Add project** → name it `anthropic-arena` → Analytics **on**.
3. In Project settings → add an **Android app** (package
   `com.sptechusa.anthropic_arena`) and an **iOS app** (bundle
   `com.sptechusa.anthropicArena`).

## 2. Wire the Flutter project — *Claude, once step 1 is done*

```powershell
dart pub global activate flutterfire_cli
flutterfire configure          # signs in, generates lib/firebase_options.dart
flutter pub add firebase_core firebase_auth cloud_firestore firebase_analytics firebase_crashlytics firebase_messaging google_sign_in sign_in_with_apple
```

Then, in code (all seams already exist):

| Swap | Where |
|------|-------|
| `AssetContentRepository` → `FirestoreContentRepository` | `lib/state/providers.dart` (`contentRepositoryProvider`) |
| Local demo sign-in → Firebase Auth (Google / Apple / email / anonymous-guest) | `AuthController` in `lib/state/providers.dart` |
| Local progress persistence → mirror writes to `users/{uid}` | `ProgressController._persist` |
| `demoRivals` list → Firestore query `users` ordered by `xp` desc, limit 50 | `leaderboardProvider` |

## 3. Firestore data model

```
courses/{courseId}                      title, tagline, description, order, color
courses/{courseId}/levels/{levelId}     title, order, topic, passMark, xpPerCorrect, questions[]
users/{uid}                             name, tag, xp, streakDays, lastPlayDay, badges[]
users/{uid}/attempts/{attemptId}        levelId, courseId, date, scorePct, correct, total, topic tallies
```

Load content with the existing script:

```
pip install firebase-admin
python tools/import_questions.py questions.csv --upload --key serviceAccountKey.json
```

(Service account key: Project settings → Service accounts → Generate new
private key. Keep it out of git.)

## 4. Security rules (starting point)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /courses/{doc=**} { allow read: if true; allow write: if false; }
    match /users/{uid} {
      allow read: if true;                  // leaderboard needs public read of name/xp
      allow write: if request.auth != null && request.auth.uid == uid;
      match /attempts/{doc=**} {
        allow read, write: if request.auth != null && request.auth.uid == uid;
      }
    }
  }
}
```

## 5. Remaining services

- **Cloud Messaging**: "don't lose your streak" reminder. The Profile screen
  already has the (disabled) toggle; enable it and register the device token.
- **Crashlytics + Analytics**: init in `main()` after `Firebase.initializeApp`.
  Log `level_started`, `level_completed`, `badge_unlocked` events — the names
  the Personal Analysis tab and the design doc already assume.

## 6. Store accounts (unchanged from the design doc)

- Google Play Developer: $25 one-time, ID verification, and the 12-tester /
  14-day closed test for new personal accounts.
- Apple Developer Program: $99/year, build + submit from a Mac with Xcode.
