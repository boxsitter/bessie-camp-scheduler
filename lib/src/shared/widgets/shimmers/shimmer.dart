import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../constants/colors.dart';

class BessShimmerEffect extends StatelessWidget {
  const BessShimmerEffect({
    super.key,
    required this.width,
    required this.height,
    this.radius = 0,
    this.color,
  });

  final double width, height, radius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: BessColors.overlay1,
      highlightColor: BessColors.element1,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: BessColors.overlay1,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class BessShimmerWrapper extends StatelessWidget {
  const BessShimmerWrapper({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.period = const Duration(milliseconds: 1500),
  });

  final Widget child;
  final Color? baseColor, highlightColor;
  final Duration period;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      period: period,
      baseColor: baseColor ?? BessColors.overlay1,
      highlightColor: highlightColor ?? BessColors.element1,
      child: child,
    );
  }
}

