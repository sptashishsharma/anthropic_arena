import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/layout.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/glass.dart';
import '../../data/models/player.dart';
import '../../state/providers.dart';
import '../analysis/analysis_tab.dart';
import '../certification/certification_tab.dart';
import '../learn/learn_tab.dart';
import '../profile/profile_tab.dart';
import '../ranking/ranking_tab.dart';

/// One entry in both the bottom bar and the wide-screen rail.
class _Destination {
  const _Destination({
    required this.label,
    required this.shortLabel,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;

  /// Used where horizontal room is tight (the 5-slot bottom bar on a phone),
  /// so "Certifications" can't wrap to a second line.
  final String shortLabel;
  final IconData icon;
  final IconData selectedIcon;
}

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  static const _tabs = [
    LearnTab(),
    CertificationTab(),
    RankingTab(),
    AnalysisTab(),
    ProfileTab(),
  ];

  List<_Destination> _destinations(bool signedIn) => [
        const _Destination(
          label: 'Learn',
          shortLabel: 'Learn',
          icon: Icons.school_outlined,
          selectedIcon: Icons.school_rounded,
        ),
        _Destination(
          label: 'Certifications',
          shortLabel: 'Certs',
          icon: signedIn ? Icons.workspace_premium_outlined : Icons.lock_outline,
          selectedIcon:
              signedIn ? Icons.workspace_premium_rounded : Icons.lock_rounded,
        ),
        const _Destination(
          label: 'Ranking',
          shortLabel: 'Rank',
          icon: Icons.leaderboard_outlined,
          selectedIcon: Icons.leaderboard_rounded,
        ),
        const _Destination(
          label: 'Analysis',
          shortLabel: 'Stats',
          icon: Icons.insights_outlined,
          selectedIcon: Icons.insights_rounded,
        ),
        const _Destination(
          label: 'Profile',
          shortLabel: 'Profile',
          icon: Icons.person_outline_rounded,
          selectedIcon: Icons.person_rounded,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(authProvider);
    // Certifications are gated behind a real account. Guest play (anonymous)
    // does not unlock the certification exam banks.
    final signedIn = player != null && player.provider != AuthProvider.guest;
    final destinations = _destinations(signedIn);
    final wide = Breakpoints.isWide(context);

    final tabs = IndexedStack(index: _index, children: _tabs);

    if (wide) {
      // Desktop/tablet-landscape: a persistent rail with the brand mark, so the
      // window doesn't just look like a stretched phone. The aurora spans the
      // whole window (not just the content pane) so the translucent rail has
      // something dark to sit on.
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: NeonBackground(
          accent: AppColors.gold,
          child: Row(
            children: [
              _ArenaRail(
                index: _index,
                destinations: destinations,
                onSelected: (i) => setState(() => _index = i),
                player: player,
              ),
              Expanded(child: tabs),
            ],
          ),
        ),
      );
    }

    final content = NeonBackground(
      accent: AppColors.gold,
      child: tabs,
    );

    // Five slots on a 320pt phone leave ~48pt per label, which is narrower
    // than "Profile" at the theme's default size — shrink the label a little
    // rather than let it wrap onto a second line.
    final width = MediaQuery.sizeOf(context).width;
    final labelScale = width < 340
        ? 0.82
        : width < 380
            ? 0.9
            : 1.0;
    final navTheme = Theme.of(context).navigationBarTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: content,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        // NavigationBar clamps text scaling internally and builds its own
        // label Text, so the widget-level labelTextStyle is the only hook
        // that reliably shrinks the label. It takes precedence over the theme.
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final base = navTheme.labelTextStyle?.resolve(states) ??
              Theme.of(context).textTheme.labelMedium ??
              const TextStyle(fontSize: 12);
          return base.copyWith(fontSize: (base.fontSize ?? 12) * labelScale);
        }),
        destinations: [
          for (final d in destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.shortLabel,
              tooltip: d.label,
            ),
        ],
      ),
    );
  }
}

class _ArenaRail extends StatelessWidget {
  const _ArenaRail({
    required this.index,
    required this.destinations,
    required this.onSelected,
    required this.player,
  });

  final int index;
  final List<_Destination> destinations;
  final ValueChanged<int> onSelected;
  final Player? player;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Extend the rail (icon + label side by side) only when there is plenty of
    // room; below that keep it compact so content keeps the space.
    final extended = MediaQuery.sizeOf(context).width >= 1180;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        // Deepen rather than lighten in dark mode, so the rail reads as a
        // recessed panel instead of a pale slab.
        color: isDark
            ? AppColors.ink.withValues(alpha: 0.62)
            : Colors.white.withValues(alpha: 0.62),
        border: Border(
          right: BorderSide(color: scheme.outline.withValues(alpha: 0.6)),
        ),
      ),
      child: SafeArea(
        right: false,
        child: NavigationRail(
          backgroundColor: Colors.transparent,
          selectedIndex: index,
          onDestinationSelected: onSelected,
          extended: extended,
          minWidth: 84,
          minExtendedWidth: 216,
          leading: Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 20),
            child: Column(
              children: [
                const BrandMark(size: 44),
                if (extended) ...[
                  const SizedBox(height: 10),
                  Text('Anthropic Arena',
                      style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    'LEARN · PLAY · COMPETE',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.gold,
                          letterSpacing: 1.6,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ],
            ),
          ),
          trailing: player == null
              ? null
              : Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: PlayerAvatar(
                        initial: player!.initial,
                        photoUrl: player!.photoUrl,
                        size: 40,
                      ),
                    ),
                  ),
                ),
          destinations: [
            for (final d in destinations)
              NavigationRailDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: Text(d.label),
              ),
          ],
        ),
      ),
    );
  }
}
