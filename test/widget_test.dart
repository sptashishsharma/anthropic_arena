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
    expect(find.text('Continue with Apple'), findsOneWidget);
    expect(find.text('Continue with Email'), findsOneWidget);
    expect(find.text('Play as guest'), findsOneWidget);
  });

  testWidgets('guest sign-in lands on the home shell with 4 tabs',
      (tester) async {
    await tester.pumpWidget(await wrap(const LoginScreen()));
    await tester.tap(find.text('Play as guest'));
    await pumpFrames(tester);

    expect(find.byType(HomeShell), findsOneWidget);
    expect(find.text('Learn'), findsOneWidget);
    expect(find.text('Ranking'), findsOneWidget);
    expect(find.text('Analysis'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('learning tab lists the bundled courses', (tester) async {
    await tester.pumpWidget(await wrap(const LoginScreen()));
    await tester.tap(find.text('Play as guest'));
    await pumpFrames(tester);

    expect(find.text('Claude Foundations'), findsOneWidget);
    expect(find.text('Prompting Mastery'), findsOneWidget);
  });
}
