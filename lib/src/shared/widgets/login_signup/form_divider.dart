import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import '../../utils/helpers/helper_functions.dart';

class TFormDivider extends StatelessWidget {
  const TFormDivider({super.key, required this.dividerText});

  final String dividerText;

  @override
  Widget build(BuildContext context) {
    final dark = BessHelperFunctions.isDarkMode(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
            child: Divider(
                color: dark ? BessColors.semiHigh : BessColors.middle,
                thickness: 0.5,
                indent: 60,
                endIndent: 5)),
        Text(dividerText, style: Theme.of(context).textTheme.labelMedium),
        Flexible(
            child: Divider(
                color: dark ? BessColors.semiHigh : BessColors.middle,
                thickness: 0.5,
                indent: 5,
                endIndent: 60)),
      ],
    );
  }
}
