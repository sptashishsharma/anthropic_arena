import 'package:anthropic_arena/data/models/course.dart';
import 'package:anthropic_arena/state/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Question q(String id, {String topic = 'General'}) => Question(
      id: id,
      topic: topic,
      question: 'Q $id',
      options: const ['a', 'b', 'c', 'd'],
      correctIndex: 0,
      explanation: '',
    );

final level1 = Level(
  id: 'l1',
  title: 'One',
  order: 1,
  topic: 'General',
  passMark: 70,
  xpPerCorrect: 10,
  questions: [q('q1'), q('q2'), q('q3', topic: 'Hard'), q('q4')],
);

final level2 = Level(
  id: 'l2',
  title: 'Two',
  order: 2,
  topic: 'General',
  passMark: 70,
  xpPerCorrect: 10,
  questions: [q('q5'), q('q6')],
);

final course = Course(
  id: 'c1',
  title: 'Course',
  tagline: '',
  description: '',
  order: 1,
  color: const Color(0xFFF5A623),
  levels: [level1, level2],
);

Future<ProviderContainer> makeContainer() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [prefsProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('perfect attempt scores, passes and unlocks the next level', () async {
    final container = await makeContainer();
    final controller = container.read(progressProvider.notifier);

    expect(controller.isUnlocked(course, level2), isFalse);

    final outcome = controller.recordAttempt(
      course: course,
      level: level1,
      answers: {'q1': 0, 'q2': 0, 'q3': 0, 'q4': 0},
      allCourses: [course],
    );

    expect(outcome.scorePct, 100);
    expect(outcome.passed, isTrue);
    expect(outcome.stars, 3);
    // 4 correct * 10 + pass 25 + perfect 50
    expect(outcome.xpEarned, 115);
    expect(controller.isUnlocked(course, level2), isTrue);

    final progress = container.read(progressProvider);
    expect(progress.xp, 115);
    expect(progress.levelsCompleted, 1);
    expect(progress.badges, contains('first-steps'));
    expect(progress.badges, contains('perfect-run'));
  });

  test('failed attempt keeps the next level locked', () async {
    final container = await makeContainer();
    final controller = container.read(progressProvider.notifier);

    final outcome = controller.recordAttempt(
      course: course,
      level: level1,
      answers: {'q1': 0, 'q2': 1, 'q3': null, 'q4': 2},
      allCourses: [course],
    );

    expect(outcome.scorePct, 25);
    expect(outcome.passed, isFalse);
    expect(outcome.stars, 0);
    expect(controller.isUnlocked(course, level2), isFalse);
  });

  test('streak counts consecutive days and resets after a gap', () async {
    final container = await makeContainer();
    final controller = container.read(progressProvider.notifier);
    const answers = {'q1': 0, 'q2': 0, 'q3': 0, 'q4': 0};

    final day1 = DateTime(2026, 7, 1, 10);
    controller.recordAttempt(
        course: course, level: level1, answers: answers,
        allCourses: [course], now: day1);
    expect(container.read(progressProvider).streakDays, 1);

    // Same day: unchanged.
    controller.recordAttempt(
        course: course, level: level1, answers: answers,
        allCourses: [course], now: day1.add(const Duration(hours: 2)));
    expect(container.read(progressProvider).streakDays, 1);

    // Next day: extends.
    controller.recordAttempt(
        course: course, level: level1, answers: answers,
        allCourses: [course], now: DateTime(2026, 7, 2, 9));
    expect(container.read(progressProvider).streakDays, 2);

    // Gap of two days: resets.
    controller.recordAttempt(
        course: course, level: level1, answers: answers,
        allCourses: [course], now: DateTime(2026, 7, 5, 9));
    expect(container.read(progressProvider).streakDays, 1);
  });

  test('progress persists across container restarts', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final first = ProviderContainer(
      overrides: [prefsProvider.overrideWithValue(prefs)],
    );
    first.read(progressProvider.notifier).recordAttempt(
      course: course,
      level: level1,
      answers: {'q1': 0, 'q2': 0, 'q3': 0, 'q4': 0},
      allCourses: [course],
    );
    final savedXp = first.read(progressProvider).xp;
    first.dispose();

    final second = ProviderContainer(
      overrides: [prefsProvider.overrideWithValue(prefs)],
    );
    addTearDown(second.dispose);
    expect(second.read(progressProvider).xp, savedXp);
    expect(second.read(progressProvider).levelsCompleted, 1);
  });

  test('course champion badge unlocks after passing every level', () async {
    final container = await makeContainer();
    final controller = container.read(progressProvider.notifier);

    controller.recordAttempt(
      course: course,
      level: level1,
      answers: {'q1': 0, 'q2': 0, 'q3': 0, 'q4': 0},
      allCourses: [course],
    );
    expect(container.read(progressProvider).badges,
        isNot(contains('course-champion')));

    controller.recordAttempt(
      course: course,
      level: level2,
      answers: {'q5': 0, 'q6': 0},
      allCourses: [course],
    );
    expect(container.read(progressProvider).badges,
        contains('course-champion'));
  });
}
