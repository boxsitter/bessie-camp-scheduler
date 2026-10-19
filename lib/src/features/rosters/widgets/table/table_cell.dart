import 'package:flutter/material.dart';

import '../../../../shared/constants/colors.dart';
import '../../../../shared/constants/sizes.dart';
import '../../../../shared/widgets/buttons/checkbox.dart';

class BessTableCell extends StatelessWidget {
  const BessTableCell({
    super.key,
    this.width,
    this.child,
    this.showVerticalSeparator = false,
    this.separatorColor,
    this.padding,
    this.backgroundColor,
  });

  final double? width;
  final Widget? child;
  final bool showVerticalSeparator;
  final Color? separatorColor;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: BessSizes.md, vertical: BessSizes.sm),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: showVerticalSeparator ? BorderDirectional(end: BorderSide(color: separatorColor ?? BessColors.borderPrimary)) : null,
      ),
      child: child,
    );
  }
}

class StringCellContent extends StatelessWidget {
  const StringCellContent({super.key, required this.content, this.textStyle, this.maxLines, this.textOverflow, this.textColor});

  final String content;
  final TextStyle? textStyle;
  final int? maxLines;
  final TextOverflow? textOverflow;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        content,
        style: textColor != null ? textStyle?.copyWith(color: textColor) : textStyle,
        maxLines: maxLines,
        overflow: textOverflow,
      ),
    );
  }
}

class CheckboxCellContent extends StatelessWidget {
  const CheckboxCellContent({super.key, this.value, this.onChanged});

  final bool? value;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    return Align(alignment: Alignment.center, child: BessCheckbox(onPressed: onChanged, tristate: true, value: value));
  }
}
