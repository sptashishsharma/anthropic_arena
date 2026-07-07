import 'package:anthropic_arena/data/models/course.dart';
import 'package:anthropic_arena/gamification/xp_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const level = Level(
    id: 'l1',
    title: 'Test',
    order: 1,
    topic: 'T',
    passMark: 70,
    xpPerCorrect: 10,
    questions: [],
  );

  group('XpRules.starsFor', () {
    test('0 stars below pass mark', () {
      expect(XpRules.starsFor(69, 70), 0);
      expect(XpRules.starsFor(0, 70), 0);
    });

    test('1 star at pass mark', () {
      expect(XpRules.starsFor(70, 70), 1);
      expect(XpRules.starsFor(84, 70), 1);
    });

    test('2 stars at 85+', () {
      expect(XpRules.starsFor(85, 70), 2);
      expect(XpRules.starsFor(99, 70), 2);
    });

    test('3 stars only for a perfect run', () {
      expect(XpRules.starsFor(100, 70), 3);
    });
  });

  group('XpRules.xpFor', () {
    test('base XP per correct answer', () {
      expect(
        XpRules.xpFor(level: level, correct: 3, scorePct: 60),
        30,
      );
    });

    test('pass bonus added at pass mark', () {
      expect(
        XpRules.xpFor(level: level, correct: 4, scorePct: 80),
        40 + XpRules.passBonus,
      );
    });

    test('perfect run earns pass + perfect bonuses', () {
      expect(
        XpRules.xpFor(level: level, correct: 5, scorePct: 100),
        50 + XpRules.passBonus + XpRules.perfectBonus,
      );
    });
  });
}
