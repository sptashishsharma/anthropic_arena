import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass.dart';
import '../../data/models/player.dart';
import '../../state/providers.dart';
import '../analysis/analysis_tab.dart';
import '../certification/certification_tab.dart';
import '../learn/learn_tab.dart';
import '../profile/profile_tab.dart';
import '../ranking/ranking_tab.dart';

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

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(authProvider);
    // Certifications are gated behind a real account. Guest play (anonymous)
    // does not unlock the certification exam banks.
    final signedIn = player != null && player.provider != AuthProvider.guest;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: NeonBackground(
        accent: AppColors.gold,
        child: IndexedStack(index: _index, children: _tabs),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school_rounded),
            label: 'Learn',
          ),
          NavigationDestination(
            icon: Icon(signedIn
                ? Icons.workspace_premium_outlined
                : Icons.lock_outline),
            selectedIcon: Icon(signedIn
                ? Icons.workspace_premium_rounded
                : Icons.lock_rounded),
            label: 'Certifications',
          ),
          const NavigationDestination(
            icon: Icon(Icons.leaderboard_outlined),
            selectedIcon: Icon(Icons.leaderboard_rounded),
            label: 'Ranking',
          ),
          const NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Analysis',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
