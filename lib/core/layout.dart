import 'package:flutter/material.dart';

/// Breakpoints. The app is phone-first; wider canvases get a rail instead of a
/// bottom bar and stop letting content stretch to the window edge.
abstract final class Breakpoints {
  /// At or above this width, use a side rail and multi-column content.
  static const wide = 900.0;

  /// Tablet-ish: still a bottom bar, but content is centred and gridded.
  static const medium = 640.0;

  /// Widest a column of content is allowed to get, so text lines stay readable
  /// on a desktop monitor.
  static const contentMaxWidth = 1080.0;

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= wide;

  static bool isMedium(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= medium;

  /// How many columns of cards fit comfortably.
  static int columns(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 1280) return 3;
    if (w >= medium) return 2;
    return 1;
  }
}

/// Centres a tab's content and caps its width on large screens, leaving phone
/// layouts untouched.
class ContentShell extends StatelessWidget {
  const ContentShell({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.contentMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      );
}

/// Lays children out in one column on phones and a responsive grid above the
/// medium breakpoint. Unlike GridView this keeps rows at their natural height,
/// so cards with different text lengths don't get clipped or over-padded.
class ResponsiveCardGrid extends StatelessWidget {
  const ResponsiveCardGrid({
    super.key,
    required this.children,
    this.spacing = 14,
  });

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final columns = Breakpoints.columns(context);
    if (columns == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: spacing),
            children[i],
          ],
        ],
      );
    }

    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final slice = children.sublist(
        i,
        (i + columns).clamp(0, children.length),
      );
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var c = 0; c < columns; c++) ...[
                if (c > 0) SizedBox(width: spacing),
                Expanded(
                  child: c < slice.length ? slice[c] : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) SizedBox(height: spacing),
          rows[i],
        ],
      ],
    );
  }
}
