class LeaderboardEntry {
  const LeaderboardEntry({
    required this.name,
    required this.tag,
    required this.xp,
    this.isYou = false,
    this.photoUrl,
  });

  final String name;
  final String tag;
  final int xp;
  final bool isYou;

  /// Identity-provider avatar, when the player has one.
  final String? photoUrl;
}

/// Demo standings shown until the Firestore-backed global leaderboard goes
/// live (see FIREBASE_SETUP.md). Names are fictional.
const demoRivals = <LeaderboardEntry>[
  LeaderboardEntry(name: 'Priya V.', tag: '#2381', xp: 1240),
  LeaderboardEntry(name: 'Marcus L.', tag: '#0917', xp: 1105),
  LeaderboardEntry(name: 'Sofia R.', tag: '#4470', xp: 980),
  LeaderboardEntry(name: 'Kenji T.', tag: '#7752', xp: 845),
  LeaderboardEntry(name: 'Amara O.', tag: '#3164', xp: 730),
  LeaderboardEntry(name: 'Diego M.', tag: '#5528', xp: 615),
  LeaderboardEntry(name: 'Lena K.', tag: '#8090', xp: 540),
  LeaderboardEntry(name: 'Ravi S.', tag: '#1246', xp: 435),
  LeaderboardEntry(name: 'Chloe B.', tag: '#6613', xp: 350),
  LeaderboardEntry(name: 'Omar F.', tag: '#9027', xp: 265),
  LeaderboardEntry(name: 'Nina P.', tag: '#3345', xp: 180),
  LeaderboardEntry(name: 'Jack W.', tag: '#0458', xp: 95),
];
