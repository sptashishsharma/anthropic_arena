import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'glass.dart';

/// The shield crest, transparent PNG; gold variant pops on dark surfaces.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 96, this.gold = true});

  final double size;
  final bool gold;

  @override
  Widget build(BuildContext context) => Image.asset(
        gold
            ? 'assets/images/anthropic-arena-mark-gold-1024.png'
            : 'assets/images/anthropic-arena-mark-dark-1024.png',
        width: size,
        height: size,
        filterQuality: FilterQuality.medium,
      );
}

class ArenaCard extends StatelessWidget {
  const ArenaCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.borderColor,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    // Frosted-glass panel: a translucent tinted fill over a backdrop blur,
    // with a hairline light border. A caller-supplied [borderColor] (e.g. the
    // gold "this is you" highlight) also casts a matching neon glow.
    // GlassSurface itself supplies the press-scale + haptic for tappable
    // cards, so every card in the app gets that feedback for free.
    return GlassSurface(
      padding: padding,
      onTap: onTap,
      fill: color,
      borderColor: borderColor,
      glow: borderColor,
      glowAlpha: 0.22,
      child: child,
    );
  }
}

/// Small pill with an icon + value, used for XP / streak / accuracy chips.
class StatChip extends StatelessWidget {
  const StatChip({
    super.key,
    required this.icon,
    required this.label,
    this.color = AppColors.gold,
    this.tooltip,
  });

  final IconData icon;
  final String label;
  final Color color;

  /// Shown on hover/long-press. Worth setting wherever [label] can be
  /// truncated (e.g. a long work email) so the full value stays reachable.
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final chip = _build(context);
    if (tooltip == null) return chip;
    return Tooltip(message: tooltip!, child: chip);
  }

  Widget _build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.22),
            blurRadius: 12,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          // Flexible + ellipsis: long values (work email addresses especially)
          // otherwise force the chip wider than its parent and spill off the
          // edge of the screen.
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.stars, this.size = 20, this.max = 3});

  final int stars;
  final double size;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < max; i++)
          Icon(
            i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: i < stars
                ? AppColors.gold
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
      ],
    );
  }
}

/// Circular avatar: the identity provider's photo when there is one, falling
/// back to the player's initial on the gold gradient. A broken/blocked photo
/// URL silently falls back too, so this never shows a broken image.
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    super.key,
    required this.initial,
    this.size = 44,
    this.photoUrl,
    this.ring,
  });

  final String initial;
  final double size;
  final String? photoUrl;

  /// Optional accent ring drawn around the avatar (rank tier / "this is you").
  final Color? ring;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.goldBright, AppColors.gold],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: AppColors.ink,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.42,
        ),
      ),
    );

    final avatar = photoUrl == null || photoUrl!.isEmpty
        ? fallback
        : ClipOval(
            child: Image.network(
              photoUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback,
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : fallback,
            ),
          );

    if (ring == null) return avatar;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ring!, width: 2),
        boxShadow: [
          BoxShadow(
            color: ring!.withValues(alpha: 0.35),
            blurRadius: 10,
            spreadRadius: -2,
          ),
        ],
      ),
      child: avatar,
    );
  }
}

/// Simple progress bar with rounded caps and a gold fill.
class ArenaProgressBar extends StatelessWidget {
  const ArenaProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.color = AppColors.gold,
  });

  final double value;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: height,
        backgroundColor:
            Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}

/// Placeholder block with a travelling sheen, shown while real content loads
/// so the first paint has structure instead of a lone spinner.
class SkeletonBlock extends StatefulWidget {
  const SkeletonBlock({
    super.key,
    this.height = 100,
    this.width,
    this.radius = 20,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  State<SkeletonBlock> createState() => _SkeletonBlockState();
}

class _SkeletonBlockState extends State<SkeletonBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHighest.withValues(alpha: 0.45);
    final sheen = scheme.onSurface.withValues(alpha: 0.06);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.35)),
          gradient: LinearGradient(
            colors: [base, sheen, base],
            stops: const [0.0, 0.5, 1.0],
            begin: Alignment(-1.6 + 3.2 * _controller.value, -0.3),
            end: Alignment(-0.6 + 3.2 * _controller.value, 0.3),
          ),
        ),
      ),
    );
  }
}

/// Section header used across tabs.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.headlineSmall),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
