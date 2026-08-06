import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../gamification/ranks.dart';

/// What a share card shows. Kept deliberately small so any screen (level
/// result, cert result, profile) can build one.
class ShareBrag {
  const ShareBrag({
    required this.headline,
    required this.subtitle,
    required this.playerName,
    required this.xp,
    this.scorePct,
    this.stars,
    this.streakDays,
  });

  final String headline;
  final String subtitle;
  final String playerName;
  final int xp;
  final int? scorePct;
  final int? stars;
  final int? streakDays;

  String get shareText =>
      '$headline — $subtitle\n'
      'I\'m on ${Ranks.forXp(xp).name} rank with $xp XP in Anthropic Arena.\n'
      'Play free: https://anthropic-arena.web.app';
}

/// Renders [brag] to a PNG off-screen and opens the platform share sheet.
/// Falls back to sharing plain text if image capture isn't possible.
Future<void> shareBrag(BuildContext context, ShareBrag brag) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  Uint8List? png;
  try {
    png = await _captureCard(context, brag);
  } catch (_) {
    png = null;
  }

  try {
    if (png != null) {
      await SharePlus.instance.share(
        ShareParams(
          text: brag.shareText,
          files: [
            XFile.fromData(png, mimeType: 'image/png', name: 'arena.png'),
          ],
        ),
      );
    } else {
      await SharePlus.instance.share(ShareParams(text: brag.shareText));
    }
  } catch (_) {
    messenger?.showSnackBar(
      const SnackBar(content: Text('Sharing isn\'t available here.')),
    );
  }
}

/// Paints the card into an off-screen layer tree and rasterises it, so the
/// shared image looks identical everywhere regardless of the live screen.
Future<Uint8List?> _captureCard(BuildContext context, ShareBrag brag) async {
  // Web can rasterise too, but the resulting file share is unreliable across
  // browsers; text-only sharing is the dependable path there.
  if (kIsWeb) return null;

  final boundary = RenderRepaintBoundary();
  final view = View.of(context);
  const size = Size(1080, 1350); // 4:5, the friendliest social aspect

  final renderView = RenderView(
    view: view,
    child: RenderPositionedBox(child: boundary),
    configuration: ViewConfiguration(
      physicalConstraints:
          BoxConstraints.tight(size * view.devicePixelRatio),
      logicalConstraints: BoxConstraints.tight(size),
      devicePixelRatio: view.devicePixelRatio,
    ),
  );

  final pipelineOwner = PipelineOwner()..rootNode = renderView;
  final buildOwner = BuildOwner(focusManager: FocusManager());
  renderView.prepareInitialFrame();

  final element = RenderObjectToWidgetAdapter<RenderBox>(
    container: boundary,
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: MediaQueryData(size: size),
        child: _ShareCard(brag: brag),
      ),
    ),
  ).attachToRenderTree(buildOwner);

  buildOwner
    ..buildScope(element)
    ..finalizeTree();
  pipelineOwner
    ..flushLayout()
    ..flushCompositingBits()
    ..flushPaint();

  final image = await boundary.toImage(pixelRatio: 1);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes?.buffer.asUint8List();
}

/// The visual itself — brand-locked so every shared image looks like Arena.
class _ShareCard extends StatelessWidget {
  const _ShareCard({required this.brag});

  final ShareBrag brag;

  @override
  Widget build(BuildContext context) {
    final tier = Ranks.forXp(brag.xp);
    return Container(
      width: 1080,
      height: 1350,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF14100A), AppColors.ink, Color(0xFF0B1016)],
        ),
      ),
      child: Stack(
        children: [
          // Warm glow behind the crest, echoing the app's neon backdrop.
          Positioned(
            top: -160,
            left: -120,
            child: Container(
              width: 720,
              height: 720,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.gold.withValues(alpha: 0.30),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(90, 96, 90, 84),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const BrandMark(size: 92),
                    const SizedBox(width: 22),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ANTHROPIC ARENA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            )),
                        Text('LEARN · PLAY · COMPETE',
                            style: TextStyle(
                              color: AppColors.gold,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 4,
                            )),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  brag.headline,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 96,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  brag.subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 40,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 46),
                if (brag.stars != null)
                  Row(
                    children: [
                      for (var i = 0; i < 3; i++)
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Icon(
                            i < brag.stars! ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 78,
                            color: i < brag.stars!
                                ? AppColors.gold
                                : Colors.white24,
                          ),
                        ),
                    ],
                  ),
                const Spacer(),
                Row(
                  children: [
                    if (brag.scorePct != null)
                      _Stat(label: 'SCORE', value: '${brag.scorePct}%'),
                    _Stat(label: 'TOTAL XP', value: '${brag.xp}'),
                    if (brag.streakDays != null && brag.streakDays! > 0)
                      _Stat(label: 'STREAK', value: '${brag.streakDays}d'),
                    _Stat(label: 'RANK', value: tier.name, color: tier.color),
                  ],
                ),
                const SizedBox(height: 40),
                Container(height: 2, color: Colors.white12),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      brag.playerName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'anthropic-arena.web.app',
                      style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 32,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 22,
                letterSpacing: 2.5,
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                color: color ?? Colors.white,
                fontSize: 56,
                fontWeight: FontWeight.w800,
              )),
        ],
      ),
    );
  }
}
