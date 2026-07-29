import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../data/models/progress.dart';
import '../../state/providers.dart';

class AnalysisTab extends ConsumerWidget {
  const AnalysisTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final textTheme = Theme.of(context).textTheme;

    final hasLevels = progress.attempts.isNotEmpty;
    final hasCerts = progress.certAttempts.isNotEmpty;

    if (!hasLevels && !hasCerts) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const BrandMark(size: 96),
                const SizedBox(height: 18),
                Text('No data yet', style: textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Play a level or take a certification exam — your personal '
                  'analysis appears here.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text('Personal Analysis', style: textTheme.headlineMedium),
          const SizedBox(height: 16),
          if (hasLevels) ...[
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.bolt_rounded,
                    color: AppColors.gold,
                    value: '${progress.xp}',
                    label: 'Total XP',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    icon: Icons.local_fire_department_rounded,
                    color: const Color(0xFFFF7A45),
                    value: '${progress.streakDays}',
                    label: 'Day streak',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.gps_fixed_rounded,
                    color: AppColors.info,
                    value: '${progress.accuracyPct}%',
                    label: 'Accuracy',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    icon: Icons.flag_rounded,
                    color: AppColors.success,
                    value: '${progress.levelsCompleted}',
                    label: 'Levels passed',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const SectionTitle('XP — last 14 days'),
            const SizedBox(height: 12),
            ArenaCard(
              padding: const EdgeInsets.fromLTRB(10, 18, 18, 8),
              child: SizedBox(height: 180, child: _XpChart(progress: progress)),
            ),
            const SizedBox(height: 24),
            const SectionTitle('Recent scores'),
            const SizedBox(height: 12),
            ArenaCard(
              padding: const EdgeInsets.fromLTRB(10, 18, 18, 8),
              child: SizedBox(
                  height: 160, child: _ScoresChart(progress: progress)),
            ),
            const SizedBox(height: 24),
            const SectionTitle('Weak spots'),
            const SizedBox(height: 4),
            Text(
              'Topics where your accuracy is lowest — revisit them to level up.',
              style: textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            ..._weakSpots(progress, context),
          ],
          if (hasCerts) ...[
            if (hasLevels) const SizedBox(height: 24),
            const SectionTitle('Certification performance'),
            const SizedBox(height: 4),
            Text(
              'Your practice-exam results per credential.',
              style: textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            ..._CertificationSection.build(progress, context),
          ],
        ],
      ),
    );
  }

  List<Widget> _weakSpots(UserProgress progress, BuildContext context) {
    final correct = <String, int>{};
    final total = <String, int>{};
    for (final a in progress.attempts) {
      a.topicTotal.forEach((t, n) => total[t] = (total[t] ?? 0) + n);
      a.topicCorrect.forEach((t, n) => correct[t] = (correct[t] ?? 0) + n);
    }
    final spots = total.entries
        .where((e) => e.value >= 3)
        .map((e) => (
              topic: e.key,
              pct: ((correct[e.key] ?? 0) * 100 / e.value).round(),
              seen: e.value,
            ))
        .toList()
      ..sort((a, b) => a.pct.compareTo(b.pct));

    final weak = spots.where((s) => s.pct < 85).take(4).toList();
    if (weak.isEmpty) {
      return [
        ArenaCard(
          child: Row(
            children: [
              const Icon(Icons.verified_rounded, color: AppColors.success),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No weak spots found — your accuracy is strong across all '
                  'topics. Keep it up!',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ];
    }
    return [
      for (final s in weak) ...[
        ArenaCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(s.topic,
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  Text(
                    '${s.pct}% · ${s.seen} questions',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: s.pct < 60 ? AppColors.danger : AppColors.gold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ArenaProgressBar(
                value: s.pct / 100,
                color: s.pct < 60 ? AppColors.danger : AppColors.gold,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    ];
  }
}

/// Per-credential summary cards for the Certification section of Analysis.
/// One card per certification the user has attempted, most recent first.
abstract final class _CertificationSection {
  static List<Widget> build(UserProgress progress, BuildContext context) {
    final byCert = <String, List<CertAttempt>>{};
    for (final a in progress.certAttempts) {
      byCert.putIfAbsent(a.certId, () => []).add(a);
    }
    final entries = byCert.entries.toList()
      ..sort((a, b) => b.value.last.dateIso.compareTo(a.value.last.dateIso));

    return [
      for (final e in entries) ...[
        _CertSummaryCard(attempts: e.value),
        const SizedBox(height: 10),
      ],
    ];
  }
}

class _CertSummaryCard extends StatelessWidget {
  const _CertSummaryCard({required this.attempts});

  /// All attempts for a single certification.
  final List<CertAttempt> attempts;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final last = attempts.last;
    var best = attempts.first;
    for (final a in attempts) {
      if (a.scorePct > best.scorePct) best = a;
    }
    final passed = best.passed;
    final statusColor = passed ? AppColors.success : AppColors.danger;

    return ArenaCard(
      borderColor: passed ? AppColors.success.withValues(alpha: 0.5) : null,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                passed
                    ? Icons.workspace_premium_rounded
                    : Icons.timelapse_rounded,
                color: statusColor,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(last.certName, style: textTheme.titleLarge),
              ),
              Text(
                passed ? 'Passed' : 'Keep going',
                style: textTheme.labelLarge
                    ?.copyWith(color: statusColor, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Best ${best.scorePct}%',
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(width: 10),
              Text('· pass ${best.passMark}%',
                  style: textTheme.labelMedium
                      ?.copyWith(color: scheme.onSurfaceVariant)),
              const Spacer(),
              Text(
                '${attempts.length} attempt${attempts.length == 1 ? '' : 's'}'
                ' · last ${last.scorePct}%',
                style: textTheme.labelMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Stack(
            children: [
              ArenaProgressBar(value: best.scorePct / 100, color: statusColor),
              // Pass-mark marker.
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, c) => Padding(
                    padding: EdgeInsets.only(
                        left: c.maxWidth * (best.passMark / 100) - 1),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 2,
                        height: 10,
                        color: scheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
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

class _XpChart extends StatelessWidget {
  const _XpChart({required this.progress});

  final UserProgress progress;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = [
      for (var i = 13; i >= 0; i--) now.subtract(Duration(days: i)),
    ];
    final values = [
      for (final d in days)
        (progress.xpByDay[
                    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}'] ??
                0)
            .toDouble(),
    ];
    final maxY =
        (values.reduce((a, b) => a > b ? a : b) * 1.3).clamp(50.0, 10000.0);
    final labelStyle = Theme.of(context)
        .textTheme
        .labelSmall
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => FlLine(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (v, meta) => Text(
                v.toInt().toString(),
                style: labelStyle,
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 4,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= days.length) return const SizedBox.shrink();
                final d = days[i];
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('${d.day}/${d.month}', style: labelStyle),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < values.length; i++)
                FlSpot(i.toDouble(), values[i]),
            ],
            isCurved: true,
            curveSmoothness: 0.3,
            color: AppColors.gold,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.gold.withValues(alpha: 0.28),
                  AppColors.gold.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoresChart extends StatelessWidget {
  const _ScoresChart({required this.progress});

  final UserProgress progress;

  @override
  Widget build(BuildContext context) {
    final recent = progress.attempts.length > 10
        ? progress.attempts.sublist(progress.attempts.length - 10)
        : progress.attempts;
    final labelStyle = Theme.of(context)
        .textTheme
        .labelSmall
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);

    return BarChart(
      BarChartData(
        minY: 0,
        maxY: 100,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (v) => FlLine(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              interval: 25,
              getTitlesWidget: (v, meta) =>
                  Text('${v.toInt()}%', style: labelStyle),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (var i = 0; i < recent.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: recent[i].scorePct.toDouble(),
                  width: 14,
                  borderRadius: BorderRadius.circular(4),
                  color: recent[i].passed ? AppColors.success : AppColors.danger,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
