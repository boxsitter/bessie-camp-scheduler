import 'package:flutter/material.dart';

import '../../constants/colors.dart';

class BessieBottomSheetTheme {
  BessieBottomSheetTheme._();

  static BottomSheetThemeData bottomSheetTheme = BottomSheetThemeData(
    showDragHandle: true,
    backgroundColor: BessColors.low,
    modalBackgroundColor: BessColors.low,
    constraints: const BoxConstraints(minWidth: double.infinity),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );
}
