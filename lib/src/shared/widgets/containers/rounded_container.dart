import 'package:bessie/src/shared/styles/shadows.dart';
import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/sizes.dart';
import '../wrappers/tint.dart';

// Note: No longer implements Tintable
class BessRoundedContainer extends StatelessWidget {
  final Widget? child;
  final double? radius;
  final double? width;
  final double? height;
  final bool showBorder;
  final bool showShadow;
  final Color? borderColor;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final double borderThickness;
  final bool clipContent;
  final double strokeAlign;
  final BorderRadiusGeometry? manualBorderRadius;
  final List<TintCondition>? tintConditions;
  final bool darken;

  const BessRoundedContainer({
    super.key,
    this.child,
    this.width,
    this.height,
    this.margin,
    this.showShadow = false,
    this.showBorder = false,
    this.padding,
    this.borderColor,
    this.radius,
    this.backgroundColor,
    this.borderThickness = 2,
    this.clipContent = true,
    this.strokeAlign = -1.0,
    this.manualBorderRadius,
    this.tintConditions,
    this.darken = false,
  });

  @override
  Widget build(BuildContext context) {
    // Determine the active tint from the provided states.
    if (tintConditions != null) {
      for (final state in tintConditions!) {
        // Find the first active state and use its color.
        if (state.$1) {
          break;
        }
      }
    }

    // Wrap the container in a Tint widget to apply the calculated effects.
    return Tint(
      darken: darken,
      tintConditions: tintConditions,
      baseBackgroundColor: backgroundColor,
      baseBorderColor: borderColor,
      child: Builder(
        // Use a Builder to get a context that is under the Tint widget.
        builder: (context) {
          // Look up the tree for the final effective colors from the Tint widget.
          final tintInfo = Tint.of(context);
          final effectiveBackgroundColor = tintInfo?.backgroundColor ?? backgroundColor ?? BessColors.core;
          final effectiveBorderColor = tintInfo?.borderColor ?? borderColor ?? BessColors.borderPrimary;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            width: width,
            height: height,
            margin: margin,
            padding: padding ?? const EdgeInsets.all(BessSizes.md),
            clipBehavior: clipContent ? Clip.antiAlias : Clip.none,
            decoration: BoxDecoration(
              color: effectiveBackgroundColor,
              borderRadius: manualBorderRadius ?? BorderRadius.circular(radius ?? BessSizes.cardRadiusLg),
              border: showBorder
                  ? Border.all(
                      strokeAlign: strokeAlign,
                      color: effectiveBorderColor,
                      width: borderThickness,
                    )
                  : null,
              boxShadow: showShadow
                  ? [
                      BessShadowStyle.defaultBoxShadow,
                    ]
                  : null,
            ),
            child: child,
          );
        },
      ),
    );
  }
}
