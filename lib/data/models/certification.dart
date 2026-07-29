import 'package:flutter/material.dart';

/// A single certification exam question. Supports both single-answer
/// (multiple-choice) and multiple-answer (multiple-select) questions —
/// [correctIndexes] holds one index for the former and several for the latter.
class CertQuestion {
  const CertQuestion({
    required this.id,
    required this.topic,
    required this.question,
    required this.options,
    required this.correctIndexes,
    this.explanation = '',
  });

  final String id;
  final String topic;
  final String question;
  final List<String> options;
  final List<int> correctIndexes;
  final String explanation;

  bool get isMultiSelect => correctIndexes.length > 1;

  /// True when [selected] matches the answer key exactly. Multi-select is
  /// all-or-nothing, as on the real exams.
  bool isCorrect(Set<int> selected) =>
      selected.length == correctIndexes.length &&
      selected.containsAll(correctIndexes);

  factory CertQuestion.fromJson(Map<String, dynamic> json) => CertQuestion(
        id: json['id'] as String,
        topic: json['topic'] as String? ?? '',
        question: json['question'] as String,
        options: (json['options'] as List).cast<String>(),
        correctIndexes:
            (json['correctIndexes'] as List).map((e) => e as int).toList(),
        explanation: json['explanation'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'topic': topic,
        'question': question,
        'options': options,
        'correctIndexes': correctIndexes,
        'explanation': explanation,
      };
}

/// One named, dated question bank belonging to a certification. A cert can
/// have several — e.g. "Latest exam pattern — Jan 2026" — and each attempt
/// draws a random subset from the chosen set's pool.
class ExamSet {
  const ExamSet({
    required this.id,
    required this.label,
    this.dateIso = '',
    required this.questions,
  });

  final String id;
  final String label;

  /// yyyy-MM-dd the set was added/authored (optional; used for display + sort).
  final String dateIso;
  final List<CertQuestion> questions;

  factory ExamSet.fromJson(Map<String, dynamic> json) => ExamSet(
        id: json['id'] as String,
        label: json['label'] as String? ?? 'Practice set',
        dateIso: json['dateIso'] as String? ?? '',
        questions: ((json['questions'] as List?) ?? const [])
            .map((q) => CertQuestion.fromJson((q as Map).cast<String, dynamic>()))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'dateIso': dateIso,
        'questions': questions.map((q) => q.toJson()).toList(),
      };
}

/// A certification track (e.g. Administrator, Platform Developer I). Carries
/// the official exam parameters shown to the user plus one or more question
/// banks ([sets]) the app draws each exam from.
class Certification {
  const Certification({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.category,
    required this.order,
    required this.color,
    required this.passMark,
    required this.timeLimitMinutes,
    required this.scoredCount,
    required this.unscoredCount,
    required this.sets,
    this.note = '',
    this.retired = false,
  });

  final String id;
  final String name;
  final String tagline;
  final String description;

  /// Grouping shown as a section header in the Certifications tab.
  final String category;
  final int order;
  final Color color;

  /// Optional caveat shown on the card/sheet (prerequisites, superbadge
  /// requirements, "verify score", etc.).
  final String note;

  /// True for credentials Salesforce has retired — shown but not takeable.
  final bool retired;

  /// Passing score (percentage) for this credential.
  final int passMark;

  /// Official time allowance in minutes.
  final int timeLimitMinutes;

  /// Number of scored questions on the official exam (typically 60).
  final int scoredCount;

  /// Number of unscored questions on the official exam (up to 5).
  final int unscoredCount;

  final List<ExamSet> sets;

  /// All questions across every set (used for content validation).
  List<CertQuestion> get questions => [for (final s in sets) ...s.questions];

  /// Sets that actually have questions (the ones a user can sit).
  List<ExamSet> get playableSets =>
      sets.where((s) => s.questions.isNotEmpty).toList();

  /// Whether an exam can be taken right now (has a non-empty set and is not
  /// retired).
  bool get isPlayable => !retired && playableSets.isNotEmpty;

  /// How many scored questions an exam drawn from [set] will present — the
  /// official [scoredCount], capped by how many questions the set holds.
  int scoredCountFor(ExamSet set) =>
      set.questions.length < scoredCount ? set.questions.length : scoredCount;

  factory Certification.fromJson(Map<String, dynamic> json) => Certification(
        id: json['id'] as String,
        name: json['name'] as String,
        tagline: json['tagline'] as String? ?? '',
        description: json['description'] as String? ?? '',
        category: json['category'] as String? ?? 'Other',
        order: json['order'] as int? ?? 1,
        color: _parseColor(json['color'] as String?),
        passMark: json['passMark'] as int? ?? 65,
        timeLimitMinutes: json['timeLimitMinutes'] as int? ?? 105,
        scoredCount: json['scoredCount'] as int? ?? 60,
        unscoredCount: json['unscoredCount'] as int? ?? 5,
        note: json['note'] as String? ?? '',
        retired: json['retired'] as bool? ?? false,
        sets: _parseSets(json),
      );

  /// Accepts either the multi-set shape (`"sets": [...]`) or a legacy flat
  /// `"questions": [...]` list (wrapped into a single default set).
  static List<ExamSet> _parseSets(Map<String, dynamic> json) {
    if (json['sets'] is List) {
      return (json['sets'] as List)
          .map((s) => ExamSet.fromJson((s as Map).cast<String, dynamic>()))
          .toList();
    }
    final qs = ((json['questions'] as List?) ?? const [])
        .map((q) => CertQuestion.fromJson((q as Map).cast<String, dynamic>()))
        .toList();
    if (qs.isEmpty) return const [];
    return [
      ExamSet(id: '${json['id']}-set-1', label: 'Practice set', questions: qs),
    ];
  }

  static Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF00A1E0);
    final cleaned = hex.replaceFirst('#', '');
    final value = int.tryParse(cleaned, radix: 16) ?? 0x00A1E0;
    return Color(cleaned.length == 8 ? value : 0xFF000000 | value);
  }
}
