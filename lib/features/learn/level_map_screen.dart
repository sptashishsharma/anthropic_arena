import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../data/models/course.dart';
import '../../state/providers.dart';
import '../quiz/quiz_screen.dart';

class LevelMapScreen extends ConsumerWidget {
  const LevelMapScreen({super.key, required this.courseId});

  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courses = ref.watch(coursesProvider).value ?? const <Course>[];
    final course = courses.where((c) => c.id == courseId).firstOrNull;
    if (course == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final progress = ref.watch(progressProvider);
    final controller = ref.read(progressProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(course.title),
            Text(
              course.tagline,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: _LevelPath(
          course: course,
          starsFor: (level) => progress.progressFor(level.id).stars,
          isPassed: (level) => progress.progressFor(level.id).passed,
          isUnlocked: (level) => controller.isUnlocked(course, level),
          onTapLevel: (level) => _showLevelSheet(context, ref, course, level),
        ),
      ),
    );
  }

  void _showLevelSheet(
      BuildContext context, WidgetRef ref, Course course, Level level) {
    final progress = ref.read(progressProvider).progressFor(level.id);
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Level ${level.order} — ${level.title}',
                      style: Theme.of(context).textTheme.headlineSmall),
                ),
                StarRow(stars: progress.stars),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatChip(
                  icon: Icons.category_rounded,
                  label: level.topic,
                  color: course.color,
                ),
                StatChip(
                  icon: Icons.quiz_rounded,
                  label: '${level.questions.length} questions',
                  color: AppColors.info,
                ),
                StatChip(
                  icon: Icons.flag_rounded,
                  label: 'Pass at ${level.passMark}%',
                  color: AppColors.success,
                ),
                if (progress.attempts > 0)
                  StatChip(
                    icon: Icons.emoji_events_rounded,
                    label: 'Best ${progress.bestScorePct}%',
                  ),
              ],
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(progress.attempts > 0 ? 'Play again' : 'Start level'),
              onPressed: () {
                Navigator.of(sheetContext).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => QuizScreen(course: course, level: level),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelPath extends StatelessWidget {
  const _LevelPath({
    required this.course,
    required this.starsFor,
    required this.isPassed,
    required this.isUnlocked,
    required this.onTapLevel,
  });

  final Course course;
  final int Function(Level) starsFor;
  final bool Function(Level) isPassed;
  final bool Function(Level) isUnlocked;
  final void Function(Level) onTapLevel;

  static const _rowHeight = 132.0;
  static const _nodeSize = 78.0;

  /// Horizontal position of node [i] as a fraction of available width.
  static double _xFraction(int i) => 0.5 + 0.32 * sin(i * pi / 2);

  @override
  Widget build(BuildContext context) {
    final levels = course.levels;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = levels.length * _rowHeight + 20;
        final centers = <Offset>[
          for (var i = 0; i < levels.length; i++)
            Offset(
              _xFraction(i) * (width - _nodeSize - 40) + _nodeSize / 2 + 20,
              i * _rowHeight + _rowHeight / 2,
            ),
        ];
        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _PathPainter(
                    centers: centers,
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.8),
                    doneColor: course.color,
                    doneUntil:
                        levels.lastIndexWhere((l) => isPassed(l)),
                  ),
                ),
              ),
              for (var i = 0; i < levels.length; i++)
                Positioned(
                  left: centers[i].dx - _nodeSize / 2,
                  top: centers[i].dy - _rowHeight / 2 + 6,
                  width: _nodeSize + 8,
                  child: _LevelNode(
                    level: levels[i],
                    color: course.color,
                    stars: starsFor(levels[i]),
                    passed: isPassed(levels[i]),
                    unlocked: isUnlocked(levels[i]),
                    size: _nodeSize,
                    onTap: () => onTapLevel(levels[i]),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PathPainter extends CustomPainter {
  _PathPainter({
    required this.centers,
    required this.color,
    required this.doneColor,
    required this.doneUntil,
  });

  final List<Offset> centers;
  final Color color;
  final Color doneColor;

  /// Index of the deepest passed level; segments up to it are tinted.
  final int doneUntil;

  @override
  void paint(Canvas canvas, Size size) {
    if (centers.length < 2) return;
    for (var i = 0; i < centers.length - 1; i++) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = i < doneUntil ? doneColor.withValues(alpha: 0.7) : color;
      final a = centers[i];
      final b = centers[i + 1];
      final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(a.dx, mid.dy, mid.dx, mid.dy)
        ..quadraticBezierTo(b.dx, mid.dy, b.dx, b.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_PathPainter old) =>
      old.centers != centers || old.doneUntil != doneUntil;
}

class _LevelNode extends StatelessWidget {
  const _LevelNode({
    required this.level,
    required this.color,
    required this.stars,
    required this.passed,
    required this.unlocked,
    required this.size,
    required this.onTap,
  });

  final Level level;
  final Color color;
  final int stars;
  final bool passed;
  final bool unlocked;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color fill;
    final Widget inner;
    if (!unlocked) {
      fill = scheme.surfaceContainerHighest;
      inner = Icon(Icons.lock_rounded, color: scheme.onSurfaceVariant);
    } else if (passed) {
      fill = color;
      inner = const Icon(Icons.check_rounded, color: Colors.white, size: 34);
    } else {
      fill = AppColors.gold;
      inner = const Icon(Icons.play_arrow_rounded,
          color: AppColors.ink, size: 36);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: unlocked ? onTap : null,
            customBorder: const CircleBorder(),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fill,
                border: Border.all(
                  color: unlocked
                      ? Colors.white.withValues(alpha: 0.85)
                      : scheme.outline,
                  width: 3,
                ),
                boxShadow: unlocked && !passed
                    ? [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.45),
                          blurRadius: 18,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: inner,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Lv ${level.order}',
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (stars > 0) StarRow(stars: stars, size: 14),
      ],
    );
  }
}
