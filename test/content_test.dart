import 'dart:convert';
import 'dart:io';

import 'package:anthropic_arena/data/models/course.dart';
import 'package:flutter_test/flutter_test.dart';

/// Validates the bundled course content so a bad row from the import
/// script can never ship silently.
void main() {
  late List<Course> courses;

  setUpAll(() {
    final raw = File('assets/content/courses.json').readAsStringSync();
    final json = jsonDecode(raw) as Map<String, dynamic>;
    courses = (json['courses'] as List)
        .map((c) => Course.fromJson((c as Map).cast<String, dynamic>()))
        .toList();
  });

  test('content contains at least one course with levels', () {
    expect(courses, isNotEmpty);
    for (final c in courses) {
      expect(c.levels, isNotEmpty, reason: 'Course ${c.id} has no levels');
    }
  });

  test('every question has 4 options and a valid correct index', () {
    for (final c in courses) {
      for (final l in c.levels) {
        expect(l.questions, isNotEmpty,
            reason: 'Level ${l.id} has no questions');
        for (final q in l.questions) {
          expect(q.options.length, 4, reason: 'Question ${q.id}');
          expect(q.correctIndex, inInclusiveRange(0, 3),
              reason: 'Question ${q.id}');
          expect(q.question.trim(), isNotEmpty, reason: 'Question ${q.id}');
        }
      }
    }
  });

  test('ids are unique across all content', () {
    final courseIds = <String>{};
    final levelIds = <String>{};
    final questionIds = <String>{};
    for (final c in courses) {
      expect(courseIds.add(c.id), isTrue, reason: 'Duplicate course ${c.id}');
      for (final l in c.levels) {
        expect(levelIds.add(l.id), isTrue, reason: 'Duplicate level ${l.id}');
        for (final q in l.questions) {
          expect(questionIds.add(q.id), isTrue,
              reason: 'Duplicate question ${q.id}');
        }
      }
    }
  });

  test('pass marks are sane percentages', () {
    for (final c in courses) {
      for (final l in c.levels) {
        expect(l.passMark, inInclusiveRange(1, 100), reason: 'Level ${l.id}');
      }
    }
  });
}
