import 'dart:convert';
import 'dart:io';

import 'package:anthropic_arena/data/content_repository.dart';
import 'package:anthropic_arena/data/models/course.dart';
import 'package:anthropic_arena/features/auth/login_screen.dart';
import 'package:anthropic_arena/features/home/home_shell.dart';
import 'package:anthropic_arena/state/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reads the bundled content synchronously — rootBundle's real async I/O
/// never completes under the widget test's fake-async clock.
class _FileContentRepository implements ContentRepository {
  @override
  Future<List<Course>> loadCourses() async {
    final raw = File('assets/content/courses.json').readAsStringSync();
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return (json['courses'] as List)
        .map((c) => Course.fromJson((c as Map).cast<String, dynamic>()))
        .toList();
  }
}

Future<Widget> wrap(Widget child) async {
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      prefsProvider.overrideWithValue(prefs),
      contentRepositoryProvider.overrideWithValue(_FileContentRepository()),
    ],
    child: MaterialApp(home: child),
  );
}

/// Pumps a bounded number of frames instead of pumpAndSettle, so screens
/// hosting indeterminate progress indicators can't hang the test.
Future<void> pumpFrames(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('login screen shows all sign-in options', (tester) async {
    await tester.pumpWidget(await wrap(const LoginScreen()));
    expect(find.text('Anthropic Arena'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Microsoft'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);
    expect(find.text('Continue with Email'), findsOneWidget);
    expect(find.text('Play as guest'), findsOneWidget);
  });

  testWidgets('Microsoft sign-in enters the arena as a non-guest account',
      (tester) async {
    await tester.pumpWidget(await wrap(const LoginScreen()));
    await tester.tap(find.text('Continue with Microsoft'));
    await pumpFrames(tester);

    expect(find.byType(HomeShell), findsOneWidget);

    // Microsoft is a real (non-guest) account, so the gated Certifications
    // tab opens its catalogue instead of the sign-in gate. The bottom bar
    // shows the short label so it can't wrap.
    await tester.tap(find.text('Certs'));
    await pumpFrames(tester);
    expect(find.text('Sign in to unlock Certifications'), findsNothing);
  });

  testWidgets('guest sign-in lands on the home shell with 5 tabs',
      (tester) async {
    await tester.pumpWidget(await wrap(const LoginScreen()));
    await tester.tap(find.text('Play as guest'));
    await pumpFrames(tester);

    expect(find.byType(HomeShell), findsOneWidget);
    expect(find.text('Learn'), findsOneWidget);
    // Short label in the bar; "Certifications" in full lives on the tab body,
    // which is also mounted inside the IndexedStack.
    expect(find.text('Certs'), findsOneWidget);
    expect(find.text('Rank'), findsOneWidget);
    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('bottom bar uses short labels and shrinks them on small phones',
      (tester) async {
    // The bar has 5 slots, so a long word like "Certifications" wrapped onto a
    // second line ("Certificatio/ns"). Guard the two things that fixed it: the
    // bar uses short labels, and the label style shrinks on narrow screens.
    //
    // This deliberately does NOT assert rendered line counts: flutter_test's
    // placeholder font is a fixed-width stand-in roughly twice as wide as real
    // Roboto/Inter, so text-fit measurements here don't reflect the shipped
    // app. Actual fit is verified visually against a browser build.
    //
    // setSurfaceSize resizes layout but leaves MediaQuery reporting the old
    // size, which would hide width-dependent logic — set the view metrics.
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(await wrap(const LoginScreen()));
    await tester.tap(find.text('Play as guest'));
    await pumpFrames(tester);

    // No multi-word or long labels in the bar.
    for (final label in ['Learn', 'Certs', 'Rank', 'Stats', 'Profile']) {
      expect(find.text(label), findsOneWidget);
      expect(label.length, lessThanOrEqualTo(7));
    }
    expect(find.text('Certifications'), findsNothing,
        reason: 'the long form belongs on the tab body, not the bar');

    // And the labels are scaled down at this width.
    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    final scaled = bar.labelTextStyle?.resolve({})?.fontSize;
    final unscaled = Theme.of(tester.element(find.byType(NavigationBar)))
        .textTheme
        .labelMedium
        ?.fontSize;
    expect(scaled, isNotNull);
    expect(scaled!, lessThan(unscaled ?? 12));
  });

  testWidgets('learning tab lists the bundled courses', (tester) async {
    await tester.pumpWidget(await wrap(const LoginScreen()));
    await tester.tap(find.text('Play as guest'));
    await pumpFrames(tester);

    expect(find.text('Claude Foundations'), findsOneWidget);
    expect(find.text('Prompting Mastery'), findsOneWidget);
  });
}
