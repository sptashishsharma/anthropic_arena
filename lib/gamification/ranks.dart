import 'package:flutter/material.dart';

/// A competitive tier earned purely with XP. Tiers give long-run progression
/// something the level map can't: a single identity number that keeps moving
/// after every course is finished.
class RankTier {
  const RankTier({
    required this.name,
    required this.minXp,
    required this.color,
    required this.icon,
  });

  final String name;
  final int minXp;
  final Color color;
  final IconData icon;
}

abstract final class Ranks {
  static const tiers = <RankTier>[
    RankTier(
        name: 'Recruit',
        minXp: 0,
        color: Color(0xFF9AA3B2),
        icon: Icons.shield_outlined),
    RankTier(
        name: 'Bronze',
        minXp: 250,
        color: Color(0xFFCD8A4B),
        icon: Icons.shield_rounded),
    RankTier(
        name: 'Silver',
        minXp: 750,
        color: Color(0xFFB9C0CC),
        icon: Icons.shield_rounded),
    RankTier(
        name: 'Gold',
        minXp: 1500,
        color: Color(0xFFF5A623),
        icon: Icons.workspace_premium_rounded),
    RankTier(
        name: 'Platinum',
        minXp: 3000,
        color: Color(0xFF4FC3F7),
        icon: Icons.military_tech_rounded),
    RankTier(
        name: 'Diamond',
        minXp: 5500,
        color: Color(0xFF8B7BF7),
        icon: Icons.diamond_rounded),
    RankTier(
        name: 'Legend',
        minXp: 9000,
        color: Color(0xFF3DC97C),
        icon: Icons.auto_awesome_rounded),
  ];

  static RankTier forXp(int xp) {
    var current = tiers.first;
    for (final t in tiers) {
      if (xp >= t.minXp) current = t;
    }
    return current;
  }

  /// The tier above [xp], or null once the top tier is reached.
  static RankTier? nextAfter(int xp) {
    for (final t in tiers) {
      if (t.minXp > xp) return t;
    }
    return null;
  }

  /// 0..1 progress through the current tier toward the next one.
  static double progress(int xp) {
    final current = forXp(xp);
    final next = nextAfter(xp);
    if (next == null) return 1;
    final span = next.minXp - current.minXp;
    if (span <= 0) return 1;
    return ((xp - current.minXp) / span).clamp(0.0, 1.0);
  }

  /// XP still needed for the next tier; 0 at the top.
  static int xpToNext(int xp) {
    final next = nextAfter(xp);
    return next == null ? 0 : next.minXp - xp;
  }
}
