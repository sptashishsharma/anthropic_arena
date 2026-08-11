import 'dart:convert';

import 'package:anthropic_arena/core/widgets/common.dart';
import 'package:anthropic_arena/data/models/player.dart';
import 'package:anthropic_arena/features/home/home_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'widget_test.dart' show pumpFrames, wrap;

/// A real work address of the length that broke the profile header: the
/// provider chip grew past the screen edge because its label neither shrank
/// nor ellipsised.
const _longEmail = 'ankit.shakdweepiya@sptechusa.com';

Future<void> signedInWith(WidgetTester tester, String email) async {
  final player = Player(
    id: 'uid-long-email',
    name: 'Ankit Shakdweepiya',
    tag: '#4191',
    provider: AuthProvider.microsoft,
    email: email,
    joinedIso: DateTime.now().toIso8601String(),
  );
  SharedPreferences.setMockInitialValues({
    'flutter.aa.player': jsonEncode(player.toJson()),
  });
  await tester.pumpWidget(await wrap(const HomeShell()));
  await pumpFrames(tester);
  await tester.tap(find.text('Profile'));
  await pumpFrames(tester);
}

void main() {
  testWidgets('profile header survives a long work email on a small phone',
      (tester) async {
    // Narrow phone: the least room the header will ever get. Layout overflow
    // throws during the frame, so simply rendering is the assertion.
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await signedInWith(tester, _longEmail);

    expect(find.byType(StatChip), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an absurdly long email still cannot overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await signedInWith(
        tester, 'a.very.long.first.and.last.name@some-long-company-domain.com');

    expect(tester.takeException(), isNull);
  });

  testWidgets('StatChip truncates rather than growing past its parent',
      (tester) async {
    // Column, matching how the profile header stacks the chip under the name:
    // it hands children a bounded width, so the chip must fit inside it.
    // (A bare Row would give the chip unbounded width — a caller error, not a
    // StatChip one.)
    const parentWidth = 200.0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: parentWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  StatChip(icon: Icons.mail_rounded, label: _longEmail),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final chip = tester.getSize(find.byType(StatChip));
    expect(chip.width, lessThanOrEqualTo(parentWidth));
    expect(tester.takeException(), isNull);
  });
}
