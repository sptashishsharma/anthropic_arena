/// Per-level best results.
class LevelProgress {
  const LevelProgress({
    required this.levelId,
    this.bestScorePct = 0,
    this.stars = 0,
    this.passed = false,
    this.attempts = 0,
  });

  final String levelId;
  final int bestScorePct;
  final int stars;
  final bool passed;
  final int attempts;

  LevelProgress copyWith({
    int? bestScorePct,
    int? stars,
    bool? passed,
    int? attempts,
  }) =>
      LevelProgress(
        levelId: levelId,
        bestScorePct: bestScorePct ?? this.bestScorePct,
        stars: stars ?? this.stars,
        passed: passed ?? this.passed,
        attempts: attempts ?? this.attempts,
      );

  factory LevelProgress.fromJson(Map<String, dynamic> json) => LevelProgress(
        levelId: json['levelId'] as String,
        bestScorePct: json['bestScorePct'] as int? ?? 0,
        stars: json['stars'] as int? ?? 0,
        passed: json['passed'] as bool? ?? false,
        attempts: json['attempts'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'levelId': levelId,
        'bestScorePct': bestScorePct,
        'stars': stars,
        'passed': passed,
        'attempts': attempts,
      };
}

/// One finished quiz run — the raw material for Personal Analysis.
class AttemptRecord {
  const AttemptRecord({
    required this.levelId,
    required this.courseId,
    required this.dateIso,
    required this.scorePct,
    required this.correct,
    required this.total,
    required this.xpEarned,
    required this.passed,
    required this.topicCorrect,
    required this.topicTotal,
  });

  final String levelId;
  final String courseId;
  final String dateIso; // full ISO timestamp
  final int scorePct;
  final int correct;
  final int total;
  final int xpEarned;
  final bool passed;

  /// topic -> correctly answered count in this attempt
  final Map<String, int> topicCorrect;

  /// topic -> questions seen in this attempt
  final Map<String, int> topicTotal;

  factory AttemptRecord.fromJson(Map<String, dynamic> json) => AttemptRecord(
        levelId: json['levelId'] as String,
        courseId: json['courseId'] as String,
        dateIso: json['dateIso'] as String,
        scorePct: json['scorePct'] as int,
        correct: json['correct'] as int,
        total: json['total'] as int,
        xpEarned: json['xpEarned'] as int,
        passed: json['passed'] as bool,
        topicCorrect:
            ((json['topicCorrect'] as Map?) ?? const {}).cast<String, int>(),
        topicTotal:
            ((json['topicTotal'] as Map?) ?? const {}).cast<String, int>(),
      );

  Map<String, dynamic> toJson() => {
        'levelId': levelId,
        'courseId': courseId,
        'dateIso': dateIso,
        'scorePct': scorePct,
        'correct': correct,
        'total': total,
        'xpEarned': xpEarned,
        'passed': passed,
        'topicCorrect': topicCorrect,
        'topicTotal': topicTotal,
      };
}

/// One finished certification exam — the raw material for the Certification
/// section of Personal Analysis.
class CertAttempt {
  const CertAttempt({
    required this.certId,
    required this.certName,
    required this.dateIso,
    required this.scorePct,
    required this.correct,
    required this.total,
    required this.passMark,
    required this.passed,
    required this.durationSeconds,
    required this.autoSubmitted,
    required this.topicCorrect,
    required this.topicTotal,
    this.setId = '',
    this.setLabel = '',
  });

  final String certId;
  final String certName;

  /// The exam set this attempt was drawn from (empty for legacy attempts).
  final String setId;
  final String setLabel;
  final String dateIso; // full ISO timestamp
  final int scorePct;
  final int correct;
  final int total;
  final int passMark;
  final bool passed;

  /// Seconds spent on the exam (elapsed of the allotted time).
  final int durationSeconds;

  /// True when the timer ran out and the exam submitted itself.
  final bool autoSubmitted;

  final Map<String, int> topicCorrect;
  final Map<String, int> topicTotal;

  factory CertAttempt.fromJson(Map<String, dynamic> json) => CertAttempt(
        certId: json['certId'] as String,
        certName: json['certName'] as String? ?? '',
        setId: json['setId'] as String? ?? '',
        setLabel: json['setLabel'] as String? ?? '',
        dateIso: json['dateIso'] as String,
        scorePct: json['scorePct'] as int,
        correct: json['correct'] as int,
        total: json['total'] as int,
        passMark: json['passMark'] as int? ?? 65,
        passed: json['passed'] as bool? ?? false,
        durationSeconds: json['durationSeconds'] as int? ?? 0,
        autoSubmitted: json['autoSubmitted'] as bool? ?? false,
        topicCorrect:
            ((json['topicCorrect'] as Map?) ?? const {}).cast<String, int>(),
        topicTotal:
            ((json['topicTotal'] as Map?) ?? const {}).cast<String, int>(),
      );

  Map<String, dynamic> toJson() => {
        'certId': certId,
        'certName': certName,
        'setId': setId,
        'setLabel': setLabel,
        'dateIso': dateIso,
        'scorePct': scorePct,
        'correct': correct,
        'total': total,
        'passMark': passMark,
        'passed': passed,
        'durationSeconds': durationSeconds,
        'autoSubmitted': autoSubmitted,
        'topicCorrect': topicCorrect,
        'topicTotal': topicTotal,
      };
}

/// Everything the player has earned, stored locally (and later synced to
/// Firestore).
class UserProgress {
  const UserProgress({
    this.xp = 0,
    this.streakDays = 0,
    this.lastPlayDay = '',
    this.totalCorrect = 0,
    this.totalAnswered = 0,
    this.levels = const {},
    this.badges = const {},
    this.xpByDay = const {},
    this.attempts = const [],
    this.certAttempts = const [],
  });

  final int xp;
  final int streakDays;

  /// yyyy-MM-dd of the most recent day a level was completed.
  final String lastPlayDay;
  final int totalCorrect;
  final int totalAnswered;
  final Map<String, LevelProgress> levels;
  final Set<String> badges;

  /// yyyy-MM-dd -> XP earned that day (kept for the analysis chart).
  final Map<String, int> xpByDay;
  final List<AttemptRecord> attempts;

  /// Finished certification exams, oldest first.
  final List<CertAttempt> certAttempts;

  int get levelsCompleted => levels.values.where((l) => l.passed).length;

  int get accuracyPct =>
      totalAnswered == 0 ? 0 : (totalCorrect * 100 / totalAnswered).round();

  LevelProgress progressFor(String levelId) =>
      levels[levelId] ?? LevelProgress(levelId: levelId);

  /// All exam attempts for one certification, most recent last.
  List<CertAttempt> certAttemptsFor(String certId) =>
      certAttempts.where((a) => a.certId == certId).toList();

  /// The highest-scoring attempt for a certification, or null if never taken.
  CertAttempt? bestCertAttempt(String certId) {
    CertAttempt? best;
    for (final a in certAttempts) {
      if (a.certId != certId) continue;
      if (best == null || a.scorePct > best.scorePct) best = a;
    }
    return best;
  }

  UserProgress copyWith({
    int? xp,
    int? streakDays,
    String? lastPlayDay,
    int? totalCorrect,
    int? totalAnswered,
    Map<String, LevelProgress>? levels,
    Set<String>? badges,
    Map<String, int>? xpByDay,
    List<AttemptRecord>? attempts,
    List<CertAttempt>? certAttempts,
  }) =>
      UserProgress(
        xp: xp ?? this.xp,
        streakDays: streakDays ?? this.streakDays,
        lastPlayDay: lastPlayDay ?? this.lastPlayDay,
        totalCorrect: totalCorrect ?? this.totalCorrect,
        totalAnswered: totalAnswered ?? this.totalAnswered,
        levels: levels ?? this.levels,
        badges: badges ?? this.badges,
        xpByDay: xpByDay ?? this.xpByDay,
        attempts: attempts ?? this.attempts,
        certAttempts: certAttempts ?? this.certAttempts,
      );

  factory UserProgress.fromJson(Map<String, dynamic> json) => UserProgress(
        xp: json['xp'] as int? ?? 0,
        streakDays: json['streakDays'] as int? ?? 0,
        lastPlayDay: json['lastPlayDay'] as String? ?? '',
        totalCorrect: json['totalCorrect'] as int? ?? 0,
        totalAnswered: json['totalAnswered'] as int? ?? 0,
        levels: ((json['levels'] as Map?) ?? const {}).map((k, v) => MapEntry(
            k as String,
            LevelProgress.fromJson((v as Map).cast<String, dynamic>()))),
        badges: ((json['badges'] as List?) ?? const []).cast<String>().toSet(),
        xpByDay: ((json['xpByDay'] as Map?) ?? const {}).cast<String, int>(),
        attempts: ((json['attempts'] as List?) ?? const [])
            .map((a) =>
                AttemptRecord.fromJson((a as Map).cast<String, dynamic>()))
            .toList(),
        certAttempts: ((json['certAttempts'] as List?) ?? const [])
            .map((a) =>
                CertAttempt.fromJson((a as Map).cast<String, dynamic>()))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'xp': xp,
        'streakDays': streakDays,
        'lastPlayDay': lastPlayDay,
        'totalCorrect': totalCorrect,
        'totalAnswered': totalAnswered,
        'levels': levels.map((k, v) => MapEntry(k, v.toJson())),
        'badges': badges.toList(),
        'xpByDay': xpByDay,
        'attempts': attempts.map((a) => a.toJson()).toList(),
        'certAttempts': certAttempts.map((a) => a.toJson()).toList(),
      };
}
