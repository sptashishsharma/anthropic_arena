import 'dart:convert';
import 'dart:io';

import 'package:anthropic_arena/data/models/certification.dart';
import 'package:anthropic_arena/state/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> makeContainer() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [prefsProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}

/// A tiny certification with one single-answer and one multi-select question.
final _cert = Certification(
  id: 'test-cert',
  name: 'Test Cert',
  tagline: '',
  description: '',
  category: 'Test',
  order: 1,
  color: const Color(0xFF00A1E0),
  passMark: 70,
  timeLimitMinutes: 105,
  scoredCount: 60,
  unscoredCount: 5,
  sets: const [
    ExamSet(
      id: 'test-set',
      label: 'Set A',
      questions: [
        CertQuestion(
          id: 'q1',
          topic: 'Alpha',
          question: 'Single answer',
          options: ['a', 'b', 'c', 'd'],
          correctIndexes: [0],
        ),
        CertQuestion(
          id: 'q2',
          topic: 'Beta',
          question: 'Choose two',
          options: ['a', 'b', 'c', 'd'],
          correctIndexes: [1, 2],
        ),
      ],
    ),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('bundled certification content', () {
    late List<Certification> certs;

    setUpAll(() {
      final raw =
          File('assets/content/certifications.json').readAsStringSync();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      certs = (json['certifications'] as List)
          .map((c) => Certification.fromJson((c as Map).cast<String, dynamic>()))
          .toList();
    });

    test('catalog is present and every cert has a category', () {
      expect(certs, isNotEmpty);
      for (final c in certs) {
        expect(c.category.trim(), isNotEmpty, reason: 'Cert ${c.id}');
        expect(c.scoredCount, greaterThan(0), reason: 'Cert ${c.id}');
      }
      // At least the seeded tracks ship with a playable question bank.
      final playable = certs.where((c) => c.isPlayable).toList();
      expect(playable.length, greaterThanOrEqualTo(8),
          reason: 'Expected the seeded tracks to have question banks');
    });

    test('every question has options and valid correct indexes', () {
      for (final c in certs) {
        for (final q in c.questions) {
          expect(q.options.length, greaterThanOrEqualTo(2),
              reason: 'Question ${q.id}');
          expect(q.correctIndexes, isNotEmpty, reason: 'Question ${q.id}');
          for (final i in q.correctIndexes) {
            expect(i, inInclusiveRange(0, q.options.length - 1),
                reason: 'Question ${q.id}');
          }
          expect(q.correctIndexes.toSet().length, q.correctIndexes.length,
              reason: 'Duplicate correct index in ${q.id}');
          expect(q.question.trim(), isNotEmpty, reason: 'Question ${q.id}');
        }
      }
    });

    test('ids are unique and pass marks/time limits are sane', () {
      final certIds = <String>{};
      final questionIds = <String>{};
      for (final c in certs) {
        expect(certIds.add(c.id), isTrue, reason: 'Duplicate cert ${c.id}');
        expect(c.passMark, inInclusiveRange(1, 100), reason: 'Cert ${c.id}');
        expect(c.timeLimitMinutes, greaterThan(0), reason: 'Cert ${c.id}');
        for (final q in c.questions) {
          expect(questionIds.add(q.id), isTrue,
              reason: 'Duplicate question ${q.id}');
        }
      }
    });
  });

  group('cert scoring', () {
    test('multi-select is all-or-nothing and single-answer scores', () async {
      final container = await makeContainer();
      final controller = container.read(progressProvider.notifier);

      final attempt = controller.recordCertAttempt(
        cert: _cert,
        questions: _cert.questions,
        answers: {
          'q1': {0}, // correct
          'q2': {1}, // partial -> incorrect
        },
        durationSeconds: 42,
      );

      expect(attempt.total, 2);
      expect(attempt.correct, 1);
      expect(attempt.scorePct, 50);
      expect(attempt.passed, isFalse);
      expect(attempt.durationSeconds, 42);
      expect(attempt.topicCorrect['Alpha'], 1);
      expect(attempt.topicTotal['Beta'], 1);

      final stored = container.read(progressProvider).certAttemptsFor('test-cert');
      expect(stored, hasLength(1));
    });

    test('exact multi-select match counts as correct and passes', () async {
      final container = await makeContainer();
      final controller = container.read(progressProvider.notifier);

      final attempt = controller.recordCertAttempt(
        cert: _cert,
        set: _cert.sets.first,
        questions: _cert.questions,
        answers: {
          'q1': {0},
          'q2': {1, 2},
        },
        durationSeconds: 10,
        autoSubmitted: true,
      );

      expect(attempt.correct, 2);
      expect(attempt.scorePct, 100);
      expect(attempt.passed, isTrue);
      expect(attempt.autoSubmitted, isTrue);
      expect(attempt.setId, 'test-set');
      expect(attempt.setLabel, 'Set A');

      final best = container.read(progressProvider).bestCertAttempt('test-cert');
      expect(best?.scorePct, 100);
    });
  });
}
