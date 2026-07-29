import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/glass.dart';
import '../../data/models/certification.dart';
import '../../data/models/progress.dart';
import 'cert_exam_screen.dart';

class CertResultScreen extends StatelessWidget {
  const CertResultScreen({
    super.key,
    required this.certification,
    required this.examSet,
    required this.questions,
    required this.answers,
    required this.attempt,
  });

  final Certification certification;
  final ExamSet examSet;
  final List<CertQuestion> questions;
  final Map<String, Set<int>> answers;
  final CertAttempt attempt;

  String _fmtDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final passed = attempt.passed;
    final statusColor = passed ? AppColors.success : AppColors.danger;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('${certification.name} · Result'),
      ),
      body: NeonBackground(
        accent: certification.color,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              GlassSurface(
                glow: statusColor,
                glowAlpha: 0.35,
                padding:
                    const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
                child: Column(
                  children: [
                    Icon(
                      passed
                          ? Icons.workspace_premium_rounded
                          : Icons.refresh_rounded,
                      color: statusColor,
                      size: 52,
                    ),
                    const SizedBox(height: 10),
                    Text('${attempt.scorePct}%',
                        style: textTheme.displayMedium
                            ?.copyWith(color: statusColor)),
                    const SizedBox(height: 4),
                    Text(
                      passed ? 'Passed' : 'Not passed',
                      style:
                          textTheme.headlineSmall?.copyWith(color: statusColor),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pass mark for this credential is ${attempt.passMark}%.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    if (examSet.label.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      StatChip(
                        icon: Icons.style_outlined,
                        label: examSet.label,
                        color: certification.color,
                      ),
                    ],
                    if (attempt.autoSubmitted) ...[
                      const SizedBox(height: 10),
                      StatChip(
                        icon: Icons.timer_off_outlined,
                        label: 'Auto-submitted (time up)',
                        color: AppColors.danger,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      icon: Icons.check_circle_outline_rounded,
                      color: certification.color,
                      value: '${attempt.correct}/${attempt.total}',
                      label: 'Correct',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniStat(
                      icon: Icons.timer_outlined,
                      color: AppColors.info,
                      value: _fmtDuration(attempt.durationSeconds),
                      label: 'Time used',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const SectionTitle('Performance by topic'),
              const SizedBox(height: 12),
              ..._topicBars(context),
              const SizedBox(height: 24),
              const SectionTitle('Review answers'),
              const SizedBox(height: 12),
              for (var i = 0; i < questions.length; i++) ...[
                _ReviewTile(
                  number: i + 1,
                  question: questions[i],
                  selected: answers[questions[i].id] ?? const <int>{},
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.grid_view_rounded),
                      label: const Text('Certifications'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retake'),
                      style: FilledButton.styleFrom(
                        backgroundColor: certification.color,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => CertExamScreen(
                            certification: certification,
                            examSet: examSet,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _topicBars(BuildContext context) {
    final topics = attempt.topicTotal.keys.toList()..sort();
    return [
      for (final t in topics) ...[
        Builder(builder: (context) {
          final total = attempt.topicTotal[t] ?? 0;
          final correct = attempt.topicCorrect[t] ?? 0;
          final pct = total == 0 ? 0 : (correct * 100 / total).round();
          final color = pct >= 70
              ? AppColors.success
              : pct >= 50
                  ? AppColors.gold
                  : AppColors.danger;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ArenaCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(t,
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                      Text('$correct/$total · $pct%',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(color: color)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ArenaProgressBar(value: pct / 100, color: color),
                ],
              ),
            ),
          );
        }),
      ],
    ];
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ArenaCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
                Text(label, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({
    required this.number,
    required this.question,
    required this.selected,
  });

  final int number;
  final CertQuestion question;
  final Set<int> selected;

  String _letters(Iterable<int> idx) {
    final sorted = idx.toList()..sort();
    if (sorted.isEmpty) return '—';
    return sorted.map((i) => String.fromCharCode(65 + i)).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final correct = question.isCorrect(selected);
    final color = correct ? AppColors.success : AppColors.danger;
    final textTheme = Theme.of(context).textTheme;

    return ArenaCard(
      borderColor: color.withValues(alpha: 0.5),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text('$number. ${question.question}',
                    style: textTheme.titleSmall),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < question.options.length; i++)
            _OptionRow(
              letter: String.fromCharCode(65 + i),
              text: question.options[i],
              isCorrect: question.correctIndexes.contains(i),
              isSelected: selected.contains(i),
            ),
          if (question.explanation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Your answer: ${_letters(selected)}   ·   '
              'Correct: ${_letters(question.correctIndexes)}',
              style: textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            Text(question.explanation,
                style: textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.letter,
    required this.text,
    required this.isCorrect,
    required this.isSelected,
  });

  final String letter;
  final String text;
  final bool isCorrect;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Correct answers are highlighted green; a wrong pick is highlighted red.
    final Color? tint =
        isCorrect ? AppColors.success : (isSelected ? AppColors.danger : null);
    final IconData icon = isCorrect
        ? Icons.check_rounded
        : (isSelected ? Icons.close_rounded : Icons.circle_outlined);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: tint ?? scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$letter. $text',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: tint ?? scheme.onSurface,
                    fontWeight: (isCorrect || isSelected)
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
