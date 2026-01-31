import 'dart:math';
import 'package:flutter/material.dart';

class TerminalOverlay extends StatelessWidget {
  final double intensity;

  const TerminalOverlay({super.key, required this.intensity});

  @override
  Widget build(BuildContext context) {
    if (intensity <= 0) return const SizedBox.shrink();
    return IgnorePointer(
      ignoring: true,
      child: CustomPaint(
        painter: _TerminalOverlayPainter(intensity),
        size: Size.infinite,
      ),
    );
  }
}

class _TerminalOverlayPainter extends CustomPainter {
  final double intensity;
  final Random rng = Random(42);

  _TerminalOverlayPainter(this.intensity);

  @override
  void paint(Canvas canvas, Size size) {
    final clamped = intensity.clamp(0.0, 1.0);

    // Vignette
    final rect = Offset.zero & size;
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          Colors.black.withOpacity(0.45 * clamped),
        ],
        stops: const [0.55, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, vignettePaint);

    // Scanlines
    final linePaint = Paint()
      ..color = Colors.black.withOpacity(0.25 * clamped)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Noise dots
    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.04 * clamped);
    final dotCount = (size.width * size.height * 0.001 * clamped).toInt();
    for (int i = 0; i < dotCount; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      canvas.drawRect(Rect.fromLTWH(x, y, 1, 1), dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TerminalOverlayPainter oldDelegate) {
    return oldDelegate.intensity != intensity;
  }
}
