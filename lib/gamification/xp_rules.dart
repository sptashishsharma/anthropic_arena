import '../data/models/course.dart';

/// All scoring/reward tuning lives here so game balance is one file away.
abstract final class XpRules {
  static const passBonus = 25;
  static const perfectBonus = 50;

  /// Stars awarded for a score, given the level's pass mark.
  static int starsFor(int scorePct, int passMark) {
    if (scorePct >= 100) return 3;
    if (scorePct >= 85) return 2;
    if (scorePct >= passMark) return 1;
    return 0;
  }

  static int xpFor({
    required Level level,
    required int correct,
    required int scorePct,
  }) {
    var xp = correct * level.xpPerCorrect;
    if (scorePct >= level.passMark) xp += passBonus;
    if (scorePct >= 100) xp += perfectBonus;
    return xp;
  }
}
