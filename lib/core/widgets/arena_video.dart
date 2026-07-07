import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Plays a bundled brand video (splash, loader, level-complete, offline).
///
/// Degrades gracefully: if the platform can't play the asset (e.g. missing
/// codec), [fallback] is shown and [onFinished] still fires after
/// [fallbackDuration].
class ArenaVideo extends StatefulWidget {
  const ArenaVideo({
    super.key,
    required this.asset,
    this.onFinished,
    this.loop = false,
    this.fit = BoxFit.contain,
    this.fallback,
    this.fallbackDuration = const Duration(milliseconds: 1800),
  });

  final String asset;
  final VoidCallback? onFinished;
  final bool loop;
  final BoxFit fit;
  final Widget? fallback;
  final Duration fallbackDuration;

  @override
  State<ArenaVideo> createState() => _ArenaVideoState();
}

class _ArenaVideoState extends State<ArenaVideo> {
  VideoPlayerController? _controller;
  bool _failed = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final controller = VideoPlayerController.asset(widget.asset);
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted) return;
      controller.setLooping(widget.loop);
      controller.setVolume(0); // brand videos are silent visuals
      if (!widget.loop && widget.onFinished != null) {
        controller.addListener(_checkFinished);
      }
      await controller.play();
      setState(() {});
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
      if (widget.onFinished != null) {
        Future.delayed(widget.fallbackDuration, () {
          if (mounted && !_finished) {
            _finished = true;
            widget.onFinished!();
          }
        });
      }
    }
  }

  void _checkFinished() {
    final c = _controller;
    if (c == null || _finished) return;
    final value = c.value;
    if (value.isInitialized &&
        !value.isPlaying &&
        value.position >= value.duration &&
        value.duration > Duration.zero) {
      _finished = true;
      widget.onFinished?.call();
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_checkFinished);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_failed || controller == null || !controller.value.isInitialized) {
      return widget.fallback ?? const SizedBox.expand();
    }
    return FittedBox(
      fit: widget.fit,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: controller.value.size.width,
        height: controller.value.size.height,
        child: VideoPlayer(controller),
      ),
    );
  }
}
