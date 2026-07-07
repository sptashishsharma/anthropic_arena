import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/arena_video.dart';
import '../../core/widgets/common.dart';
import '../../data/models/course.dart';
import '../../gamification/xp_rules.dart';
import '../../state/providers.dart';
import 'quiz_screen.dart';

class LevelResultScreen extends StatefulWidget {
  const LevelResultScreen({
    super.key,
    required this.course,
    required this.level,
    required this.outcome,
    required this.questions,
    required this.answers,
  });

  final Course course;
  final Level level;
  final AttemptOutcome outcome;
  final List<Question> questions;
  final Map<String, int?> answers;

  @override
  State<LevelResultScreen> createState() => _LevelResultScreenState();
}

class _LevelResultScreenState extends State<LevelResultScreen> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    if (widget.outcome.passed) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _confetti.play());
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.outcome;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  children: [
                    if (o.passed) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: ArenaVideo(
                            asset: 'assets/videos/level_complete.mp4',
                            loop: true,
                            fit: BoxFit.cover,
                            fallback: Container(
                              color: AppColors.ink,
                              child: const Center(child: BrandMark(size: 90)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ] else
                      const SizedBox(height: 8),
                    Text(
                      o.passed ? 'Level complete!' : 'So close!',
                      textAlign: TextAlign.center,
                      style: textTheme.displaySmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      o.passed
                          ? 'You conquered ${widget.level.title}.'
                          : 'You need ${widget.level.passMark}% to pass — '
                              'review and try again. You\'ve got this!',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 18),
                    Center(
                        child:
                            StarRow(stars: o.stars, size: 44)),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _ResultStat(
                            label: 'Score',
                            value: '${o.scorePct}%',
                            icon: Icons.percent_rounded,
                            color: o.passed ? AppColors.success : AppColors.danger,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ResultStat(
                            label: 'Correct',
                            value: '${o.correct}/${o.total}',
                            icon: Icons.check_circle_rounded,
                            color: AppColors.info,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ResultStat(
                            label: 'XP earned',
                            value: '+${o.xpEarned}',
                            icon: Icons.bolt_rounded,
                            color: AppColors.gold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (o.scorePct >= 100)
                      _BonusRow(
                        icon: Icons.workspace_premium_rounded,
                        text:
                            'Perfect run bonus +${XpRules.perfectBonus} XP included',
                      ),
                    if (o.streakExtended && o.streakDays > 1)
                      _BonusRow(
                        icon: Icons.local_fire_department_rounded,
                        text: '${o.streakDays}-day streak — keep it alive!',
                      ),
                    for (final badge in o.newBadges)
                      _BonusRow(
                        icon: badge.icon,
                        text: 'Badge unlocked: ${badge.name}',
                      ),
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(o.passed ? 'Continue' : 'Back to map'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.fact_check_outlined),
                      label: const Text('Review answers'),
                      onPressed: () => _showReview(context),
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      icon: const Icon(Icons.replay_rounded),
                      label: const Text('Play again'),
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => QuizScreen(
                              course: widget.course, level: widget.level),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 24,
              emissionFrequency: 0.06,
              gravity: 0.25,
              colors: const [
                AppColors.gold,
                AppColors.goldBright,
                Colors.white,
                AppColors.info,
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showReview(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        builder: (sheetContext, scrollController) => ListView.separated(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          itemCount: widget.questions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (itemContext, i) => _ReviewTile(
            index: i,
            question: widget.questions[i],
            selected: widget.answers[widget.questions[i].id],
          ),
        ),
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  const _ResultStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ArenaCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _BonusRow extends StatelessWidget {
  const _BonusRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: AppColors.gold),
          const SizedBox(width: 8),
          Flexible(
            child: Text(text,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: AppColors.gold)),
          ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({
    required this.index,
    required this.question,
    required this.selected,
  });

  final int index;
  final Question question;
  final int? selected;

  @override
  Widget build(BuildContext context) {
    final correct = selected == question.correctIndex;
    final skipped = selected == null;
    final color = correct
        ? AppColors.success
        : skipped
            ? Theme.of(context).colorScheme.onSurfaceVariant
            : AppColors.danger;
    final textTheme = Theme.of(context).textTheme;

    return ArenaCard(
      borderColor: color.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                correct
                    ? Icons.check_circle_rounded
                    : skipped
                        ? Icons.remove_circle_outline_rounded
                        : Icons.cancel_rounded,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Q${index + 1} · ${question.topic}',
                    style: textTheme.labelMedium?.copyWith(color: color)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(question.question, style: textTheme.titleMedium),
          const SizedBox(height: 8),
          if (!correct && !skipped)
            Text('Your answer: ${question.options[selected!]}',
                style: textTheme.bodySmall?.copyWith(color: AppColors.danger)),
          Text(
            'Correct: ${question.options[question.correctIndex]}',
            style: textTheme.bodySmall?.copyWith(color: AppColors.success),
          ),
          if (question.explanation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(question.explanation, style: textTheme.bodySmall),
          ],
          if (question.resource != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: Text(question.resource!.title),
                onPressed: () => launchUrl(
                  Uri.parse(question.resource!.url),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
