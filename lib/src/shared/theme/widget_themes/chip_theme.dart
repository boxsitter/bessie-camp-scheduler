import 'package:flutter/material.dart';

import '../../constants/colors.dart';

class BessieChipTheme {
  BessieChipTheme._();

  static ChipThemeData chipTheme = ChipThemeData(
    checkmarkColor: BessColors.low,
    selectedColor: BessColors.primary,
    disabledColor: BessColors.middle.withValues(alpha: 0.4),
    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12),
    labelStyle:
        TextStyle(color: BessColors.high, fontFamily: 'Inter'),
  );
}
