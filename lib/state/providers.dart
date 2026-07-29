import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/certification_repository.dart';
import '../data/content_repository.dart';
import '../data/leaderboard.dart';
import '../data/models/certification.dart';
import '../data/models/course.dart';
import '../data/models/player.dart';
import '../data/models/progress.dart';
import '../gamification/badges.dart';
import '../gamification/reminder_service.dart';
import '../gamification/xp_rules.dart';

// ---------------------------------------------------------------------------
// Bootstrap
// ---------------------------------------------------------------------------

/// Overridden in main() with the real instance before the app starts.
final prefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Overridden in main()'),
);

/// True when Firebase.initializeApp succeeded (web today; Android/iOS after
/// they're registered in the console). When false the app runs fully local.
final firebaseReadyProvider = Provider<bool>((ref) => false);

final contentRepositoryProvider =
    Provider<ContentRepository>((ref) => const AssetContentRepository());

final coursesProvider = FutureProvider<List<Course>>(
  (ref) => ref.watch(contentRepositoryProvider).loadCourses(),
);

final certificationRepositoryProvider = Provider<CertificationRepository>(
    (ref) => const AssetCertificationRepository());

final certificationsProvider = FutureProvider<List<Certification>>(
  (ref) => ref.watch(certificationRepositoryProvider).loadCertifications(),
);

// ---------------------------------------------------------------------------
// Theme
// ---------------------------------------------------------------------------

class ThemeController extends Notifier<ThemeMode> {
  static const _key = 'aa.theme';

  @override
  ThemeMode build() {
    final stored = ref.read(prefsProvider).getString(_key);
    return ThemeMode.values.firstWhere(
      (m) => m.name == stored,
      orElse: () => ThemeMode.dark,
    );
  }

  void set(ThemeMode mode) {
    state = mode;
    ref.read(prefsProvider).setString(_key, mode.name);
  }
}

final themeProvider =
    NotifierProvider<ThemeController, ThemeMode>(ThemeController.new);

// ---------------------------------------------------------------------------
// Streak reminders
// ---------------------------------------------------------------------------

class RemindersController extends Notifier<bool> {
  static const _key = 'aa.reminders';

  @override
  bool build() => ref.read(prefsProvider).getBool(_key) ?? false;

  /// Turns daily reminders on/off. Returns null on success or a
  /// user-facing message when the change couldn't apply.
  Future<String?> setEnabled(bool on) async {
    if (!on) {
      await ReminderService.disable();
      state = false;
      await ref.read(prefsProvider).setBool(_key, false);
      return null;
    }
    if (kIsWeb) {
      return 'Reminders work in the Android app for now — '
          'browser notifications are coming later.';
    }
    final ok = await ReminderService.enable();
    if (!ok) {
      return 'Notification permission was denied — allow notifications for '
          'Anthropic Arena in your phone settings and try again.';
    }
    state = true;
    await ref.read(prefsProvider).setBool(_key, true);
    return null;
  }
}

final remindersProvider =
    NotifierProvider<RemindersController, bool>(RemindersController.new);

// ---------------------------------------------------------------------------
// Auth
// ---------------------------------------------------------------------------

/// Local-first auth. With Firebase available the same methods authenticate
/// against Firebase Auth and mirror a profile document to Firestore; without
/// it they create a device-local account. All methods return null on success
/// or a human-readable error message.
class AuthController extends Notifier<Player?> {
  static const _key = 'aa.player';

  @override
  Player? build() {
    final raw = ref.read(prefsProvider).getString(_key);
    if (raw == null) return null;
    return Player.fromJson((jsonDecode(raw) as Map).cast<String, dynamic>());
  }

  bool get _firebase => ref.read(firebaseReadyProvider);

  Player _store({
    required String id,
    required String name,
    required AuthProvider provider,
    String? email,
  }) {
    final player = Player(
      id: id,
      name: name,
      tag: '#${1000 + (id.hashCode.abs() % 9000)}',
      provider: provider,
      email: email,
      joinedIso: DateTime.now().toIso8601String(),
    );
    ref.read(prefsProvider).setString(_key, jsonEncode(player.toJson()));
    state = player;
    _mirrorProfile(player);
    return player;
  }

  Player _storeLocal({
    required String name,
    required AuthProvider provider,
    String? email,
  }) {
    final rng = Random(DateTime.now().microsecondsSinceEpoch);
    return _store(
      id: 'p${DateTime.now().millisecondsSinceEpoch}${rng.nextInt(999)}',
      name: name,
      provider: provider,
      email: email,
    );
  }

  /// Pushes the public profile to Firestore so the leaderboard can see it.
  /// Guests never sync: only signed-in players compete on the leaderboard.
  void _mirrorProfile(Player player) {
    if (!_firebase) return;
    if (player.provider == AuthProvider.guest) return;
    final progress = ref.read(progressProvider);
    unawaited(FirebaseFirestore.instance
        .collection('users')
        .doc(player.id)
        .set({
          'name': player.name,
          'tag': player.tag,
          'provider': player.provider.name,
          'xp': progress.xp,
          'streakDays': progress.streakDays,
          'levelsCompleted': progress.levelsCompleted,
          'badges': progress.badges.length,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true))
        .catchError((_) {}));
  }

  Future<String?> signInGuest() async {
    if (_firebase) {
      try {
        final cred = await fb.FirebaseAuth.instance.signInAnonymously();
        _store(id: cred.user!.uid, name: 'Player', provider: AuthProvider.guest);
        return null;
      } on fb.FirebaseAuthException catch (e) {
        return _friendly(e);
      }
    }
    _storeLocal(name: 'Player', provider: AuthProvider.guest);
    return null;
  }

  Future<String?> signInEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    if (_firebase) {
      final auth = fb.FirebaseAuth.instance;
      try {
        fb.UserCredential cred;
        try {
          cred = await auth.createUserWithEmailAndPassword(
              email: email, password: password);
        } on fb.FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            cred = await auth.signInWithEmailAndPassword(
                email: email, password: password);
          } else {
            rethrow;
          }
        }
        unawaited(cred.user?.updateDisplayName(name));
        _store(
            id: cred.user!.uid,
            name: name,
            provider: AuthProvider.email,
            email: email);
        return null;
      } on fb.FirebaseAuthException catch (e) {
        return _friendly(e);
      }
    }
    _storeLocal(name: name, provider: AuthProvider.email, email: email);
    return null;
  }

  /// Real Google popup on web; demo account elsewhere until those platforms
  /// are registered with Firebase.
  Future<String?> signInGoogle() async {
    if (_firebase && kIsWeb) {
      try {
        final cred = await fb.FirebaseAuth.instance
            .signInWithPopup(fb.GoogleAuthProvider());
        final user = cred.user!;
        _store(
          id: user.uid,
          name: user.displayName ?? 'Player',
          provider: AuthProvider.google,
          email: user.email,
        );
        return null;
      } on fb.FirebaseAuthException catch (e) {
        return _friendly(e);
      }
    }
    _storeLocal(name: 'Google Player', provider: AuthProvider.google);
    return null;
  }

  Future<String?> signInDemoApple() async {
    _storeLocal(name: 'Apple Player', provider: AuthProvider.apple);
    return null;
  }

  void rename(String name) {
    final current = state;
    if (current == null) return;
    final updated = current.copyWith(name: name);
    ref.read(prefsProvider).setString(_key, jsonEncode(updated.toJson()));
    state = updated;
    _mirrorProfile(updated);
  }

  /// Called by ProgressController after every attempt so the leaderboard
  /// stays current.
  void syncProgress() {
    final current = state;
    if (current != null) _mirrorProfile(current);
  }

  Future<void> signOut() async {
    if (_firebase) {
      try {
        await fb.FirebaseAuth.instance.signOut();
      } catch (_) {}
    }
    ref.read(prefsProvider).remove(_key);
    state = null;
  }

  static String _friendly(fb.FirebaseAuthException e) => switch (e.code) {
        'invalid-credential' ||
        'wrong-password' =>
          'Wrong password for that email. Try again.',
        'invalid-email' => 'That email address doesn\'t look right.',
        'weak-password' => 'Password too weak — use at least 6 characters.',
        'user-disabled' => 'This account has been disabled.',
        'popup-closed-by-user' => 'Sign-in window was closed. Try again.',
        'operation-not-allowed' =>
          'This sign-in method isn\'t enabled in Firebase yet.',
        'network-request-failed' => 'No connection — check your internet.',
        _ => 'Sign-in failed (${e.code}). Please try again.',
      };
}

final authProvider = NotifierProvider<AuthController, Player?>(
  AuthController.new,
);

// ---------------------------------------------------------------------------
// Progress (the game engine)
// ---------------------------------------------------------------------------

/// Everything the result screen needs to celebrate a finished level.
class AttemptOutcome {
  const AttemptOutcome({
    required this.scorePct,
    required this.correct,
    required this.total,
    required this.stars,
    required this.xpEarned,
    required this.passed,
    required this.newBadges,
    required this.streakDays,
    required this.streakExtended,
  });

  final int scorePct;
  final int correct;
  final int total;
  final int stars;
  final int xpEarned;
  final bool passed;
  final List<BadgeSpec> newBadges;
  final int streakDays;
  final bool streakExtended;
}

class ProgressController extends Notifier<UserProgress> {
  static const _key = 'aa.progress';

  /// Attempt history kept for analysis (bounds local storage).
  static const _maxAttempts = 200;

  @override
  UserProgress build() {
    final raw = ref.read(prefsProvider).getString(_key);
    if (raw == null) return const UserProgress();
    return UserProgress.fromJson(
        (jsonDecode(raw) as Map).cast<String, dynamic>());
  }

  static String dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  AttemptOutcome recordAttempt({
    required Course course,
    required Level level,
    required Map<String, int?> answers,
    required List<Course> allCourses,
    DateTime? now,
  }) {
    final when = now ?? DateTime.now();
    final total = level.questions.length;
    var correct = 0;
    final topicCorrect = <String, int>{};
    final topicTotal = <String, int>{};

    for (final q in level.questions) {
      final topic = q.topic.isEmpty ? level.topic : q.topic;
      topicTotal[topic] = (topicTotal[topic] ?? 0) + 1;
      if (answers[q.id] == q.correctIndex) {
        correct++;
        topicCorrect[topic] = (topicCorrect[topic] ?? 0) + 1;
      }
    }

    final scorePct = total == 0 ? 0 : (correct * 100 / total).round();
    final passed = scorePct >= level.passMark;
    final stars = XpRules.starsFor(scorePct, level.passMark);
    final xp = XpRules.xpFor(level: level, correct: correct, scorePct: scorePct);

    // Streak: one or more finished levels per calendar day keeps it alive.
    final today = dayKey(when);
    final yesterday = dayKey(when.subtract(const Duration(days: 1)));
    int streak;
    var streakExtended = false;
    if (state.lastPlayDay == today) {
      streak = state.streakDays == 0 ? 1 : state.streakDays;
    } else if (state.lastPlayDay == yesterday) {
      streak = state.streakDays + 1;
      streakExtended = true;
    } else {
      streak = 1;
      streakExtended = state.lastPlayDay.isNotEmpty || state.streakDays == 0;
    }

    final existing = state.progressFor(level.id);
    final updatedLevel = existing.copyWith(
      attempts: existing.attempts + 1,
      bestScorePct: max(existing.bestScorePct, scorePct),
      stars: max(existing.stars, stars),
      passed: existing.passed || passed,
    );

    final attempt = AttemptRecord(
      levelId: level.id,
      courseId: course.id,
      dateIso: when.toIso8601String(),
      scorePct: scorePct,
      correct: correct,
      total: total,
      xpEarned: xp,
      passed: passed,
      topicCorrect: topicCorrect,
      topicTotal: topicTotal,
    );

    final xpByDay = Map<String, int>.from(state.xpByDay);
    xpByDay[today] = (xpByDay[today] ?? 0) + xp;
    // Keep the chart data bounded.
    if (xpByDay.length > 60) {
      final keys = xpByDay.keys.toList()..sort();
      for (final k in keys.take(xpByDay.length - 60)) {
        xpByDay.remove(k);
      }
    }

    final attempts = [...state.attempts, attempt];
    if (attempts.length > _maxAttempts) {
      attempts.removeRange(0, attempts.length - _maxAttempts);
    }

    var next = state.copyWith(
      xp: state.xp + xp,
      streakDays: streak,
      lastPlayDay: today,
      totalCorrect: state.totalCorrect + correct,
      totalAnswered: state.totalAnswered + total,
      levels: {...state.levels, level.id: updatedLevel},
      xpByDay: xpByDay,
      attempts: attempts,
    );

    final newBadges = Badges.newlyEarned(next, allCourses);
    if (newBadges.isNotEmpty) {
      next = next.copyWith(
        badges: {...next.badges, ...newBadges.map((b) => b.id)},
      );
    }

    state = next;
    _persist();
    // Keep the global leaderboard in sync (no-op without Firebase).
    ref.read(authProvider.notifier).syncProgress();

    return AttemptOutcome(
      scorePct: scorePct,
      correct: correct,
      total: total,
      stars: stars,
      xpEarned: xp,
      passed: passed,
      newBadges: newBadges,
      streakDays: streak,
      streakExtended: streakExtended,
    );
  }

  /// Number of stored cert attempts kept (bounds local storage).
  static const _maxCertAttempts = 100;

  /// Scores a finished certification exam, stores it for analytics and
  /// returns the resulting attempt. [questions] are the scored questions that
  /// were actually presented; unscored questions must not be passed in.
  CertAttempt recordCertAttempt({
    required Certification cert,
    required List<CertQuestion> questions,
    required Map<String, Set<int>> answers,
    required int durationSeconds,
    ExamSet? set,
    bool autoSubmitted = false,
    DateTime? now,
  }) {
    final when = now ?? DateTime.now();
    final total = questions.length;
    var correct = 0;
    final topicCorrect = <String, int>{};
    final topicTotal = <String, int>{};

    for (final q in questions) {
      final topic = q.topic.isEmpty ? cert.name : q.topic;
      topicTotal[topic] = (topicTotal[topic] ?? 0) + 1;
      if (q.isCorrect(answers[q.id] ?? const <int>{})) {
        correct++;
        topicCorrect[topic] = (topicCorrect[topic] ?? 0) + 1;
      }
    }

    final scorePct = total == 0 ? 0 : (correct * 100 / total).round();
    final attempt = CertAttempt(
      certId: cert.id,
      certName: cert.name,
      setId: set?.id ?? '',
      setLabel: set?.label ?? '',
      dateIso: when.toIso8601String(),
      scorePct: scorePct,
      correct: correct,
      total: total,
      passMark: cert.passMark,
      passed: scorePct >= cert.passMark,
      durationSeconds: durationSeconds,
      autoSubmitted: autoSubmitted,
      topicCorrect: topicCorrect,
      topicTotal: topicTotal,
    );

    final certAttempts = [...state.certAttempts, attempt];
    if (certAttempts.length > _maxCertAttempts) {
      certAttempts.removeRange(0, certAttempts.length - _maxCertAttempts);
    }

    state = state.copyWith(certAttempts: certAttempts);
    _persist();
    return attempt;
  }

  /// Whether [level] of [course] is playable given current progress.
  bool isUnlocked(Course course, Level level) {
    final sorted = course.levels;
    final index = sorted.indexWhere((l) => l.id == level.id);
    if (index <= 0) return true;
    return state.progressFor(sorted[index - 1].id).passed;
  }

  void resetAll() {
    state = const UserProgress();
    ref.read(prefsProvider).remove(_key);
    ref.read(authProvider.notifier).syncProgress();
  }

  void _persist() =>
      ref.read(prefsProvider).setString(_key, jsonEncode(state.toJson()));
}

final progressProvider = NotifierProvider<ProgressController, UserProgress>(
  ProgressController.new,
);

// ---------------------------------------------------------------------------
// Leaderboard
// ---------------------------------------------------------------------------

/// Live Firestore standings: top 50 players by XP.
final _liveLeaderboardProvider = StreamProvider<List<LeaderboardEntry>>((ref) {
  final player = ref.watch(authProvider);
  return FirebaseFirestore.instance
      .collection('users')
      .orderBy('xp', descending: true)
      .limit(50)
      .snapshots()
      .map((snap) => [
            for (final doc in snap.docs)
              LeaderboardEntry(
                name: (doc.data()['name'] as String?) ?? 'Player',
                tag: (doc.data()['tag'] as String?) ?? '',
                xp: (doc.data()['xp'] as num?)?.toInt() ?? 0,
                isYou: doc.id == player?.id,
              ),
          ]);
});

/// What the Ranking tab shows: live standings when Firebase is on,
/// demo standings otherwise.
final leaderboardProvider = Provider<List<LeaderboardEntry>>((ref) {
  final player = ref.watch(authProvider);
  final progress = ref.watch(progressProvider);
  // Guests play but don't compete: rankings list signed-in players only.
  final competing = player != null && player.provider != AuthProvider.guest;

  if (ref.watch(firebaseReadyProvider)) {
    final live = ref.watch(_liveLeaderboardProvider).value ?? const [];
    // Make sure the local player is visible even before their first sync.
    if (competing && !live.any((e) => e.isYou)) {
      return [
        ...live,
        LeaderboardEntry(
            name: player.name, tag: player.tag, xp: progress.xp, isYou: true),
      ]..sort((a, b) => b.xp.compareTo(a.xp));
    }
    return live;
  }

  return [
    ...demoRivals,
    if (competing)
      LeaderboardEntry(
          name: player.name, tag: player.tag, xp: progress.xp, isYou: true),
  ]..sort((a, b) => b.xp.compareTo(a.xp));
});

/// True when the standings shown are the live global ones.
final leaderboardIsLiveProvider =
    Provider<bool>((ref) => ref.watch(firebaseReadyProvider));
