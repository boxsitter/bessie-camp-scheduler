import 'dart:math';

import 'package:flutter/material.dart';

/// The default blend mode for radiance effects.
const BlendMode kRadianceBlendMode = BlendMode.plus;

class Radiance extends StatelessWidget {
  const Radiance({
    super.key,
    this.child,
    required this.shapePath,
    required this.intensity,
    required this.spread,
    required this.color,
    this.blendMode = kRadianceBlendMode,
    this.clip = false,
    this.passes = 1,
    this.falloffCurve = Curves.easeOut,
    this.ditherOpacity = 0.0,
  }) : assert(passes > 0, 'The number of passes must be greater than 0.');

  /// The widget below this widget in the tree.
  final Widget? child;

  /// The [Path] that defines the shape of the radiance.
  final Path shapePath;

  /// The total opacity of the radiance. This value is distributed among the passes.
  final double intensity;

  /// The maximum "spread" or blur radius of the radiance.
  final double spread;

  /// The color of the radiance.
  final Color color;

  /// The [BlendMode] to use when drawing the radiance.
  final BlendMode blendMode;

  /// Whether to clip the radiance effect to the [shapePath].
  final bool clip;

  /// The number of layers to use when painting the glow.
  /// More passes can create a smoother, richer glow at the cost of performance.
  final int passes;

  /// The curve that determines the spread distribution across multiple passes.
  /// This only has an effect when `passes` > 1.
  final Curve falloffCurve;

  /// The opacity of the dithering noise layer.
  /// A small value like 0.02 can help reduce color banding.
  /// Defaults to 0.0 (disabled).
  final double ditherOpacity;

  @override
  Widget build(BuildContext context) {
    final List<Widget> layers = [];

    // --- Glow Pass Layers ---
    if (passes == 1) {
      layers.add(
        CustomPaint(
      painter: RadiancePainter(
        shapePath: shapePath,
        intensity: intensity,
        spread: spread,
        color: color,
        blendMode: blendMode,
      ),
        ),
    );
    } else {
    final double passIntensity = intensity / passes;
    for (int i = 1; i <= passes; i++) {
      final double passSpread = spread * falloffCurve.transform(i / passes);
      layers.add(
        CustomPaint(
          painter: RadiancePainter(
            shapePath: shapePath,
            intensity: passIntensity,
            spread: passSpread,
            color: color,
            blendMode: blendMode,
          ),
        ),
      );
    }
    }

    // --- Dither Layer ---
    if (ditherOpacity > 0) {
      layers.add(
        // This forces the dither painter to fill the entire area.
        Positioned.fill(
          child: Opacity(
          opacity: ditherOpacity.clamp(0.0, 1.0),
          child: CustomPaint(
            painter: _DitherPainter(),
          ),
        ),
        ),
      );
    }

    // --- Child Layer ---
    if (child != null) {
      layers.add(child!);
    }

    final effectStack = Stack(
      children: layers,
    );

    if (clip) {
      return ClipPath(
        clipper: _PathClipper(shapePath),
        child: effectStack,
      );
    }

    return effectStack;
  }
}

class RadiancePainter extends CustomPainter {
  const RadiancePainter({
    required this.shapePath,
    required this.intensity,
    required this.spread,
    required this.color,
    required this.blendMode,
  });

  final Path shapePath;
  final double intensity;
  final double spread;
  final Color color;
  final BlendMode blendMode;

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0.0 || spread <= 0.0) {
      return;
    }

    final paint = Paint()
      ..color = color.withOpacity(intensity.clamp(0.0, 1.0))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, spread * 0.75)
      ..blendMode = blendMode;

    canvas.drawPath(shapePath, paint);
  }

  @override
  bool shouldRepaint(covariant RadiancePainter oldDelegate) {
    return oldDelegate.shapePath != shapePath ||
        oldDelegate.intensity != intensity ||
        oldDelegate.spread != spread ||
        oldDelegate.color != color ||
        oldDelegate.blendMode != blendMode;
  }
}

/// A simple painter that adds noise to reduce color banding.
class _DitherPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // The painter now uses a solid color. The final opacity is controlled
    // entirely by the Opacity widget wrapper.
    final paint = Paint()..color = Colors.black;
    final random = Random(1337);
    final dotCount = (size.width * size.height * 0.05).toInt();

    for (int i = 0; i < dotCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      canvas.drawRect(Rect.fromLTWH(x, y, 1, 1), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DitherPainter oldDelegate) => false;
}


class _PathClipper extends CustomClipper<Path> {
  const _PathClipper(this.path);

  final Path path;

  @override
  Path getClip(Size size) => path;

  @override
  bool shouldReclip(covariant _PathClipper oldClipper) => oldClipper.path != path;
}
