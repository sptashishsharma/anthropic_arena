import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/glass.dart';
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
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
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
      body: NeonBackground(
        accent: course.color,
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(0, kToolbarHeight + 12, 0, 40),
            child: _LevelPath(
              course: course,
              starsFor: (level) => progress.progressFor(level.id).stars,
              isPassed: (level) => progress.progressFor(level.id).passed,
              isUnlocked: (level) => controller.isUnlocked(course, level),
              onTapLevel: (level) =>
                  _showLevelSheet(context, ref, course, level),
            ),
          ),
        ),
      ),
    );
  }

  void _showLevelSheet(
      BuildContext context, WidgetRef ref, Course course, Level level) {
    final progress = ref.read(progressProvider).progressFor(level.id);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: GlassSurface(
          radius: 28,
          glow: course.color,
          glowAlpha: 0.35,
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
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
                label:
                    Text(progress.attempts > 0 ? 'Play again' : 'Start level'),
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
      ),
    );
  }
}

class _LevelPath extends StatefulWidget {
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
  State<_LevelPath> createState() => _LevelPathState();
}

class _LevelPathState extends State<_LevelPath>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final levels = widget.course.levels;
    // The single node that's playable right now — it gets the pulsing glow.
    final activeIndex = levels.indexWhere(
        (l) => widget.isUnlocked(l) && !widget.isPassed(l));

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = levels.length * _LevelPath._rowHeight + 20;
        final centers = <Offset>[
          for (var i = 0; i < levels.length; i++)
            Offset(
              _LevelPath._xFraction(i) *
                      (width - _LevelPath._nodeSize - 40) +
                  _LevelPath._nodeSize / 2 +
                  20,
              i * _LevelPath._rowHeight + _LevelPath._rowHeight / 2,
            ),
        ];
        final doneUntil = levels.lastIndexWhere(widget.isPassed);

        return AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            final pulse = 0.5 + 0.5 * sin(t * 2 * pi);
            return SizedBox(
              width: width,
              height: height,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _PathPainter(
                        centers: centers,
                        trackColor: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.14),
                        doneColor: widget.course.color,
                        doneUntil: doneUntil,
                        t: t,
                      ),
                    ),
                  ),
                  for (var i = 0; i < levels.length; i++)
                    Positioned(
                      left: centers[i].dx - _LevelPath._nodeSize / 2,
                      top: centers[i].dy -
                          _LevelPath._rowHeight / 2 +
                          6,
                      width: _LevelPath._nodeSize + 8,
                      child: _LevelNode(
                        level: levels[i],
                        color: widget.course.color,
                        stars: widget.starsFor(levels[i]),
                        passed: widget.isPassed(levels[i]),
                        unlocked: widget.isUnlocked(levels[i]),
                        size: _LevelPath._nodeSize,
                        pulse: i == activeIndex ? pulse : 0,
                        onTap: () => widget.onTapLevel(levels[i]),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _PathPainter extends CustomPainter {
  _PathPainter({
    required this.centers,
    required this.trackColor,
    required this.doneColor,
    required this.doneUntil,
    required this.t,
  });

  final List<Offset> centers;
  final Color trackColor;
  final Color doneColor;

  /// Index of the deepest passed level; segments up to it are lit.
  final int doneUntil;

  /// Animation phase, 0..1, driving the flowing energy + dashes.
  final double t;

  Path _segment(Offset a, Offset b) {
    final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
    return Path()
      ..moveTo(a.dx, a.dy)
      ..quadraticBezierTo(a.dx, mid.dy, mid.dx, mid.dy)
      ..quadraticBezierTo(b.dx, mid.dy, b.dx, b.dy);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (centers.length < 2) return;

    // Build one continuous path + measure each segment's length so we can
    // map "level index" onto "distance along the path".
    final full = Path()..moveTo(centers[0].dx, centers[0].dy);
    final segLen = <double>[];
    for (var i = 0; i < centers.length - 1; i++) {
      final a = centers[i];
      final b = centers[i + 1];
      final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
      full
        ..quadraticBezierTo(a.dx, mid.dy, mid.dx, mid.dy)
        ..quadraticBezierTo(b.dx, mid.dy, b.dx, b.dy);
      segLen.add(_segment(a, b).computeMetrics().first.length);
    }

    final metric = full.computeMetrics().first;
    final total = metric.length;

    double lenUpTo(int node) {
      var s = 0.0;
      for (var i = 0; i < node && i < segLen.length; i++) {
        s += segLen[i];
      }
      return s;
    }

    // 1) Base translucent track for the whole route.
    canvas.drawPath(
      full,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..color = trackColor,
    );

    // 2) Completed portion: solid, glowing course colour.
    final done = doneUntil.clamp(0, centers.length - 1);
    final doneLen = lenUpTo(done);
    if (doneLen > 0) {
      canvas.drawPath(
        metric.extractPath(0, doneLen),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round
          ..color = doneColor
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3),
      );
    }

    // 3) Active segment (toward the next playable level): animated dashes.
    if (doneUntil >= 0 && doneUntil < segLen.length) {
      final start = doneLen;
      final end = (doneLen + segLen[doneUntil]).clamp(0.0, total);
      _drawDashes(canvas, metric, start, end,
          AppColors.gold.withValues(alpha: 0.9));
    }

    // 4) A comet of light flowing up the lit path.
    final travel = doneUntil < segLen.length
        ? (doneLen + segLen[max(0, doneUntil)]).clamp(0.0, total)
        : total;
    if (travel > 6) {
      const cometLen = 56.0;
      final head = t * travel;
      final from = (head - cometLen).clamp(0.0, travel);
      canvas.drawPath(
        metric.extractPath(from, head.clamp(0.0, travel)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round
          ..color = AppColors.neonGold
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
  }

  void _drawDashes(
      Canvas canvas, PathMetric metric, double start, double end, Color color) {
    const dash = 11.0;
    const gap = 9.0;
    const period = dash + gap;
    final phase = t * period;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = color;
    var d = start - phase;
    while (d < end) {
      final s = d.clamp(start, end);
      final e = (d + dash).clamp(start, end);
      if (e > s) canvas.drawPath(metric.extractPath(s, e), paint);
      d += period;
    }
  }

  @override
  bool shouldRepaint(_PathPainter old) =>
      old.t != t ||
      old.doneUntil != doneUntil ||
      old.centers != centers ||
      old.doneColor != doneColor;
}

class _LevelNode extends StatelessWidget {
  const _LevelNode({
    required this.level,
    required this.color,
    required this.stars,
    required this.passed,
    required this.unlocked,
    required this.size,
    required this.pulse,
    required this.onTap,
  });

  final Level level;
  final Color color;
  final int stars;
  final bool passed;
  final bool unlocked;
  final double size;

  /// 0 = steady, up to 1 = brightest — only the active node pulses.
  final double pulse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final Color fill;
    final Widget inner;
    final Color glow;
    final bool glass;
    if (!unlocked) {
      fill = scheme.onSurface.withValues(alpha: 0.06);
      inner = Icon(Icons.lock_rounded,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.8));
      glow = Colors.transparent;
      glass = true;
    } else if (passed) {
      fill = color;
      inner = const Icon(Icons.check_rounded, color: Colors.white, size: 34);
      glow = color;
      glass = false;
    } else {
      fill = AppColors.gold;
      inner =
          const Icon(Icons.play_arrow_rounded, color: AppColors.ink, size: 36);
      glow = AppColors.neonGold;
      glass = false;
    }

    final glowAlpha = passed ? 0.5 : (0.35 + 0.45 * pulse);
    final glowBlur = passed ? 20.0 : (16.0 + 16.0 * pulse);

    final decoration = BoxDecoration(
      shape: BoxShape.circle,
      color: fill,
      gradient: glass
          ? null
          : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(fill, Colors.white, 0.22)!,
                fill,
              ],
            ),
      border: Border.all(
        color: unlocked
            ? Colors.white.withValues(alpha: 0.9)
            : scheme.onSurface.withValues(alpha: 0.18),
        width: 3,
      ),
      boxShadow: glow == Colors.transparent
          ? null
          : [
              BoxShadow(
                color: glow.withValues(alpha: glowAlpha),
                blurRadius: glowBlur,
                spreadRadius: passed ? 0 : 2,
              ),
            ],
    );

    Widget circle = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: decoration,
      child: inner,
    );

    // Locked nodes read as frosted glass; lit nodes stay solid so the glow
    // and iconography pop.
    if (glass) {
      circle = ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: circle,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: unlocked ? onTap : null,
            customBorder: const CircleBorder(),
            child: circle,
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
