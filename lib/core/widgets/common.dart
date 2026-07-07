import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

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
    final scheme = Theme.of(context).colorScheme;
    // The Material sits inside the decorated box so ink splashes (and
    // ListTile backgrounds) paint correctly on top of the card colour.
    return Container(
      decoration: BoxDecoration(
        color: color ?? scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor ?? scheme.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: onTap == null
            ? Padding(padding: padding, child: child)
            : InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(20),
                child: Padding(padding: padding, child: child),
              ),
      ),
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
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
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

/// Circular avatar with the player's initial.
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({super.key, required this.initial, this.size = 44});

  final String initial;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
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
