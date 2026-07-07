import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/common.dart';
import '../../data/models/course.dart';
import '../../data/models/progress.dart';
import '../../state/providers.dart';
import 'level_map_screen.dart';

class LearnTab extends ConsumerWidget {
  const LearnTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courses = ref.watch(coursesProvider);
    final progress = ref.watch(progressProvider);
    final player = ref.watch(authProvider);

    return SafeArea(
      child: courses.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(message: '$e'),
        data: (list) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            _Header(playerName: player?.name ?? 'Player', progress: progress),
            const SizedBox(height: 20),
            for (final course in list) ...[
              _CourseCard(course: course, progress: progress),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.playerName, required this.progress});

  final String playerName;
  final UserProgress progress;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hi $playerName 👋',
                  style: textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text('Ready to level up?', style: textTheme.headlineMedium),
            ],
          ),
        ),
        StatChip(
          icon: Icons.local_fire_department_rounded,
          label: '${progress.streakDays}',
          color: progress.streakDays > 0
              ? const Color(0xFFFF7A45)
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        StatChip(icon: Icons.bolt_rounded, label: '${progress.xp} XP'),
      ],
    );
  }
}

class _CourseCard extends ConsumerWidget {
  const _CourseCard({required this.course, required this.progress});

  final Course course;
  final UserProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done =
        course.levels.where((l) => progress.progressFor(l.id).passed).length;
    final total = course.levels.length;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return ArenaCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => LevelMapScreen(courseId: course.id)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: course.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.menu_book_rounded,
                    color: course.color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(course.title, style: textTheme.titleLarge),
                    const SizedBox(height: 2),
                    Text(
                      course.tagline,
                      style: textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ArenaProgressBar(
                  value: total == 0 ? 0 : done / total,
                  color: course.color,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$done / $total levels',
                style: textTheme.labelMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const BrandMark(size: 80),
            const SizedBox(height: 16),
            Text('Could not load courses',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
