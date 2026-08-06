import 'dart:convert';

import 'package:anthropic_arena/data/leaderboard.dart';
import 'package:anthropic_arena/data/models/player.dart';
import 'package:anthropic_arena/data/models/progress.dart';
import 'package:anthropic_arena/state/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A container seeded with a signed-in (non-guest) player holding [xp].
/// Firebase is off under test, so `demoRivals` backs the board.
Future<ProviderContainer> boardWith({required int xp}) async {
  final player = Player(
    id: 'uid-1',
    name: 'Me',
    tag: '#1234',
    provider: AuthProvider.microsoft,
    joinedIso: DateTime.now().toIso8601String(),
  );
  SharedPreferences.setMockInitialValues({
    'flutter.aa.player': jsonEncode(player.toJson()),
    'flutter.aa.progress': jsonEncode(UserProgress(xp: xp).toJson()),
  });
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [prefsProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('your own row is ranked by score, not appended to the bottom', () async {
    // Regression: the local row used to be spliced in *after* sorting, pinning
    // you to last place no matter how much XP you had.
    final container = await boardWith(xp: 99999);
    final board = container.read(leaderboardProvider);

    expect(board.first.isYou, isTrue);
    expect(board.first.xp, 99999);
  });

  test('a mid-table score lands in the right slot', () async {
    final container = await boardWith(xp: 700);
    final board = container.read(leaderboardProvider);

    final me = board.indexWhere((e) => e.isYou);
    expect(me, greaterThan(0), reason: 'rivals above 700 XP exist');
    expect(board[me - 1].xp, greaterThanOrEqualTo(700));
    expect(board.sublist(me + 1).every((e) => e.xp <= 700), isTrue);
  });

  test('players with no score are hidden so the board is never a wall of zeroes',
      () async {
    final container = await boardWith(xp: 0);
    final board = container.read(leaderboardProvider);

    // You still appear (so the tab isn't empty right after signing in), but
    // nobody else on zero does.
    expect(board.where((e) => !e.isYou).every((e) => e.xp > 0), isTrue);
    expect(demoRivals.every((e) => e.xp > 0), isTrue);
  });

  test('weekly scope ranks on the rolling 7-day total', () async {
    final container = await boardWith(xp: 5000);
    container
        .read(leaderboardScopeProvider.notifier)
        .set(LeaderboardScope.week);

    final board = container.read(leaderboardProvider);
    final me = board.firstWhere((e) => e.isYou);
    // No XP was recorded on any day, so the weekly figure is 0 even though the
    // all-time total is high.
    expect(me.xp, 0);
  });
}
