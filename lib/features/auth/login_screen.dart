import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/glass.dart';
import '../../state/providers.dart';
import '../home/home_shell.dart';
import 'sign_in_options.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  void _enterArena(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeShell()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final firebaseReady = ref.watch(firebaseReadyProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: NeonBackground(
        accent: AppColors.gold,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: BrandMark(size: 118)),
                    const SizedBox(height: 22),
                    Text(
                      'Anthropic Arena',
                      textAlign: TextAlign.center,
                      style: textTheme.displaySmall
                          ?.copyWith(color: AppColors.cream),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'LEARN · PLAY · COMPETE',
                      textAlign: TextAlign.center,
                      style: textTheme.labelLarge?.copyWith(
                        color: AppColors.gold,
                        letterSpacing: 3.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 40),
                    SignInOptions(onSignedIn: () => _enterArena(context)),
                    const SizedBox(height: 12),
                    Text(
                      firebaseReady
                          ? 'Signed-in players compete on the global leaderboard. '
                              'Guest progress stays on this device.'
                          : 'Your progress is saved on this device. Sign in when '
                              'the global arena goes live to compete worldwide.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall
                          ?.copyWith(color: const Color(0xFF77808F)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
