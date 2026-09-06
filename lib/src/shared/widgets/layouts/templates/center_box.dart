import 'package:flutter/material.dart';

import '../../../styles/spacing_styles.dart';
import '../../../constants/colors.dart';
import '../../../constants/sizes.dart';
import '../../../utils/helpers/helper_functions.dart';

class BessCenterBox extends StatelessWidget {
  const BessCenterBox({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 550,
        child: SingleChildScrollView(
          child: Container(
            padding: BessSpacingStyle.paddingWithAppBarHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(BessSizes.cardRadiusLg),
              color: BessHelperFunctions.isDarkMode(context)
                  ? BessColors.high
                  : BessColors.low,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
