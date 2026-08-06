import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass.dart';
import '../../state/providers.dart';
import 'login_screen.dart';

/// Three-card intro shown once, before the very first sign-in. Answers "what
/// is this and why should I care" so the login screen isn't the first thing a
/// brand-new user has to interpret.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    (
      icon: Icons.school_rounded,
      color: AppColors.gold,
      title: 'Learn by playing',
      body:
          'Anthropic and Salesforce skills broken into short, quick-fire levels. '
          'Answer questions, get instant feedback, actually remember it.',
    ),
    (
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFFF7A45),
      title: 'Build a streak',
      body:
          'Earn XP for every correct answer, collect stars and badges, and climb '
          'the rank tiers from Recruit to Legend.',
    ),
    (
      icon: Icons.emoji_events_rounded,
      color: AppColors.info,
      title: 'Compete worldwide',
      body:
          'Every signed-in player shares one live global leaderboard. '
          'Practise timed certification exams while you\'re at it.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(onboardingSeenProvider.notifier).markSeen();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final last = _page == _pages.length - 1;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: NeonBackground(
        accent: _pages[_page].color,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextButton(
                        onPressed: _finish,
                        child: const Text('Skip'),
                      ),
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: _pages.length,
                      onPageChanged: (i) => setState(() => _page = i),
                      itemBuilder: (context, i) {
                        final p = _pages[i];
                        return Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 132,
                                height: 132,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: p.color.withValues(alpha: 0.16),
                                  border: Border.all(
                                      color: p.color.withValues(alpha: 0.6),
                                      width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: p.color.withValues(alpha: 0.35),
                                      blurRadius: 40,
                                      spreadRadius: -6,
                                    ),
                                  ],
                                ),
                                child:
                                    Icon(p.icon, size: 62, color: p.color),
                              ),
                              const SizedBox(height: 36),
                              Text(p.title,
                                  textAlign: TextAlign.center,
                                  style: textTheme.displaySmall),
                              const SizedBox(height: 14),
                              Text(
                                p.body,
                                textAlign: TextAlign.center,
                                style: textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _pages.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _page ? 26 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _page
                                ? _pages[_page].color
                                : Theme.of(context).colorScheme.outline,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: FilledButton(
                      onPressed: last
                          ? _finish
                          : () => _controller.nextPage(
                                duration: const Duration(milliseconds: 320),
                                curve: Curves.easeOutCubic,
                              ),
                      child: Text(last ? 'Enter the arena' : 'Next'),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
