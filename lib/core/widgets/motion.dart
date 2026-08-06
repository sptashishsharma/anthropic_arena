import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Light touch feedback. No-ops on web and desktop, where there is no haptic
/// engine and the calls would just be wasted plugin traffic.
abstract final class Haptics {
  static bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static void tap() {
    if (_supported) HapticFeedback.selectionClick();
  }

  static void success() {
    if (_supported) HapticFeedback.mediumImpact();
  }

  static void failure() {
    if (_supported) HapticFeedback.vibrate();
  }

  static void celebrate() {
    if (_supported) HapticFeedback.heavyImpact();
  }
}

/// Scales its child down slightly while pressed. Wrapping taps in this makes
/// the whole UI feel physical rather than static.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.97,
    this.haptic = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool haptic;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: () {
        if (widget.haptic) Haptics.tap();
        widget.onTap!();
      },
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Fades + slides its child in, staggered by [index] so a list assembles
/// itself instead of appearing all at once.
class EntranceFade extends StatelessWidget {
  const EntranceFade({
    super.key,
    required this.child,
    this.index = 0,
    this.offsetY = 14,
    this.stagger = const Duration(milliseconds: 55),
    this.duration = const Duration(milliseconds: 420),
  });

  final Widget child;
  final int index;
  final double offsetY;
  final Duration stagger;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    // Cap the stagger so long lists don't leave later items visibly late.
    final delay = stagger * (index.clamp(0, 8));
    return TweenAnimationBuilder<double>(
      key: ValueKey(index),
      tween: Tween(begin: 0, end: 1),
      duration: duration + delay,
      curve: Interval(
        delay.inMilliseconds / (duration + delay).inMilliseconds,
        1,
        curve: Curves.easeOutCubic,
      ),
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, offsetY * (1 - t)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
