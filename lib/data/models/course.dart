import 'package:flutter/material.dart';

/// A "learn more" link attached to a question (Learning Assistance).
class QuestionResource {
  const QuestionResource({required this.title, required this.url});

  final String title;
  final String url;

  factory QuestionResource.fromJson(Map<String, dynamic> json) =>
      QuestionResource(
        title: json['title'] as String? ?? 'Learn more',
        url: json['url'] as String,
      );

  Map<String, dynamic> toJson() => {'title': title, 'url': url};
}

class Question {
  const Question({
    required this.id,
    required this.topic,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.resource,
  });

  final String id;
  final String topic;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final QuestionResource? resource;

  factory Question.fromJson(Map<String, dynamic> json) => Question(
        id: json['id'] as String,
        topic: json['topic'] as String? ?? '',
        question: json['question'] as String,
        options: (json['options'] as List).cast<String>(),
        correctIndex: json['correctIndex'] as int,
        explanation: json['explanation'] as String? ?? '',
        resource: json['resource'] == null
            ? null
            : QuestionResource.fromJson(
                (json['resource'] as Map).cast<String, dynamic>()),
      );
}

class Level {
  const Level({
    required this.id,
    required this.title,
    required this.order,
    required this.topic,
    required this.passMark,
    required this.xpPerCorrect,
    required this.questions,
  });

  final String id;
  final String title;
  final int order;
  final String topic;

  /// Percentage (0-100) required to pass and unlock the next level.
  final int passMark;
  final int xpPerCorrect;
  final List<Question> questions;

  factory Level.fromJson(Map<String, dynamic> json) => Level(
        id: json['id'] as String,
        title: json['title'] as String,
        order: json['order'] as int? ?? 1,
        topic: json['topic'] as String? ?? '',
        passMark: json['passMark'] as int? ?? 70,
        xpPerCorrect: json['xpPerCorrect'] as int? ?? 10,
        questions: (json['questions'] as List)
            .map((q) => Question.fromJson((q as Map).cast<String, dynamic>()))
            .toList(),
      );
}

class Course {
  const Course({
    required this.id,
    required this.title,
    required this.tagline,
    required this.description,
    required this.order,
    required this.color,
    required this.levels,
  });

  final String id;
  final String title;
  final String tagline;
  final String description;
  final int order;
  final Color color;
  final List<Level> levels;

  factory Course.fromJson(Map<String, dynamic> json) => Course(
        id: json['id'] as String,
        title: json['title'] as String,
        tagline: json['tagline'] as String? ?? '',
        description: json['description'] as String? ?? '',
        order: json['order'] as int? ?? 1,
        color: _parseColor(json['color'] as String?),
        levels: ((json['levels'] as List?) ?? const [])
            .map((l) => Level.fromJson((l as Map).cast<String, dynamic>()))
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order)),
      );

  static Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFFF5A623);
    final cleaned = hex.replaceFirst('#', '');
    final value = int.tryParse(cleaned, radix: 16) ?? 0xF5A623;
    return Color(cleaned.length == 8 ? value : 0xFF000000 | value);
  }
}
