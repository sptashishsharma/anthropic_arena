import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// GitHub-style activity grid over the last [weeks] weeks, coloured by the XP
/// earned each day. Gives long-term consistency a face — a wall of gold squares
/// is far more motivating than a streak counter alone.
class StreakHeatmap extends StatelessWidget {
  const StreakHeatmap({
    super.key,
    required this.xpByDay,
    this.weeks = 14,
    this.cell = 13,
    this.gap = 4,
  });

  /// yyyy-MM-dd -> XP earned that day.
  final Map<String, int> xpByDay;
  final int weeks;
  final double cell;
  final double gap;

  static String _key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final today = DateTime.now();
    // Grid runs Monday..Sunday down each column, oldest column first.
    final lastColumnStart = today.subtract(Duration(days: today.weekday - 1));
    final peak = xpByDay.values.isEmpty
        ? 0
        : xpByDay.values.reduce((a, b) => a > b ? a : b);

    Color colorFor(int xp) {
      if (xp <= 0) return scheme.surfaceContainerHighest.withValues(alpha: 0.35);
      if (peak <= 0) return AppColors.gold;
      final t = (xp / peak).clamp(0.15, 1.0);
      return Color.lerp(
        AppColors.gold.withValues(alpha: 0.28),
        AppColors.goldBright,
        t,
      )!;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true, // keep the most recent weeks in view
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var w = weeks - 1; w >= 0; w--) ...[
            Column(
              children: [
                for (var d = 0; d < 7; d++) ...[
                  Builder(builder: (context) {
                    final date = lastColumnStart
                        .subtract(Duration(days: w * 7))
                        .add(Duration(days: d));
                    final future = date.isAfter(today);
                    final xp = xpByDay[_key(date)] ?? 0;
                    return Padding(
                      padding: EdgeInsets.only(bottom: gap),
                      child: Tooltip(
                        message: future
                            ? ''
                            : '${_key(date)} · $xp XP',
                        child: Container(
                          width: cell,
                          height: cell,
                          decoration: BoxDecoration(
                            color: future
                                ? Colors.transparent
                                : colorFor(xp),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
            SizedBox(width: gap),
          ],
        ],
      ),
    );
  }
}
