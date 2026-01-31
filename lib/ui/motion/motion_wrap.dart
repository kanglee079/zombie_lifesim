import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'motion_config.dart';

class MotionWrap extends StatelessWidget {
  final Widget child;
  final String presetId;
  final bool enabled;

  const MotionWrap({
    super.key,
    required this.child,
    required this.presetId,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    final preset = MotionConfigCache.instance.preset(presetId);

    Animate animate = child
        .animate()
        .fadeIn(duration: preset.durationMs.ms, curve: Curves.easeOut)
        .slideY(begin: preset.slideY, end: 0, duration: preset.durationMs.ms)
        .blur(
          begin: Offset(preset.blur, preset.blur),
          end: Offset.zero,
          duration: preset.durationMs.ms,
        );

    if (preset.shake) {
      animate = animate.shake(
        duration: (preset.durationMs + 120).ms,
        hz: 12,
        curve: Curves.easeInOut,
        offset: const Offset(2, 0),
      );
    }

    if (preset.flicker) {
      animate = animate.fade(
        duration: (preset.durationMs ~/ 2).ms,
        begin: 0.8,
        end: 1.0,
        curve: Curves.easeInOut,
      );
    }

    if (preset.shimmer) {
      animate = animate.shimmer(duration: (preset.durationMs + 200).ms);
    }

    return animate;
  }
}
