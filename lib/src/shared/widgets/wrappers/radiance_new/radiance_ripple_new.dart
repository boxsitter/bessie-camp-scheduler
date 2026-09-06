// radiance_ripple_new.dart
import 'dart:ui';
import 'package:bessie/src/shared/widgets/wrappers/radiance_new/radiance_consts_new.dart';
import 'package:flutter/material.dart';

import '../../effects/radiance/radiance.dart';

/// A helper class to manage the state and animation of a single static burst effect.
class _BurstAnimation {
  late final AnimationController controller;
  late final Animation<double> spread;
  late final Animation<double> intensity;
  final Offset position;

  _BurstAnimation({
    required TickerProvider vsync,
    required this.position,
    required Duration duration,
    required double beginSpread,
    required double endSpread,
    required double beginIntensity,
    required double endIntensity,
    required Curve spreadCurve,
    required Curve intensityCurve,
  }) {
    controller = AnimationController(vsync: vsync, duration: duration);
    spread = CurvedAnimation(parent: controller, curve: spreadCurve)
        .drive(Tween<double>(begin: beginSpread, end: endSpread));
    intensity = CurvedAnimation(parent: controller, curve: intensityCurve)
        .drive(Tween<double>(begin: beginIntensity, end: endIntensity));
  }

  void dispose() {
    controller.dispose();
  }
}

class RadianceRipple extends StatefulWidget {
  const RadianceRipple({
    super.key,
    required this.child,
    required this.isHeld,
    required this.isHovering,
    this.tapPosition,
    this.borderRadius = BorderRadius.zero,
    this.color,
  });

  final Widget child;
  final bool isHeld;
  final bool isHovering;
  final Offset? tapPosition;
  final BorderRadius borderRadius;
  final Color? color;

  @override
  State<RadianceRipple> createState() => _RadianceRippleState();
}

class _RadianceRippleState extends State<RadianceRipple> with TickerProviderStateMixin {
  // --- Controllers for Mouse-Bound Effects ---
  late final AnimationController _hoverController;
  late final AnimationController _holdController;

  late Animation<double> _hoverIntensityAnimation;
  late Animation<double> _hoverSpreadAnimation;

  // --- State for Static "Fire-and-Forget" Bursts ---
  final List<_BurstAnimation> _bursts = [];

  // --- Interaction State ---
  Offset? _lastPosition;
  DateTime? _holdStartTime;

  @override
  void initState() {
    super.initState();
    // Controller for hover glow (mouse-bound)
    _hoverController = AnimationController(vsync: this, duration: kHoverFadeDuration);
    if (widget.isHovering) {
      _hoverController.value = 1.0;
    }
    _hoverIntensityAnimation =
        CurvedAnimation(parent: _hoverController, curve: kHoverFadeCurve).drive(Tween<double>(begin: 0.0, end: kHoverIntensity));
    _hoverSpreadAnimation = CurvedAnimation(parent: _hoverController, curve: kHoverFadeCurve)
        .drive(Tween<double>(begin: kHoverSpread * kHoverSpreadBeginFactor, end: kHoverSpread));

    // Controller for hold/charge effect (mouse-bound)
    _holdController = AnimationController(vsync: this, duration: kHoldChargeDuration);
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _holdController.dispose();
    for (final burst in _bursts) {
      burst.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(RadianceRipple oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.tapPosition != null) {
      _lastPosition = widget.tapPosition;
    }

    // --- State Transitions ---
    final justEntered = !oldWidget.isHovering && widget.isHovering;
    final justExited = oldWidget.isHovering && !widget.isHovering;
    final justPressed = !oldWidget.isHeld && widget.isHeld;
    final justReleased = oldWidget.isHeld && !widget.isHeld;

    // --- Handle Mouse-Bound Effects ---
    if (justEntered) {
      _hoverController.forward();
      if (widget.isHeld) {
        // If user drags back in while holding, resume the hold animation
        _holdController.forward();
      }
    }

    if (justExited) {
      _hoverController.reverse();
      // Animate the hold effect out instead of stopping abruptly
      _holdController.reverse();
    }

    if (justPressed && widget.isHovering) {
      _holdController.forward(from: 0.0);
      _holdStartTime = DateTime.now();
    }

    // --- Handle Static Effects ---
    if (justReleased) {
      if (_holdStartTime != null) {
        final holdDuration = DateTime.now().difference(_holdStartTime!);
        final charge = _holdController.value;

        // Reset mouse-bound hold state
        _holdController.reset();
        _holdStartTime = null;

        // If released inside, spawn a static burst that will animate independently
        if (widget.isHovering) {
          _createAndAddBurst(charge, holdDuration);
        }
      }
    }
  }

  /// Creates a new static burst animation and adds it to the render list.
  void _createAndAddBurst(double charge, Duration holdDuration) {
    final position = _lastPosition;
    if (position == null) return;

    late final _BurstAnimation burst;

    if (holdDuration < kQuickClickThreshold) {
      // Quick Click Burst
      burst = _BurstAnimation(
        vsync: this,
        position: position,
        duration: kQuickClickBurstDuration,
        beginSpread: kQuickClickStartSpread,
        endSpread: kQuickClickEndSpread,
        beginIntensity: kQuickClickStartIntensity,
        endIntensity: 0.0,
        spreadCurve: Curves.easeOut,
        intensityCurve: kReleaseFadeOutCurve,
      );
    } else {
      // Charged Release Burst
      final chargedSpread = lerpDouble(kReleaseSpreadMax, kReleaseSpreadMax + kChargedReleaseSpreadBonus, charge)!;
      final chargedLifespan = Duration(
          milliseconds: lerpDouble(kReleaseLifespan.inMilliseconds,
              kReleaseLifespan.inMilliseconds + kChargedReleaseLifespanBonus.inMilliseconds, charge)!
              .toInt());
      final initialIntensity = lerpDouble(kHoverIntensity, kHoldIntensityMax, charge)!;
      final initialSpread = lerpDouble(kHoverSpread, kHoldSpreadMin, charge)!;

      burst = _BurstAnimation(
        vsync: this,
        position: position,
        duration: chargedLifespan,
        beginSpread: initialSpread,
        endSpread: chargedSpread,
        beginIntensity: initialIntensity,
        endIntensity: 0.0,
        spreadCurve: Curves.easeOut,
        intensityCurve: kReleaseFadeOutCurve,
      );
    }

    // Add the listener after the burst is constructed to avoid assignment errors.
    burst.controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _removeBurst(burst);
      }
    });

    setState(() {
      _bursts.add(burst);
    });
    burst.controller.forward();
  }

  /// Removes a burst from the list and disposes its controller.
  void _removeBurst(_BurstAnimation burst) {
    setState(() {
      _bursts.remove(burst);
    });
    burst.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,
          // --- 1. Render all static, "fire-and-forget" bursts ---
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge(_bursts.map((b) => b.controller).toList()),
              builder: (context, child) {
                return Stack(
                  children: _bursts.map((burst) {
                    return Radiance(
                      shapePath: Path()
                        ..addOval(Rect.fromCircle(center: burst.position, radius: burst.spread.value)),
                      intensity: burst.intensity.value,
                      spread: burst.spread.value,
                      color: widget.color ?? Colors.white,
                      passes: 1,
                    );
                  }).toList(),
                );
              },
            ),
          ),
          // --- 2. Render the mouse-bound hover and hold effects on top ---
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([_hoverController, _holdController]),
              builder: (context, child) {
                final position = widget.tapPosition ?? _lastPosition;
                if (position == null) return const SizedBox.shrink();

                double spread = _hoverSpreadAnimation.value;
                double intensity = _hoverIntensityAnimation.value;

                // The hold effect is a modification of the base hover glow
                if (_holdController.value > 0) {
                  final holdCharge = _holdController.value;
                  final scaleDownProgress =
                  (holdCharge * kHoldChargeDuration.inMilliseconds / kHoldScaleDownDuration.inMilliseconds)
                      .clamp(0.0, 1.0);
                  spread = lerpDouble(_hoverSpreadAnimation.value, kHoldSpreadMin, scaleDownProgress)!;
                  intensity = lerpDouble(_hoverIntensityAnimation.value, kHoldIntensityMax, holdCharge)!;
                }

                if (intensity <= 0) return const SizedBox.shrink();

                return Radiance(
                  shapePath: Path()..addOval(Rect.fromCircle(center: position, radius: spread)),
                  intensity: intensity,
                  spread: spread,
                  color: widget.color ?? Colors.white,
                  passes: 1,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}