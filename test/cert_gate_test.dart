import 'package:anthropic_arena/features/auth/login_screen.dart';
import 'package:anthropic_arena/features/home/home_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'widget_test.dart' show wrap, pumpFrames;

/// Signs in as a guest and opens the (locked) Certifications tab.
///
/// [surface] sets the viewport first: the gate's whole failure mode was content
/// falling below the fold on a short window, where the bottom NavigationBar
/// then swallowed the tap, so viewport size is part of the contract here.
Future<void> guestOnCertTab(WidgetTester tester, {Size? surface}) async {
  // Make a tap that lands on the wrong widget fail instead of just warn.
  WidgetController.hitTestWarningShouldBeFatal = true;
  if (surface != null) {
    await tester.binding.setSurfaceSize(surface);
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }
  await tester.pumpWidget(await wrap(const LoginScreen()));
  await tester.tap(find.text('Play as guest'));
  await pumpFrames(tester);
  // The bottom bar uses the short label ("Certs") so it can't wrap; the full
  // word only appears in the tab's own heading.
  await tester.tap(find.text('Certs'));
  await pumpFrames(tester);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('guest sees the sign-in gate with sign-in options in place',
      (tester) async {
    await guestOnCertTab(tester);

    expect(find.text('Sign in to unlock Certifications'), findsOneWidget);
    // The real sign-in actions live on the gate itself, so unlocking the tab
    // never depends on a route push.
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);
    expect(find.text('Continue with Email'), findsOneWidget);
    // A guest signing in "as guest" again would leave the tab locked.
    expect(find.text('Play as guest'), findsNothing);
  });

  // The regression: every control on the gate must be genuinely hittable
  // without scrolling, at the small viewports where the card is tightest.
  for (final size in const [Size(360, 640), Size(800, 600), Size(412, 732)]) {
    testWidgets('gate controls are tappable at ${size.width}x${size.height}',
        (tester) async {
      await guestOnCertTab(tester, surface: size);

      // Apple is the local demo path, so it completes without a network call.
      // A tap stolen by the nav bar (the original bug) fails this outright.
      await tester.tap(find.text('Continue with Apple'));
      await pumpFrames(tester);

      // Unlocked in place: same shell, no navigation involved.
      expect(find.byType(HomeShell), findsOneWidget);
      expect(find.text('Sign in to unlock Certifications'), findsNothing);
    });
  }

  testWidgets('the secondary link opens the full sign-in page', (tester) async {
    await guestOnCertTab(tester, surface: const Size(360, 640));

    await tester.tap(find.text('Open the full sign-in page'));
    await pumpFrames(tester);

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Play as guest'), findsOneWidget);
  });
}
