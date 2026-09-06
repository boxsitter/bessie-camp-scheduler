import 'package:bessie/src/shared/styles/text_styles.dart';
import 'package:bessie/src/shared/widgets/buttons/card_button.dart';
import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import '../wrappers/tint.dart';

class BessTextIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool? selected;
  final bool enabled;
  final String content;
  final double? width;
  final double? height;
  final double? margin;
  final double? radius;
  final Color? backgroundColor;

  const BessTextIconButton({
    super.key,
    this.onPressed,
    this.selected,
    this.enabled = true,
    required this.content,
    this.width,
    this.height,
    this.margin = 0.0,
    this.radius = 16.0,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin != null ? EdgeInsets.all(margin!) : EdgeInsets.zero,
      child: CardButton(
        width: width,
        height: height,
        onPressed: onPressed,
        tintConditions: [(selected == true, BessColors.primary)],
        showBorder: selected == true,
        borderThickness: 2,
        radius: radius,
        padding: EdgeInsets.all(8),
        backgroundColor: backgroundColor,
        borderColor: BessColors.textPrimary,
        enabled: enabled,
        child: Center(
          child: Builder(builder: (context) {
            return Text(
              content,
              style: BessTextStyles.textIcon
                  .copyWith(color: Tint.of(context) != null ? Tint.of(context)?.foregroundColor : BessColors.textPrimary),
              maxLines: 2,
              overflow: TextOverflow.clip,
              textAlign: TextAlign.center,
            );
          }),
        ),
      ),
    );
  }
}
