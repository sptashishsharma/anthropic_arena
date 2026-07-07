import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/arena_video.dart';
import '../../core/widgets/common.dart';
import '../../state/providers.dart';
import '../auth/login_screen.dart';
import '../home/home_shell.dart';

/// Plays the brand splash video, then routes to login or straight into the
/// arena for returning players. Tapping skips.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigated = false;

  void _continue() {
    if (_navigated || !mounted) return;
    _navigated = true;
    final signedIn = ref.read(authProvider) != null;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            signedIn ? const HomeShell() : const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _continue,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ArenaVideo(
              asset: 'assets/videos/splash.mp4',
              onFinished: _continue,
              fallback: const _StaticSplash(),
            ),
            const Positioned(
              bottom: 28,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Tap to skip',
                  style: TextStyle(color: Color(0x66FFFFFF), fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaticSplash extends StatelessWidget {
  const _StaticSplash();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.ink,
      child: Center(child: BrandMark(size: 140)),
    );
  }
}
