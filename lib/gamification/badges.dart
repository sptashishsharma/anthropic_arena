import 'package:flutter/material.dart';

import '../data/models/course.dart';
import '../data/models/progress.dart';

class BadgeSpec {
  const BadgeSpec({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.isEarned,
  });

  final String id;
  final String name;
  final String description;
  final IconData icon;

  /// Whether [progress] satisfies this badge (courses provided for
  /// course-completion checks).
  final bool Function(UserProgress progress, List<Course> courses) isEarned;
}

/// The full badge catalogue. Evaluated after every finished level.
abstract final class Badges {
  static final all = <BadgeSpec>[
    BadgeSpec(
      id: 'first-steps',
      name: 'First Steps',
      description: 'Complete your first level',
      icon: Icons.flag_rounded,
      isEarned: (p, _) => p.levelsCompleted >= 1,
    ),
    BadgeSpec(
      id: 'perfect-run',
      name: 'Perfect Run',
      description: 'Score 100% on any level',
      icon: Icons.workspace_premium_rounded,
      isEarned: (p, _) => p.levels.values.any((l) => l.bestScorePct >= 100),
    ),
    BadgeSpec(
      id: 'comeback',
      name: 'Comeback',
      description: 'Pass a level after failing it',
      icon: Icons.replay_circle_filled_rounded,
      isEarned: (p, _) =>
          p.levels.values.any((l) => l.passed && l.attempts >= 2),
    ),
    BadgeSpec(
      id: 'streak-3',
      name: 'On Fire',
      description: 'Reach a 3-day streak',
      icon: Icons.local_fire_department_rounded,
      isEarned: (p, _) => p.streakDays >= 3,
    ),
    BadgeSpec(
      id: 'streak-7',
      name: 'Unstoppable',
      description: 'Reach a 7-day streak',
      icon: Icons.bolt_rounded,
      isEarned: (p, _) => p.streakDays >= 7,
    ),
    BadgeSpec(
      id: 'xp-500',
      name: 'Rising Star',
      description: 'Earn 500 XP',
      icon: Icons.star_rounded,
      isEarned: (p, _) => p.xp >= 500,
    ),
    BadgeSpec(
      id: 'xp-1500',
      name: 'Arena Veteran',
      description: 'Earn 1,500 XP',
      icon: Icons.military_tech_rounded,
      isEarned: (p, _) => p.xp >= 1500,
    ),
    BadgeSpec(
      id: 'sharpshooter',
      name: 'Sharpshooter',
      description: 'Answer 50 questions correctly',
      icon: Icons.gps_fixed_rounded,
      isEarned: (p, _) => p.totalCorrect >= 50,
    ),
    BadgeSpec(
      id: 'course-champion',
      name: 'Course Champion',
      description: 'Pass every level of a course',
      icon: Icons.emoji_events_rounded,
      isEarned: (p, courses) => courses.any((c) =>
          c.levels.isNotEmpty &&
          c.levels.every((l) => p.progressFor(l.id).passed)),
    ),
    BadgeSpec(
      id: 'grand-champion',
      name: 'Grand Champion',
      description: 'Pass every level of every course',
      icon: Icons.shield_rounded,
      isEarned: (p, courses) =>
          courses.isNotEmpty &&
          courses.every((c) =>
              c.levels.every((l) => p.progressFor(l.id).passed)),
    ),
  ];

  static BadgeSpec? byId(String id) {
    for (final b in all) {
      if (b.id == id) return b;
    }
    return null;
  }

  /// Badges newly earned by [progress] that aren't in its unlocked set yet.
  static List<BadgeSpec> newlyEarned(
          UserProgress progress, List<Course> courses) =>
      all
          .where((b) =>
              !progress.badges.contains(b.id) && b.isEarned(progress, courses))
          .toList();
}
