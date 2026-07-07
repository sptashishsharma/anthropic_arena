import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../data/leaderboard.dart';
import '../../state/providers.dart';

class RankingTab extends ConsumerWidget {
  const RankingTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(leaderboardProvider);
    final top3 = entries.take(3).toList();
    final rest = entries.skip(3).toList();
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text('Ranking', style: textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            'Demo standings — the global arena goes live with Firebase.',
            style: textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          if (top3.length >= 3)
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
            _RankRow(entry: rest[i], rank: i + 4),
            const SizedBox(height: 8),
          ],
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
        PlayerAvatar(initial: entry.name[0].toUpperCase(), size: 40),
        const SizedBox(height: 6),
        Text(
          entry.isYou ? 'You' : entry.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        Text('${entry.xp} XP',
            style: textTheme.labelSmall
                ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 6),
        Container(
          height: height - 92,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color.withValues(alpha: 0.85), color.withValues(alpha: 0.35)],
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
          PlayerAvatar(initial: entry.name[0].toUpperCase(), size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    entry.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: 6),
                Text(entry.tag,
                    style: textTheme.labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
                if (entry.isYou) ...[
                  const SizedBox(width: 8),
                  const StatChip(
                      icon: Icons.person_rounded, label: 'You'),
                ],
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
