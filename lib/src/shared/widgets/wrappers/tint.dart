import 'package:bessie/src/shared/utils/helpers/helper_functions.dart';
import 'package:flutter/material.dart';
import 'package:bessie/src/shared/constants/colors.dart';

/// A type definition for a tinting condition.
/// The first element is an `isActive` flag, and the second is the `Color` to apply if active.
typedef TintCondition = (bool, Color?);

class TintInfo {
  final Color backgroundColor;
  final Color borderColor;
  final Color foregroundColor;

  const TintInfo({
    required this.backgroundColor,
    required this.borderColor,
    required this.foregroundColor,
  });
  //... equality and hashCode
}

class _TintData extends InheritedWidget {
  final TintInfo tintInfo;

  const _TintData({
    required this.tintInfo,
    required super.child,
  });

  @override
  bool updateShouldNotify(_TintData oldWidget) => tintInfo != oldWidget.tintInfo;
}

class Tint extends StatelessWidget {
  final Widget child;
  final List<TintCondition>? tintConditions;
  final bool darken;
  final Color? baseBackgroundColor;
  final Color? baseBorderColor;
  final Color? baseForegroundColor;

  const Tint({
    super.key,
    required this.child,
    this.tintConditions,
    this.darken = false,
    this.baseBackgroundColor,
    this.baseBorderColor,
    this.baseForegroundColor,
  });

  static TintInfo? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_TintData>()?.tintInfo;
  }

  @override
  Widget build(BuildContext context) {
    // Find the first active tint color from the conditions list.
    Color? activeTint;
    if (tintConditions != null) {
      for (final condition in tintConditions!) {
        if (condition.$1) {
          activeTint = condition.$2;
          break; // Use the first active tint found
        }
      }
    }

    // --- Calculate Background Color ---
    Color effectiveBackgroundColor = baseBackgroundColor ?? BessColors.core;
    if (activeTint != null) {
      effectiveBackgroundColor =
          BessHelperFunctions.blendColors(effectiveBackgroundColor, activeTint, 60);
    }
    if (darken) {
      effectiveBackgroundColor = BessHelperFunctions.adjustHSL(effectiveBackgroundColor, luminance: -0.07, saturation: 0.2);
    }

    // --- Calculate Border Color ---
    Color effectiveBorderColor =
        activeTint ?? baseBorderColor ?? BessColors.borderPrimary;
    if (darken) {
      effectiveBorderColor = BessHelperFunctions.adjustHSL(effectiveBorderColor, luminance: -0.07, saturation: 0.2);
    }

    // --- Calculate Foreground Color ---
    Color effectiveForegroundColor =
        activeTint ?? baseForegroundColor ?? BessColors.textPrimary;
    if (darken) {
      effectiveForegroundColor = BessHelperFunctions.adjustHSL(effectiveForegroundColor, luminance: -0.07, saturation: 0.2);
    }
    // Apply final adjustment regardless of tint or darken
    effectiveForegroundColor = BessHelperFunctions.adjustHSL(
        effectiveForegroundColor,
        luminance: -0.2);

    final tintInfo = TintInfo(
      backgroundColor: effectiveBackgroundColor,
      borderColor: effectiveBorderColor,
      foregroundColor: effectiveForegroundColor,
    );

    return _TintData(
      tintInfo: tintInfo,
      child: child,
    );
  }
}
