import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/layout.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/motion.dart';
import '../../core/widgets/progress_ring.dart';
import '../../data/models/course.dart';
import '../../data/models/progress.dart';
import '../../gamification/ranks.dart';
import '../../gamification/xp_rules.dart';
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
        loading: () => const _LoadingSkeleton(),
        error: (e, _) => _ErrorState(message: '$e'),
        data: (list) => ContentShell(
          child: ListView(
            // Bottom padding clears the navigation bar so the last card is
            // never sliced by it.
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
            children: [
              _Header(playerName: player?.name ?? 'Player', progress: progress),
              const SizedBox(height: 16),
              _DailyGoalCard(progress: progress),
              const SizedBox(height: 14),
              _ContinueCard(courses: list, progress: progress),
              const SizedBox(height: 20),
              SectionTitle('Courses',
                  trailing: Text('${list.length}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant))),
              const SizedBox(height: 12),
              ResponsiveCardGrid(
                children: [
                  for (var i = 0; i < list.length; i++)
                    EntranceFade(
                      index: i,
                      child:
                          _CourseCard(course: list[i], progress: progress),
                    ),
                ],
              ),
            ],
          ),
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

/// Today's goal ring plus the rank the player is climbing toward.
class _DailyGoalCard extends StatelessWidget {
  const _DailyGoalCard({required this.progress});

  final UserProgress progress;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final today = progress.xpToday;
    final goal = XpRules.dailyGoalXp;
    final met = today >= goal;
    final tier = Ranks.forXp(progress.xp);
    final next = Ranks.nextAfter(progress.xp);

    return ArenaCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          ProgressRing(
            value: goal == 0 ? 1 : today / goal,
            color: met ? AppColors.success : AppColors.gold,
            size: 88,
            stroke: 9,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CountUpText(
                  today,
                  style: textTheme.titleLarge?.copyWith(
                    color: met ? AppColors.success : AppColors.gold,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text('/ $goal XP',
                    style: textTheme.labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(met ? 'Daily goal complete! 🎉' : 'Today\'s goal',
                    style: textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  met
                      ? 'Streak safe for today. Keep going for bonus XP.'
                      : 'Earn ${goal - today} more XP to keep your streak alive.',
                  style: textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(tier.icon, size: 16, color: tier.color),
                    const SizedBox(width: 6),
                    Text(tier.name,
                        style: textTheme.labelLarge
                            ?.copyWith(color: tier.color)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ArenaProgressBar(
                        value: Ranks.progress(progress.xp),
                        color: tier.color,
                        height: 6,
                      ),
                    ),
                  ],
                ),
                if (next != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${Ranks.xpToNext(progress.xp)} XP to ${next.name}',
                    style: textTheme.labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Jumps straight back to the first unfinished level, so returning players
/// never have to remember where they stopped.
class _ContinueCard extends ConsumerWidget {
  const _ContinueCard({required this.courses, required this.progress});

  final List<Course> courses;
  final UserProgress progress;

  ({Course course, Level level})? _nextUp(WidgetRef ref) {
    final controller = ref.read(progressProvider.notifier);
    // Prefer a course already in flight, then anything still unlocked.
    for (final started in [true, false]) {
      for (final course in courses) {
        final touched =
            course.levels.any((l) => progress.progressFor(l.id).attempts > 0);
        if (touched != started) continue;
        for (final level in course.levels) {
          if (progress.progressFor(level.id).passed) continue;
          if (!controller.isUnlocked(course, level)) continue;
          return (course: course, level: level);
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = _nextUp(ref);
    if (next == null) return const SizedBox.shrink();

    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final fresh = progress.levelsCompleted == 0;

    return ArenaCard(
      borderColor: AppColors.gold,
      padding: const EdgeInsets.all(18),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LevelMapScreen(courseId: next.course.id),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow_rounded,
                color: AppColors.gold, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fresh ? 'Start here' : 'Continue where you left off',
                    style: textTheme.labelMedium
                        ?.copyWith(color: AppColors.gold)),
                const SizedBox(height: 3),
                Text('${next.course.title} · ${next.level.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
        ],
      ),
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
    final complete = total > 0 && done == total;

    return ArenaCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => LevelMapScreen(courseId: course.id)),
      ),
      padding: const EdgeInsets.all(18),
      borderColor: complete ? AppColors.success : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Hero(
                tag: 'course-icon-${course.id}',
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: course.color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    complete
                        ? Icons.verified_rounded
                        : Icons.menu_book_rounded,
                    color: complete ? AppColors.success : course.color,
                    size: 26,
                  ),
                ),
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
                  color: complete ? AppColors.success : course.color,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  complete ? 'Complete' : '$done / $total levels',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelMedium?.copyWith(
                      color: complete
                          ? AppColors.success
                          : scheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shimmerless but structured placeholder — keeps the first paint from being
/// an empty black screen with a lone spinner.
class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ContentShell(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
        children: [
          for (var i = 0; i < 5; i++) ...[
            const SkeletonBlock(height: 118),
            const SizedBox(height: 14),
          ],
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
