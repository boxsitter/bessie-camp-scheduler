import 'dart:math' show max;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

// --- RIPPLE EFFECT CONSTANTS ---

// --- HOVER PHASE CONSTANTS ---
const double kRippleHoverGlowRadius = 50.0;
const double kRippleHoverGlowOpacity = 0.1;

// --- HOLD PHASE CONSTANTS ---

// Hold -> Radius Shrink
const Duration kRippleHoldShrinkDuration = Duration(milliseconds: 300);
const Curve kRippleHoldShrinkCurve = Curves.decelerate;
const double kRippleHoldShrinkRadiusStart = 50.0;
const double kRippleHoldShrinkRadiusEnd = 25.0;

// Hold -> Opacity Fade-In (Phase 1)
const Duration kRippleHoldOpacityFadeInDuration = Duration(milliseconds: 1000);
const Curve kRippleHoldOpacityFadeInCurve = Curves.decelerate;
const double kRippleHoldOpacityMin = 0.0;
const double kRippleHoldOpacityMax = 0.08;

// --- PROLONGED HOLD PHASE CONSTANTS ---

// Prolonged Hold -> Opacity Fade-In (Phase 2)
const Duration kRippleProlongedHoldOpacityFadeInDuration =
    Duration(milliseconds: 5000);
const Curve kRippleProlongedHoldOpacityFadeInCurve = Curves.linear;
const double kRippleProlongedHoldOpacityMax = 1.0;

// --- RELEASE PHASE CONSTANTS ---

// Release -> Radius Expand
const Duration kRippleReleaseExpandDuration = Duration(milliseconds: 550);
const Curve kRippleReleaseExpandCurve = Curves.decelerate;
const double kRippleReleaseExpandRadiusMax = 100.0;

// Release -> Opacity Fade-Out
const Duration kRippleReleaseOpacityFadeOutDuration = Duration(milliseconds: 550);
const Curve kRippleReleaseOpacityFadeOutCurve = Curves.decelerate;
/// If the ripple's opacity is below this value on release, it will be bumped up
/// to this value to ensure the fade-out is noticeable.
const double kRippleReleaseOpacityMinThreshold = 0.08;
const double kRippleReleaseOpacityMin = 0.0;

// --- MISC ---
const BlendMode kRippleBlendMode = BlendMode.plus;
const double kBloomAmount = 70.0;
const double kRippleDefaultGradientHotspot = 0.5;

class RippleEffect extends StatefulWidget {
  const RippleEffect({
    super.key,
    required this.child,
    required this.isHeld,
    required this.isHovering,
    required this.tapPositionNotifier,
    this.borderRadius = BorderRadius.zero,
    this.rippleColor,
    this.useSolidColor = false,
    this.gradientHotspot = kRippleDefaultGradientHotspot,
    this.onAnimationComplete,
  });

  final Widget child;
  final bool isHeld;
  final bool isHovering;
  final ValueNotifier<Offset?> tapPositionNotifier;
  final BorderRadius borderRadius;
  final Color? rippleColor;
  final bool useSolidColor;
  final double gradientHotspot;
  final VoidCallback? onAnimationComplete;

  @override
  State<RippleEffect> createState() => _RippleEffectState();
}

class _RippleEffectState extends State<RippleEffect> with TickerProviderStateMixin {
  // State
  double _opacityOnRelease = 0.0;
  double _radiusOnRelease = 0.0;

  // Controllers
  late final AnimationController _expandController;
  late final AnimationController _holdController;
  late final AnimationController _slowFadeInController;
  late final AnimationController _releaseFadeOutController;

  // Animations
  late final Animation<double> _curvedExpandAnimation;
  late final Animation<double> _curvedHoldShrinkAnimation;
  late final Animation<double> _curvedHoldFadeInAnimation;
  late final Animation<double> _curvedSlowFadeInAnimation;
  late final Animation<double> _curvedReleaseFadeOutAnimation;

  @override
  void initState() {
    super.initState();

    // -- Controllers --
    _expandController =
        AnimationController(vsync: this, duration: kRippleReleaseExpandDuration);
    _holdController =
        AnimationController(vsync: this, duration: kRippleHoldShrinkDuration);
    _slowFadeInController = AnimationController(
        vsync: this, duration: kRippleProlongedHoldOpacityFadeInDuration);
    _releaseFadeOutController = AnimationController(
        vsync: this, duration: kRippleReleaseOpacityFadeOutDuration);

    // -- Animations --
    _curvedExpandAnimation = CurvedAnimation(
        parent: _expandController, curve: kRippleReleaseExpandCurve);
    _curvedHoldShrinkAnimation =
        CurvedAnimation(parent: _holdController, curve: kRippleHoldShrinkCurve);
    _curvedHoldFadeInAnimation = CurvedAnimation(
        parent: _holdController, curve: kRippleHoldOpacityFadeInCurve);
    _curvedSlowFadeInAnimation = CurvedAnimation(
        parent: _slowFadeInController,
        curve: kRippleProlongedHoldOpacityFadeInCurve);
    _curvedReleaseFadeOutAnimation = CurvedAnimation(
        parent: _releaseFadeOutController,
        curve: kRippleReleaseOpacityFadeOutCurve);

    // -- Listeners --
    _holdController.addStatusListener((status) {
      if (status == AnimationStatus.completed && widget.isHeld) {
        _slowFadeInController.forward(from: 0);
      }
    });
    _expandController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(RippleEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isHeld != widget.isHeld) {
      if (widget.isHeld) {
        _startHoldAnimation();
      } else {
        _startReleaseAnimation();
      }
    }
  }

  @override
  void dispose() {
    _expandController.dispose();
    _holdController.dispose();
    _slowFadeInController.dispose();
    _releaseFadeOutController.dispose();
    super.dispose();
  }

  void _startHoldAnimation() {
    _expandController.stop();
    _releaseFadeOutController.stop();
    _opacityOnRelease = 0.0;
    _radiusOnRelease = 0.0;
    _holdController.forward(from: 0);
    }

  void _startReleaseAnimation() {
    _opacityOnRelease =
        max(_calculateCurrentOpacity(), kRippleReleaseOpacityMinThreshold);
    _radiusOnRelease = _calculateCurrentRadius();

    _expandController.forward(from: 0);
    _releaseFadeOutController.forward(from: 0);
    _holdController.reset();
    _slowFadeInController.reset();
  }

  double _calculateCurrentOpacity() {
    if (_holdController.status != AnimationStatus.completed) {
      return lerpDouble(kRippleHoldOpacityMin, kRippleHoldOpacityMax,
          _curvedHoldFadeInAnimation.value)!;
    } else {
      return lerpDouble(kRippleHoldOpacityMax, kRippleProlongedHoldOpacityMax,
          _curvedSlowFadeInAnimation.value)!;
    }
  }

  double _calculateCurrentRadius() {
    return lerpDouble(kRippleHoldShrinkRadiusStart,
        kRippleHoldShrinkRadiusEnd, _curvedHoldShrinkAnimation.value)!;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
        borderRadius: widget.borderRadius,
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            widget.child,
            Positioned.fill(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _expandController,
                _holdController,
                  _slowFadeInController,
                  _releaseFadeOutController,
                widget.tapPositionNotifier,
                ]),
                builder: (context, child) {
                  final bool isAnimating = _expandController.isAnimating ||
                      _releaseFadeOutController.isAnimating;
                final tapPosition = widget.tapPositionNotifier.value;

                if ((!widget.isHeld && !isAnimating && !widget.isHovering) ||
                    tapPosition == null) {
                    return const SizedBox.shrink();
                  }
                  return CustomPaint(
                    painter: RipplePainter(
                    position: tapPosition,
                    isHolding: widget.isHeld,
                    isHovering: widget.isHovering,
                    holdShrinkProgress: _curvedHoldShrinkAnimation.value,
                    holdFadeInProgress: _curvedHoldFadeInAnimation.value,
                      expandProgress: _curvedExpandAnimation.value,
                      releaseOpacityProgress:
                          _curvedReleaseFadeOutAnimation.value,
                      color: widget.rippleColor ?? Colors.white,
                      currentOpacity: _calculateCurrentOpacity(),
                      opacityOnRelease: _opacityOnRelease,
                      radiusOnRelease: _radiusOnRelease,
                    useSolidColor: widget.useSolidColor,
                    gradientHotspot: widget.gradientHotspot,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
    );
  }
}

class RipplePainter extends CustomPainter {
  final Offset position;
  final bool isHolding;
  final bool isHovering;
  final double holdShrinkProgress;
  final double holdFadeInProgress;
  final double expandProgress;
  final double releaseOpacityProgress;
  final Color color;
  final double currentOpacity;
  final double opacityOnRelease;
  final double radiusOnRelease;
  final bool useSolidColor;
  final double gradientHotspot;

  RipplePainter({
    required this.position,
    required this.isHolding,
    required this.isHovering,
    required this.holdShrinkProgress,
    required this.holdFadeInProgress,
    required this.expandProgress,
    required this.releaseOpacityProgress,
    required this.color,
    required this.currentOpacity,
    required this.opacityOnRelease,
    required this.radiusOnRelease,
    required this.useSolidColor,
    required this.gradientHotspot,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double opacity;
    double radius;

    final bool isAnimatingOut = expandProgress > 0.0 || releaseOpacityProgress > 0.0;

    if (isHolding) {
      // --- HOLD PHASE ---
      opacity = lerpDouble(
          kRippleHoldOpacityMin, kRippleHoldOpacityMax, holdFadeInProgress)!;
      radius = lerpDouble(kRippleHoldShrinkRadiusStart,
          kRippleHoldShrinkRadiusEnd, holdShrinkProgress)!;
    } else if (isAnimatingOut) {
      // --- EXPAND & FADE-OUT PHASE ---
      opacity = lerpDouble(
          opacityOnRelease, kRippleReleaseOpacityMin, releaseOpacityProgress)!;
      radius = lerpDouble(
          radiusOnRelease, kRippleReleaseExpandRadiusMax, expandProgress)!;
    } else if (isHovering) {
      // --- HOVER PHASE ---
      opacity = kRippleHoverGlowOpacity;
      radius = kRippleHoverGlowRadius;
    } else {
      return;
    }

    if (opacity <= 0.0 || radius <= 0.0) return;

    final Paint paint = Paint()..blendMode = kRippleBlendMode;

    if (useSolidColor) {
      paint.color = color.withOpacity(opacity);
      paint.style = PaintingStyle.fill;
    } else {
      paint.shader = RadialGradient(
        colors: [
          color.withOpacity(opacity),
          color.withOpacity(0.0),
        ],
        stops: [gradientHotspot, 1.0],
      ).createShader(Rect.fromCircle(center: position, radius: radius));

    if (kBloomAmount > 0) {
      paint.maskFilter =
          MaskFilter.blur(BlurStyle.normal, kBloomAmount * opacity);
    }
    }
    canvas.drawCircle(position, radius, paint);
  }

  @override
  bool shouldRepaint(covariant RipplePainter oldDelegate) {
    return oldDelegate.position != position ||
        oldDelegate.isHolding != isHolding ||
        oldDelegate.isHovering != isHovering ||
        oldDelegate.holdShrinkProgress != holdShrinkProgress ||
        oldDelegate.holdFadeInProgress != holdFadeInProgress ||
        oldDelegate.expandProgress != expandProgress ||
        oldDelegate.releaseOpacityProgress != releaseOpacityProgress ||
        oldDelegate.color != color ||
        oldDelegate.currentOpacity != currentOpacity ||
        oldDelegate.opacityOnRelease != opacityOnRelease ||
        oldDelegate.radiusOnRelease != radiusOnRelease ||
        oldDelegate.useSolidColor != useSolidColor ||
        oldDelegate.gradientHotspot != gradientHotspot;
  }
}
