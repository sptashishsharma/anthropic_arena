import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/layout.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../data/leaderboard.dart';
import '../../data/models/player.dart';
import '../../gamification/ranks.dart';
import '../../state/providers.dart';
import '../auth/login_screen.dart';

class RankingTab extends ConsumerWidget {
  const RankingTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(leaderboardProvider);
    final isLive = ref.watch(leaderboardIsLiveProvider);
    final scope = ref.watch(leaderboardScopeProvider);
    final isGuest = ref.watch(authProvider)?.provider == AuthProvider.guest;
    final hasPodium = entries.length >= 3;
    final top3 = hasPodium ? entries.take(3).toList() : <LeaderboardEntry>[];
    final rest = hasPodium ? entries.skip(3).toList() : entries;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: ContentShell(
        maxWidth: 760,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
          children: [
            Text('Ranking', style: textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              isLive
                  ? (scope == LeaderboardScope.week
                      ? 'This week\'s climbers — resets every Monday.'
                      : 'Global leaderboard — live. Play levels to climb!')
                  : 'Demo standings — the global arena goes live with Firebase.',
              style: textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            _ScopeTabs(
              scope: scope,
              onChanged: (s) =>
                  ref.read(leaderboardScopeProvider.notifier).set(s),
            ),
            const SizedBox(height: 20),
            if (isGuest) ...[
              _GuestPrompt(),
              const SizedBox(height: 16),
            ],
            if (entries.isEmpty)
              _EmptyBoard(weekly: scope == LeaderboardScope.week)
            else ...[
              if (hasPodium)
                SizedBox(
                  height: 216,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                          child: _PodiumSpot(
                              entry: top3[1],
                              place: 2,
                              height: 152,
                              color: AppColors.silver)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _PodiumSpot(
                              entry: top3[0],
                              place: 1,
                              height: 184,
                              color: AppColors.gold)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _PodiumSpot(
                              entry: top3[2],
                              place: 3,
                              height: 132,
                              color: AppColors.bronze)),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              for (var i = 0; i < rest.length; i++) ...[
                _RankRow(entry: rest[i], rank: i + (hasPodium ? 4 : 1)),
                const SizedBox(height: 8),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// All-time vs this-week switch.
class _ScopeTabs extends StatelessWidget {
  const _ScopeTabs({required this.scope, required this.onChanged});

  final LeaderboardScope scope;
  final ValueChanged<LeaderboardScope> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<LeaderboardScope>(
      segments: const [
        ButtonSegment(
          value: LeaderboardScope.allTime,
          icon: Icon(Icons.public_rounded, size: 18),
          label: Text('All time'),
        ),
        ButtonSegment(
          value: LeaderboardScope.week,
          icon: Icon(Icons.calendar_today_rounded, size: 16),
          label: Text('This week'),
        ),
      ],
      selected: {scope},
      showSelectedIcon: false,
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

class _GuestPrompt extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ArenaCard(
      child: Row(
        children: [
          const Icon(Icons.emoji_events_outlined,
              color: AppColors.gold, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'You\'re playing as a guest, so your score stays off '
              'the rankings. Sign in to compete!',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
            child: const Text('Sign in'),
          ),
        ],
      ),
    );
  }
}

/// Shown when nobody has scored yet in the selected scope — far better than a
/// wall of "0 XP" rows.
class _EmptyBoard extends StatelessWidget {
  const _EmptyBoard({required this.weekly});

  final bool weekly;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ArenaCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        children: [
          const Icon(Icons.emoji_events_rounded,
              color: AppColors.gold, size: 44),
          const SizedBox(height: 14),
          Text(
            weekly ? 'No scores yet this week' : 'The arena is wide open',
            style: textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            weekly
                ? 'Finish one level and you\'ll top this week\'s board.'
                : 'Be the first to put a score on the board — pass a level to claim the crown.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _PodiumSpot extends StatelessWidget {
  const _PodiumSpot({
    required this.entry,
    required this.place,
    required this.height,
    required this.color,
  });

  final LeaderboardEntry entry;
  final int place;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (place == 1)
          const Icon(Icons.emoji_events_rounded,
              color: AppColors.gold, size: 26),
        PlayerAvatar(
          initial: entry.name.isEmpty ? 'P' : entry.name[0].toUpperCase(),
          photoUrl: entry.photoUrl,
          size: 40,
          ring: color,
        ),
        const SizedBox(height: 6),
        Text(
          entry.isYou ? 'You' : entry.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        Text('${entry.xp} XP',
            style: textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 6),
        Container(
          height: height - 92,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: 0.85),
                color.withValues(alpha: 0.35)
              ],
            ),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(14)),
          ),
          alignment: Alignment.center,
          child: Text(
            '$place',
            style: textTheme.displaySmall?.copyWith(
              color: AppColors.ink.withValues(alpha: 0.8),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.entry, required this.rank});

  final LeaderboardEntry entry;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final tier = Ranks.forXp(entry.xp);
    return ArenaCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderColor: entry.isYou ? AppColors.gold : null,
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text('$rank',
                style: textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
          ),
          PlayerAvatar(
            initial: entry.name.isEmpty ? 'P' : entry.name[0].toUpperCase(),
            photoUrl: entry.photoUrl,
            size: 36,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium,
                      ),
                    ),
                    if (entry.isYou) ...[
                      const SizedBox(width: 8),
                      const StatChip(
                          icon: Icons.person_rounded, label: 'You'),
                    ],
                  ],
                ),
                Row(
                  children: [
                    Icon(tier.icon, size: 12, color: tier.color),
                    const SizedBox(width: 4),
                    Text(tier.name,
                        style:
                            textTheme.labelSmall?.copyWith(color: tier.color)),
                    const SizedBox(width: 6),
                    Text(entry.tag,
                        style: textTheme.labelSmall
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
          Text('${entry.xp} XP',
              style: textTheme.titleMedium?.copyWith(
                  color: AppColors.gold, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
