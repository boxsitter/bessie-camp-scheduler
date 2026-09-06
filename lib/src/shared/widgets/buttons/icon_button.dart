import 'package:bessie/src/shared/widgets/buttons/card_button.dart';
import 'package:bessie/src/shared/widgets/loaders/circular_loader.dart';
import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import '../wrappers/tint.dart';

class BessIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool? selected;
  final bool enabled;
  final IconData iconData;
  final double? size;
  final double? margin;
  final double? radius;
  final Color? backgroundColor;
  final double? iconSize;
  final Color? disabledBackgroundColor;
  final Color? baseIconColor;
  final Color? baseTint;
  final bool isLoading;

  const BessIconButton({
    super.key,
    this.onPressed,
    this.selected,
    this.enabled = true,
    required this.iconData,
    this.size,
    this.margin = 0.0,
    this.radius = 16.0,
    this.backgroundColor,
    this.iconSize,
    this.disabledBackgroundColor,
    this.baseIconColor,
    this.baseTint,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final Widget widget = Padding(
      padding: margin != null ? EdgeInsets.all(margin!) : EdgeInsets.zero,
      child: CardButton(
        width: size,
        height: size,
        onPressed: onPressed,
        tintConditions: [(baseTint != null, baseTint), (selected == true, BessColors.primary)],
        showBorder: selected == true,
        borderThickness: 2,
        radius: radius,
        padding: EdgeInsets.zero,
        backgroundColor: backgroundColor,
        borderColor: BessColors.textPrimary,
        enabled: enabled,
        disabledBackgroundColor: disabledBackgroundColor,
        child: Center(
          child: Builder(builder: (context) {
            if (isLoading) {
              return SizedBox(child: BessCircularLoader(), width: 24, height: 24,);
            }
            return Icon(
              iconData,
              color: baseIconColor != null
                  ? baseIconColor
                  : Tint.of(context) != null
                      ? Tint.of(context)?.foregroundColor
                      : BessColors.textPrimary,
              size: iconSize,
            );
          }),
        ),
      ),
    );

    if (size == null) {
      return AspectRatio(
        aspectRatio: 1.0,
        child: widget,
      );
    } else {
      return widget;
    }
  }
}
