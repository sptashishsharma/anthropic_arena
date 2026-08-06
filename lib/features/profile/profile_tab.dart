import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_info.dart';
import '../../core/layout.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/widgets/streak_heatmap.dart';
import '../../data/models/course.dart';
import '../../data/models/progress.dart';
import '../../gamification/badges.dart';
import '../../gamification/ranks.dart';
import '../../state/providers.dart';
import '../auth/login_screen.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(authProvider);
    final progress = ref.watch(progressProvider);
    final themeMode = ref.watch(themeProvider);
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    if (player == null) return const SizedBox.shrink();

    final tier = Ranks.forXp(progress.xp);

    return SafeArea(
      child: ContentShell(
        maxWidth: 820,
        child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
        children: [
          Row(
            children: [
              PlayerAvatar(
                initial: player.initial,
                photoUrl: player.photoUrl,
                size: 64,
                ring: tier.color,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(player.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.headlineMedium),
                        ),
                        const SizedBox(width: 8),
                        Text(player.tag,
                            style: textTheme.labelLarge
                                ?.copyWith(color: scheme.onSurfaceVariant)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    StatChip(
                      icon: switch (player.provider.name) {
                        'google' => Icons.g_mobiledata_rounded,
                        'apple' => Icons.apple_rounded,
                        'microsoft' => Icons.window_rounded,
                        'email' => Icons.mail_rounded,
                        _ => Icons.sports_esports_rounded,
                      },
                      label: switch (player.provider.name) {
                        'google' => player.isDemo ? 'Google (demo)' : 'Google',
                        'apple' => player.isDemo ? 'Apple (demo)' : 'Apple',
                        'microsoft' => player.isDemo
                            ? 'Microsoft (demo)'
                            : player.email ?? 'Microsoft',
                        'email' => player.email ?? 'Email',
                        _ => 'Guest player',
                      },
                      color: AppColors.info,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit name',
                icon: const Icon(Icons.edit_rounded),
                onPressed: () => _editName(context, ref, player.name),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _RankCard(progress: progress),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ArenaCard(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    children: [
                      CountUpText(progress.xp,
                          style: textTheme.headlineSmall
                              ?.copyWith(color: AppColors.gold)),
                      Text('XP', style: textTheme.labelSmall),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ArenaCard(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    children: [
                      CountUpText(progress.streakDays,
                          style: textTheme.headlineSmall
                              ?.copyWith(color: const Color(0xFFFF7A45))),
                      Text('Streak', style: textTheme.labelSmall),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ArenaCard(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    children: [
                      CountUpText(progress.badges.length,
                          style: textTheme.headlineSmall
                              ?.copyWith(color: AppColors.success)),
                      Text('Badges', style: textTheme.labelSmall),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const SectionTitle('Activity'),
          const SizedBox(height: 12),
          ArenaCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Last 14 weeks',
                    style: textTheme.labelMedium
                        ?.copyWith(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 12),
                StreakHeatmap(xpByDay: progress.xpByDay),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SectionTitle('Badges',
              trailing: Text('${progress.badges.length}/${Badges.all.length}',
                  style: textTheme.labelLarge
                      ?.copyWith(color: scheme.onSurfaceVariant))),
          const SizedBox(height: 12),
          _BadgeGrid(progress: progress),
          const SizedBox(height: 24),
          const SectionTitle('Settings'),
          const SizedBox(height: 12),
          ArenaCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Theme', style: textTheme.titleMedium),
                const SizedBox(height: 10),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.smartphone_rounded),
                        label: Text('Auto')),
                    ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode_rounded),
                        label: Text('Light')),
                    ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode_rounded),
                        label: Text('Dark')),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (set) =>
                      ref.read(themeProvider.notifier).set(set.first),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ArenaCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Streak reminders'),
                  subtitle: const Text('A daily nudge to keep your streak'),
                  trailing: Switch(
                    value: ref.watch(remindersProvider),
                    onChanged: (on) async {
                      final message = await ref
                          .read(remindersProvider.notifier)
                          .setEnabled(on);
                      if (message != null && context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(message)));
                      }
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading:
                      const Icon(Icons.restart_alt_rounded, color: AppColors.danger),
                  title: const Text('Reset progress',
                      style: TextStyle(color: AppColors.danger)),
                  onTap: () => _confirmReset(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout_rounded),
                  title: const Text('Sign out'),
                  onTap: () => _signOut(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                const BrandMark(size: 40),
                const SizedBox(height: 6),
                Text('${AppInfo.name} · v${AppInfo.version}',
                    style: textTheme.labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
                Text(AppInfo.credit,
                    style: textTheme.labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  Future<void> _editName(
      BuildContext context, WidgetRef ref, String current) async {
    final controller = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Display name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name != null && name.length >= 2) {
      ref.read(authProvider.notifier).rename(name);
    }
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset all progress?'),
        content: const Text(
            'XP, streaks, stars and badges on this device will be erased. '
            'This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(progressProvider.notifier).resetAll();
    }
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(authProvider.notifier).signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }
}

/// Rank tier hero: current tier, XP ring to the next one, and how far away it
/// is. Gives players a goal that outlives finishing every course.
class _RankCard extends StatelessWidget {
  const _RankCard({required this.progress});

  final UserProgress progress;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final tier = Ranks.forXp(progress.xp);
    final next = Ranks.nextAfter(progress.xp);

    return ArenaCard(
      padding: const EdgeInsets.all(18),
      borderColor: tier.color,
      child: Row(
        children: [
          ProgressRing(
            value: Ranks.progress(progress.xp),
            color: tier.color,
            size: 82,
            stroke: 8,
            child: Icon(tier.icon, color: tier.color, size: 32),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rank', style: textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant)),
                Text(tier.name,
                    style: textTheme.headlineSmall?.copyWith(color: tier.color)),
                const SizedBox(height: 6),
                Text(
                  next == null
                      ? 'Top tier reached — you are a Legend.'
                      : '${Ranks.xpToNext(progress.xp)} XP to ${next.name}',
                  style: textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge wall. Locked badges show how close they are and open a detail sheet
/// on tap, so they read as goals rather than dead padlocks.
class _BadgeGrid extends ConsumerWidget {
  const _BadgeGrid({required this.progress});

  final UserProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final courses = ref.watch(coursesProvider).value ?? const <Course>[];
    final columns = MediaQuery.sizeOf(context).width >= Breakpoints.medium ? 7 : 5;

    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: [
        for (final badge in Badges.all)
          Builder(builder: (context) {
            final earned = progress.badges.contains(badge.id);
            final pct = badge.progressFor(progress, courses);
            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showBadgeSheet(context, badge, earned, pct,
                  badge.measure?.call(progress, courses)),
              child: Container(
                decoration: BoxDecoration(
                  color: earned
                      ? AppColors.gold.withValues(alpha: 0.16)
                      : scheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: earned ? AppColors.gold : scheme.outline,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Center(
                      child: Icon(
                        earned ? badge.icon : Icons.lock_outline_rounded,
                        color:
                            earned ? AppColors.gold : scheme.onSurfaceVariant,
                      ),
                    ),
                    // A locked badge that is partly done shows a hairline of
                    // progress along the bottom edge.
                    if (!earned && pct > 0)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                          child: ArenaProgressBar(
                              value: pct, height: 3, color: AppColors.gold),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  void _showBadgeSheet(BuildContext context, BadgeSpec badge, bool earned,
      double pct, (int, int)? measure) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final textTheme = Theme.of(sheetContext).textTheme;
        final scheme = Theme.of(sheetContext).colorScheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: earned
                      ? AppColors.gold.withValues(alpha: 0.18)
                      : scheme.surfaceContainerHighest,
                  border: Border.all(
                      color: earned ? AppColors.gold : scheme.outline,
                      width: 2),
                ),
                child: Icon(
                  earned ? badge.icon : Icons.lock_outline_rounded,
                  size: 34,
                  color: earned ? AppColors.gold : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              Text(badge.name, style: textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(
                badge.description,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 18),
              if (earned)
                const StatChip(
                    icon: Icons.check_circle_rounded,
                    label: 'Earned',
                    color: AppColors.success)
              else ...[
                ArenaProgressBar(value: pct, color: AppColors.gold),
                const SizedBox(height: 8),
                Text(
                  measure == null
                      ? 'Keep playing to unlock'
                      : '${measure.$1} / ${measure.$2}',
                  style: textTheme.labelLarge
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
