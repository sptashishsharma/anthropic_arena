import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/content_repository.dart';
import '../data/leaderboard.dart';
import '../data/models/course.dart';
import '../data/models/player.dart';
import '../data/models/progress.dart';
import '../gamification/badges.dart';
import '../gamification/xp_rules.dart';

// ---------------------------------------------------------------------------
// Bootstrap
// ---------------------------------------------------------------------------

/// Overridden in main() with the real instance before the app starts.
final prefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Overridden in main()'),
);

final contentRepositoryProvider =
    Provider<ContentRepository>((ref) => const AssetContentRepository());

final coursesProvider = FutureProvider<List<Course>>(
  (ref) => ref.watch(contentRepositoryProvider).loadCourses(),
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
// Auth
// ---------------------------------------------------------------------------

class AuthController extends Notifier<Player?> {
  static const _key = 'aa.player';

  @override
  Player? build() {
    final raw = ref.read(prefsProvider).getString(_key);
    if (raw == null) return null;
    return Player.fromJson((jsonDecode(raw) as Map).cast<String, dynamic>());
  }

  Player _create({
    required String name,
    required AuthProvider provider,
    String? email,
  }) {
    final now = DateTime.now();
    final rng = Random(now.microsecondsSinceEpoch);
    final player = Player(
      id: 'p${now.millisecondsSinceEpoch}${rng.nextInt(999)}',
      name: name,
      tag: '#${(1000 + rng.nextInt(9000))}',
      provider: provider,
      email: email,
      joinedIso: now.toIso8601String(),
    );
    ref.read(prefsProvider).setString(_key, jsonEncode(player.toJson()));
    state = player;
    return player;
  }

  void signInGuest() => _create(name: 'Player', provider: AuthProvider.guest);

  void signInEmail({required String name, required String email}) =>
      _create(name: name, provider: AuthProvider.email, email: email);

  /// Demo sign-in for Google/Apple until Firebase Auth is connected.
  void signInDemoProvider(AuthProvider provider, {required String name}) =>
      _create(name: name, provider: provider);

  void rename(String name) {
    final current = state;
    if (current == null) return;
    final updated = current.copyWith(name: name);
    ref.read(prefsProvider).setString(_key, jsonEncode(updated.toJson()));
    state = updated;
  }

  void signOut() {
    ref.read(prefsProvider).remove(_key);
    state = null;
  }
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

final leaderboardProvider = Provider<List<LeaderboardEntry>>((ref) {
  final player = ref.watch(authProvider);
  final progress = ref.watch(progressProvider);
  final entries = [
    ...demoRivals,
    if (player != null)
      LeaderboardEntry(
        name: player.name,
        tag: player.tag,
        xp: progress.xp,
        isYou: true,
      ),
  ]..sort((a, b) => b.xp.compareTo(a.xp));
  return entries;
});
