import 'dart:ui';
import 'package:bessie/src/shared/widgets/wrappers/radiance/radiance_consts_old.dart';
import 'package:flutter/material.dart';

class RadiancePainterOld extends CustomPainter {
  const RadiancePainterOld({
    this.hoverPosition,
    this.releasePosition,
    required this.hoverOpacity,
    required this.hoverRadius,
    required this.releaseOpacity,
    required this.releaseRadius,
    required this.isHolding,
    required this.isReleasing,
    required this.holdProgress,
    required this.color,
  });

  final Offset? hoverPosition;
  final Offset? releasePosition;
  final double hoverOpacity;
  final double hoverRadius;
  final double releaseOpacity;
  final double releaseRadius;
  final bool isHolding;
  final bool isReleasing;
  final double holdProgress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..blendMode = kRadianceBlendMode;

    // Draw the hold effect if it's active. This takes priority.
    if (isHolding && hoverPosition != null) {
      final scaleDownProgress = (holdProgress * kHoldChargeDuration.inMilliseconds / kHoldScaleDownDuration.inMilliseconds).clamp(0.0, 1.0);
      final currentRadius = lerpDouble(kHoverRadius, kHoldRadiusMin, scaleDownProgress)!;
      final currentOpacity = lerpDouble(kHoverOpacity, kHoldOpacityMax, holdProgress)!;

      paint.color = color.withOpacity(currentOpacity);
      paint.maskFilter = MaskFilter.blur(BlurStyle.normal, currentRadius * 0.75);
      canvas.drawCircle(hoverPosition!, currentRadius, paint);
    }
    // Otherwise, draw the hover glow if it's visible and not being overridden by a release animation.
    else if (hoverOpacity > 0.0 && hoverPosition != null && !isReleasing) {
      paint.color = color.withOpacity(hoverOpacity);
      paint.maskFilter = MaskFilter.blur(BlurStyle.normal, hoverRadius * 0.75);
      canvas.drawCircle(hoverPosition!, hoverRadius, paint);
    }

    // Draw the release burst on top if it's happening.
    if (isReleasing && releasePosition != null && releaseOpacity > 0.0) {
      paint.color = color.withOpacity(releaseOpacity);
      paint.maskFilter = MaskFilter.blur(BlurStyle.normal, releaseRadius * 0.75);
      canvas.drawCircle(releasePosition!, releaseRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant RadiancePainterOld oldDelegate) {
    return oldDelegate.hoverPosition != hoverPosition ||
        oldDelegate.releasePosition != releasePosition ||
        oldDelegate.hoverOpacity != hoverOpacity ||
        oldDelegate.hoverRadius != hoverRadius ||
        oldDelegate.releaseOpacity != releaseOpacity ||
        oldDelegate.releaseRadius != releaseRadius ||
        oldDelegate.isHolding != isHolding ||
        oldDelegate.isReleasing != isReleasing ||
        oldDelegate.holdProgress != holdProgress ||
        oldDelegate.color != color;
  }
}