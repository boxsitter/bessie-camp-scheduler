import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import '../../constants/sizes.dart';

class BessieTextFormFieldTheme {
  BessieTextFormFieldTheme._();

  static InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
    errorMaxLines: 3,
    prefixIconColor: BessColors.high,
    suffixIconColor: BessColors.high,
    // constraints: const BoxConstraints.expand(height: TSizes.inputFieldHeight),
    labelStyle: const TextStyle().copyWith(
        fontSize: BessSizes.fontSizeMd,
        color: BessColors.textPrimary,
        fontFamily: 'Inter'),
    hintStyle: const TextStyle().copyWith(
        fontSize: BessSizes.fontSizeSm,
        color: BessColors.textSecondary,
        fontFamily: 'Inter'),
    errorStyle: const TextStyle()
        .copyWith(fontStyle: FontStyle.normal, fontFamily: 'Inter'),
    floatingLabelStyle: const TextStyle()
        .copyWith(color: BessColors.textSecondary, fontFamily: 'Inter'),
    border: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(BessSizes.inputFieldRadius),
      borderSide: BorderSide(width: 1, color: BessColors.borderPrimary),
    ),
    enabledBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(BessSizes.inputFieldRadius),
      borderSide: BorderSide(width: 1, color: BessColors.borderPrimary),
    ),
    focusedBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(BessSizes.inputFieldRadius),
      borderSide: BorderSide(width: 1, color: BessColors.borderSecondary),
    ),
    errorBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(BessSizes.inputFieldRadius),
      borderSide: BorderSide(width: 1, color: BessColors.error),
    ),
    focusedErrorBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(BessSizes.inputFieldRadius),
      borderSide: BorderSide(width: 2, color: BessColors.error),
    ),
  );
}
