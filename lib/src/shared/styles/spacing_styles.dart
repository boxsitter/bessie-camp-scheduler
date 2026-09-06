import 'package:flutter/material.dart';

import '../constants/sizes.dart';

class BessSpacingStyle {
  static const EdgeInsetsGeometry paddingWithAppBarHeight = EdgeInsets.only(
    top: BessSizes.appBarHeight,
    left: BessSizes.defaultSpace,
    bottom: BessSizes.defaultSpace,
    right: BessSizes.defaultSpace,
  );
}
