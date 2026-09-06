import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import '../../constants/sizes.dart';

class BessieAppBarTheme {
  BessieAppBarTheme._();

  static var appBarTheme = AppBarTheme(
    elevation: 0,
    centerTitle: false,
    scrolledUnderElevation: 0,
    backgroundColor: BessColors.core,
    surfaceTintColor: BessColors.core,
    iconTheme:
        IconThemeData(color: BessColors.icon, size: BessSizes.iconMd),
    actionsIconTheme:
        IconThemeData(color: BessColors.icon, size: BessSizes.iconMd),
    titleTextStyle: TextStyle(
        fontSize: 18.0,
        fontWeight: FontWeight.w600,
        color: BessColors.high,
        fontFamily: 'Inter'),
  );
}
