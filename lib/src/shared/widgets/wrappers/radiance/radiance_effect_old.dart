import 'dart:ui';
import 'package:bessie/src/shared/widgets/wrappers/radiance/radiance_consts_old.dart';
import 'package:bessie/src/shared/widgets/wrappers/radiance/radiance_painter_old.dart';
import 'package:flutter/material.dart';


enum _ExitDirection { top, right, bottom, left }

class RadianceEffectOld extends StatefulWidget {
  const RadianceEffectOld({
    super.key,
    required this.child,
    required this.isHeld,
    required this.isHovering,
    required this.tapPositionNotifier,
    this.borderRadius = BorderRadius.zero,
    this.color,
  });

  final Widget child;
  final bool isHeld;
  final bool isHovering;
  final ValueNotifier<Offset?> tapPositionNotifier;
  final BorderRadius borderRadius;
  final Color? color;

  @override
  State<RadianceEffectOld> createState() => _RadianceEffectOldState();
}

class _RadianceEffectOldState extends State<RadianceEffectOld>
    with TickerProviderStateMixin {
  late final AnimationController _hoverController;
  late final AnimationController _releaseController;
  late final AnimationController _holdController;
  late final AnimationController _exitTravelController;

  late Animation<double> _hoverOpacityAnimation;
  late Animation<double> _hoverRadiusAnimation;
  late Animation<double> _releaseRadiusAnimation;
  late Animation<double> _releaseOpacityAnimation;
  late Animation<Offset> _exitTravelAnimation;

  final GlobalKey _widgetKey = GlobalKey();
  Offset? _lastPosition;
  Offset? _releasePosition;
  Size? _widgetSize;
  double _charge = 0.0;
  DateTime? _holdStartTime;
  bool _isQuickBurst = false;

  @override
  void initState() {
    super.initState();
    _hoverController =
        AnimationController(vsync: this, duration: kHoverFadeDuration);
    _hoverOpacityAnimation = CurvedAnimation(
      parent: _hoverController,
      curve: kHoverFadeCurve,
    ).drive(Tween<double>(begin: 0.0, end: kHoverOpacity));
    _hoverRadiusAnimation = CurvedAnimation(
      parent: _hoverController,
      curve: kHoverFadeCurve,
    ).drive(Tween<double>(
        begin: kHoverRadius * kHoverRadiusBeginFactor, end: kHoverRadius));

    _releaseController =
        AnimationController(vsync: this, duration: kQuickReleaseLifespan);
    _releaseRadiusAnimation =
        Tween<double>(begin: 0, end: 0).animate(_releaseController);
    _releaseOpacityAnimation =
        Tween<double>(begin: 0, end: 0).animate(_releaseController);
    _releaseController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_isQuickBurst) {
          _isQuickBurst = false;
          _triggerQuickReleaseBurst();
        } else if (widget.isHovering) {
          _hoverController.duration = kRecoveryFadeInDuration;
          _hoverController.forward(from: 0.0);
          _hoverController.duration = kHoverFadeDuration;
        }
      }
    });

    _holdController =
        AnimationController(vsync: this, duration: kHoldChargeDuration);

    _exitTravelController =
        AnimationController(vsync: this, duration: kExitTravelDuration);
    _exitTravelAnimation =
        Tween<Offset>(begin: Offset.zero, end: Offset.zero)
            .animate(_exitTravelController);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final context = _widgetKey.currentContext;
      if (context != null) {
        final renderBox = context.findRenderObject() as RenderBox;
        if (renderBox.hasSize) {
          _widgetSize = renderBox.size;
        }
      }
    });
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _releaseController.dispose();
    _holdController.dispose();
    _exitTravelController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(RadianceEffectOld oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isHovering != oldWidget.isHovering) {
      if (widget.isHovering) {
        _exitTravelController.stop();
        if (!widget.isHeld) {
          _hoverController.forward();
        }
      } else {
        _triggerExitAnimation();
      }
    }

    if (widget.isHeld != oldWidget.isHeld) {
      if (widget.isHeld) {
        _holdStartTime = DateTime.now();
        _releaseController.stop();
        _hoverController.reverse();
        _holdController.forward(from: 0.0);
      } else {
        final holdDuration = DateTime.now().difference(_holdStartTime!);
        _charge = _holdController.value;
        _holdController.reset();

        if (widget.isHovering) {
          if (holdDuration < kQuickClickThreshold) {
            _isQuickBurst = true;
            _triggerQuickReleaseMorph();
          } else {
            _triggerChargedRelease();
          }
        } else {
          _triggerCancelAnimation();
        }
      }
    }
  }

  void _triggerExitAnimation() {
    if (_lastPosition == null || _widgetSize == null) return;

    _hoverController.reverse();

    final center = _widgetSize!.center(Offset.zero);
    final exitVector = _lastPosition! - center;

    _ExitDirection direction;
    if (exitVector.dx.abs() > exitVector.dy.abs()) {
      direction = exitVector.dx > 0 ? _ExitDirection.right : _ExitDirection.left;
    } else {
      direction = exitVector.dy > 0 ? _ExitDirection.bottom : _ExitDirection.top;
    }

    Offset targetPosition;
    switch (direction) {
      case _ExitDirection.top:
        targetPosition = Offset(_lastPosition!.dx, _lastPosition!.dy - kExitTravelDistance);
        break;
      case _ExitDirection.right:
        targetPosition = Offset(_lastPosition!.dx + kExitTravelDistance, _lastPosition!.dy);
        break;
      case _ExitDirection.bottom:
        targetPosition = Offset(_lastPosition!.dx, _lastPosition!.dy + kExitTravelDistance);
        break;
      case _ExitDirection.left:
        targetPosition = Offset(_lastPosition!.dx - kExitTravelDistance, _lastPosition!.dy);
        break;
    }

    _exitTravelAnimation = CurvedAnimation(parent: _exitTravelController, curve: kExitTravelCurve)
        .drive(Tween<Offset>(begin: _lastPosition, end: targetPosition));

    _exitTravelController.forward(from: 0.0);
  }

  void _triggerChargedRelease() {
    _releasePosition = _lastPosition;
    if (_releasePosition == null) return;

    final chargedRadius = lerpDouble(kQuickReleaseRadiusMax,
        kQuickReleaseRadiusMax + kChargedReleaseRadiusBonus, _charge)!;
    final chargedLifespan = Duration(
        milliseconds: lerpDouble(
            kQuickReleaseLifespan.inMilliseconds,
            kQuickReleaseLifespan.inMilliseconds +
                kChargedReleaseLifespanBonus.inMilliseconds,
            _charge)!
            .toInt());
    final initialOpacity =
    lerpDouble(kHoverOpacity, kHoldOpacityMax, _charge)!;
    final initialRadius = lerpDouble(kHoverRadius, kHoldRadiusMin, _charge)!;

    _releaseController.duration = chargedLifespan;

    _releaseRadiusAnimation =
        CurvedAnimation(parent: _releaseController, curve: Curves.easeOut)
            .drive(Tween<double>(begin: initialRadius, end: chargedRadius));
    _releaseOpacityAnimation = CurvedAnimation(
        parent: _releaseController, curve: kQuickReleaseFadeOutCurve)
        .drive(Tween<double>(begin: initialOpacity, end: 0.0));

    _releaseController.forward(from: 0.0);
  }

  void _triggerQuickReleaseMorph() {
    _releasePosition = _lastPosition;
    if (_releasePosition == null) return;

    final scaleDownProgress = (_charge * kHoldChargeDuration.inMilliseconds / kHoldScaleDownDuration.inMilliseconds).clamp(0.0, 1.0);
    final initialRadius = lerpDouble(kHoverRadius, kHoldRadiusMin, scaleDownProgress)!;
    final initialOpacity = lerpDouble(kHoverOpacity, kHoldOpacityMax, _charge)!;

    _releaseController.duration = kQuickClickMorphDuration;

    _releaseRadiusAnimation = CurvedAnimation(parent: _releaseController, curve: Curves.easeOut)
        .drive(Tween<double>(begin: initialRadius, end: kQuickClickStartRadius));
    _releaseOpacityAnimation = CurvedAnimation(parent: _releaseController, curve: Curves.easeOut)
        .drive(Tween<double>(begin: initialOpacity, end: kQuickClickStartOpacity));

    _releaseController.forward(from: 0.0);
  }

  void _triggerQuickReleaseBurst() {
    _releaseController.duration = kQuickClickBurstDuration;

    _releaseRadiusAnimation = CurvedAnimation(parent: _releaseController, curve: Curves.easeOut)
        .drive(Tween<double>(begin: kQuickClickStartRadius, end: kQuickClickEndRadius));
    _releaseOpacityAnimation = CurvedAnimation(parent: _releaseController, curve: kQuickReleaseFadeOutCurve)
        .drive(Tween<double>(begin: kQuickClickStartOpacity, end: 0.0));

    _releaseController.forward(from: 0.0);
  }

  void _triggerCancelAnimation() {
    _releasePosition = _lastPosition;
    if (_releasePosition == null) return;

    final scaleDownProgress = (_charge *
        kHoldChargeDuration.inMilliseconds /
        kHoldScaleDownDuration.inMilliseconds)
        .clamp(0.0, 1.0);
    final initialRadius =
    lerpDouble(kHoverRadius, kHoldRadiusMin, scaleDownProgress)!;
    final initialOpacity =
    lerpDouble(kHoverOpacity, kHoldOpacityMax, _charge)!;

    _releaseController.duration = const Duration(milliseconds: 150);

    _releaseRadiusAnimation =
        CurvedAnimation(parent: _releaseController, curve: Curves.easeOut)
            .drive(Tween<double>(begin: initialRadius, end: initialRadius * 0.8));
    _releaseOpacityAnimation =
        CurvedAnimation(parent: _releaseController, curve: Curves.easeOut)
            .drive(Tween<double>(begin: initialOpacity, end: 0.0));

    _releaseController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      key: _widgetKey,
      borderRadius: widget.borderRadius,
      child: Stack(
            fit: StackFit.passthrough,
            children: [
              widget.child,
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _hoverController,
                    _releaseController,
                    _holdController,
                    _exitTravelController,
                    widget.tapPositionNotifier,
                  ]),
                  builder: (context, child) {
                    final currentPosition = widget.tapPositionNotifier.value;
                    if (currentPosition != null) {
                      _lastPosition = currentPosition;
                    }

                    final bool isExiting = _exitTravelController.isAnimating;
                    final paintPosition = isExiting ? _exitTravelAnimation.value : _lastPosition;

                    final bool shouldPaint = widget.isHovering ||
                        widget.isHeld ||
                        _hoverController.isAnimating ||
                        _holdController.isAnimating ||
                        _releaseController.isAnimating ||
                        isExiting;

                    if (!shouldPaint || (paintPosition == null && !_releaseController.isAnimating)) {
                      return const SizedBox.shrink();
                    }

                    return CustomPaint(
                      painter: RadiancePainterOld(
                        hoverPosition: paintPosition,
                        releasePosition: _releasePosition,
                        hoverOpacity: _hoverOpacityAnimation.value,
                        hoverRadius: _hoverRadiusAnimation.value,
                        releaseOpacity: _releaseOpacityAnimation.value,
                        releaseRadius: _releaseRadiusAnimation.value,
                        isHolding: widget.isHeld,
                        isReleasing: _releaseController.isAnimating,
                        holdProgress: _holdController.value,
                        color: widget.color ?? Colors.white,
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