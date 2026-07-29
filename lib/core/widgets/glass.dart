import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A frosted-glass surface: real backdrop blur, a translucent tinted fill,
/// a hairline light border and an optional neon glow. This is the building
/// block for the app's glassmorphism look — drop it in place of a solid
/// card/panel anywhere.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
    this.blur = 16,
    this.onTap,
    this.glow,
    this.glowAlpha = 0.28,
    this.borderColor,
    this.fill,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;
  final VoidCallback? onTap;

  /// Neon glow colour cast around the surface. Null = no glow.
  final Color? glow;
  final double glowAlpha;
  final Color? borderColor;
  final Color? fill;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shape = BorderRadius.circular(radius);

    final tintTop =
        fill ?? (isDark ? AppColors.glassFillDark : AppColors.glassFillLight);
    final tintBottom = (fill ?? Colors.white)
        .withValues(alpha: isDark ? 0.02 : 0.18);
    final border = borderColor ??
        (glow ?? Colors.white).withValues(
          alpha: glow != null ? 0.55 : (isDark ? 0.20 : 0.35),
        );

    Widget content = Material(
      color: Colors.transparent,
      child: onTap == null
          ? Padding(padding: padding, child: child)
          : InkWell(
              onTap: onTap,
              borderRadius: shape,
              child: Padding(padding: padding, child: child),
            ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: glow == null
            ? null
            : [
                BoxShadow(
                  color: glow!.withValues(alpha: glowAlpha),
                  blurRadius: 28,
                  spreadRadius: -3,
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: shape,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: shape,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [tintTop, tintBottom],
              ),
              border: Border.all(color: border, width: 1.2),
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// Slowly drifting neon "aurora" backdrop. Paints a dark (or light) base
/// gradient with a few soft, animated colour orbs behind [child]. Cheap:
/// it's radial gradients on a canvas, no per-frame blur.
class NeonBackground extends StatefulWidget {
  const NeonBackground({
    super.key,
    required this.child,
    this.accent = AppColors.gold,
  });

  final Widget child;

  /// Primary orb colour — pass the course colour so each course's map has
  /// its own tint while staying within the brand palette.
  final Color accent;

  @override
  State<NeonBackground> createState() => _NeonBackgroundState();
}

class _NeonBackgroundState extends State<NeonBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => CustomPaint(
        painter: _NeonPainter(
          t: _c.value,
          accent: widget.accent,
          isDark: isDark,
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}

class _NeonPainter extends CustomPainter {
  _NeonPainter({required this.t, required this.accent, required this.isDark});

  final double t;
  final Color accent;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final base = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? const [Color(0xFF090B0F), Color(0xFF0E1119), Color(0xFF090B0F)]
            : const [Color(0xFFF4F5F7), Color(0xFFEEF0F5), Color(0xFFF4F5F7)],
      ).createShader(rect);
    canvas.drawRect(rect, base);

    void orb(double cx, double cy, double r, Color c) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [c, c.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }

    final tau = t * 2 * pi;
    final w = size.width;
    final h = size.height;
    final a = isDark ? 0.24 : 0.12;

    orb(w * (0.24 + 0.10 * sin(tau)), h * (0.16 + 0.05 * cos(tau)),
        w * 0.75, accent.withValues(alpha: a));
    orb(w * (0.86 + 0.08 * cos(tau * 0.8)), h * (0.44 + 0.06 * sin(tau * 1.2)),
        w * 0.62, AppColors.gold.withValues(alpha: a * 0.9));
    orb(w * (0.14 + 0.10 * sin(tau * 1.3)), h * (0.82 + 0.05 * cos(tau)),
        w * 0.68, AppColors.info.withValues(alpha: a * 0.65));
  }

  @override
  bool shouldRepaint(_NeonPainter old) =>
      old.t != t || old.accent != accent || old.isDark != isDark;
}
