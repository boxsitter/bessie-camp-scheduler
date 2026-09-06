import 'package:flutter/material.dart';

/// A custom scroll physics that allows for snapping and less momentum.
class CustomScrollPhysics extends ScrollPhysics {
  final double itemHeight;

  const CustomScrollPhysics({required this.itemHeight, super.parent});

  @override
  CustomScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomScrollPhysics(parent: buildParent(ancestor), itemHeight: itemHeight);
  }

  double _getTargetPixels(ScrollMetrics position, double velocity) {
    double page = position.pixels / itemHeight;

    final tolerance = toleranceFor(position);
    if (velocity.abs() > tolerance.velocity) {
      if (velocity < -tolerance.velocity) {
        page -= 0.5;
      } else {
        page += 0.5;
      }
    }

    final double targetPixels = page.round() * itemHeight;
    return targetPixels.clamp(position.minScrollExtent, position.maxScrollExtent);
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    final tolerance = toleranceFor(position);
    final double target = _getTargetPixels(position, velocity);

    if (target == position.minScrollExtent || target == position.maxScrollExtent) {
      if (velocity.abs() > tolerance.velocity) {
        return super.createBallisticSimulation(position, velocity);
      }
    }

    if ((target - position.pixels).abs() < tolerance.distance) {
      return null;
    }

    return ScrollSpringSimulation(
      SpringDescription.withDampingRatio(
        mass: 1.0,
        stiffness: 70.0,
        ratio: 1.0,
      ),
      position.pixels,
      target,
      velocity,
      tolerance: tolerance,
    );
  }

  @override
  bool get allowImplicitScrolling => true;
}