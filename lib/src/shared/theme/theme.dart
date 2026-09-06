import 'package:bessie/src/shared/constants/sizes.dart';
import 'package:bessie/src/shared/theme/widget_themes/data_table_theme.dart';
import 'package:bessie/src/shared/theme/widget_themes/progress_indicator_theme.dart';
import 'package:bessie/src/shared/theme/widget_themes/scrollbar_theme.dart';
import 'package:flutter/material.dart';

import '../constants/colors.dart';
import 'widget_themes/appbar_theme.dart';
import 'widget_themes/bottom_sheet_theme.dart';
import 'widget_themes/checkbox_theme.dart';
import 'widget_themes/chip_theme.dart';
import 'widget_themes/elevated_button_theme.dart';
import 'widget_themes/outlined_button_theme.dart';
import 'widget_themes/text_field_theme.dart';
import 'widget_themes/text_theme.dart';

class BessieAppTheme {
  BessieAppTheme._();

  static ThemeData theme = ThemeData(
    useMaterial3: true,
    cupertinoOverrideTheme: MaterialBasedCupertinoThemeData(materialTheme: ThemeData(checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BessSizes.xs)),
      checkColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return BessColors.low;
        } else {
          return BessColors.high;
        }
      }),
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return BessColors.primary;
        } else {
          return Colors.transparent;
        }
      }),
    ))),

    visualDensity: VisualDensity.compact,
    fontFamily: 'Inter',
    platform: TargetPlatform.android,
    disabledColor: BessColors.disabled,
    brightness: Brightness.light,
    primaryColor: BessColors.core,
    textTheme: BessTextTheme.textTheme,
    chipTheme: BessieChipTheme.chipTheme,
    appBarTheme: BessieAppBarTheme.appBarTheme,
    checkboxTheme: BessieCheckboxTheme.checkboxTheme,
    scaffoldBackgroundColor: BessColors.background,
    bottomSheetTheme: BessieBottomSheetTheme.bottomSheetTheme,
    elevatedButtonTheme: BessieElevatedButtonTheme.elevatedButtonTheme,
    outlinedButtonTheme: BessieOutlinedButtonTheme.outlinedButtonTheme,
    inputDecorationTheme: BessieTextFormFieldTheme.inputDecorationTheme,
    progressIndicatorTheme: BessieProgressIndicatorTheme.progressIndicatorTheme,
    dataTableTheme: BessieDataTableTheme.dataTableTheme,
    iconTheme: IconThemeData(color: BessColors.semiHigh, size: BessSizes.bg),
    scrollbarTheme: BessieScrollbarTheme.scrollbarTheme,
  );

  // static ThemeData darkTheme = ThemeData(
  //   useMaterial3: true,
  //   fontFamily: 'Inter',
  //   disabledColor: BessColors.grey,
  //   brightness: Brightness.dark,
  //   primaryColor: BessColors.core,
  //   textTheme: BessieTextTheme.darkTextTheme,
  //   chipTheme: BessieChipTheme.darkChipTheme,
  //   appBarTheme: BessieAppBarTheme.darkAppBarTheme,
  //   checkboxTheme: BessieCheckboxTheme.darkCheckboxTheme,
  //   scaffoldBackgroundColor: BessColors.primary.withValues(alpha: (0.1)),
  //   bottomSheetTheme: BessieBottomSheetTheme.darkBottomSheetTheme,
  //   elevatedButtonTheme: BessieElevatedButtonTheme.darkElevatedButtonTheme,
  //   outlinedButtonTheme: BessieOutlinedButtonTheme.darkOutlinedButtonTheme,
  //   inputDecorationTheme: BessieTextFormFieldTheme.darkInputDecorationTheme,
  // );
}
