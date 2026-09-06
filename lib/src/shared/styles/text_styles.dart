import 'package:flutter/material.dart';

import '../constants/colors.dart';

class BessTextStyles {
  static final TextStyle standard = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14.0,
    color: BessColors.textPrimary,
    fontWeight: FontWeight.w400,
    height: 1.2,
  );

  static final TextStyle standardSecondary = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14.0,
    color: BessColors.textSecondary,
    fontWeight: FontWeight.w400,
    height: 1.2,
  );

  static final TextStyle standardBold = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14.0,
    color: BessColors.textPrimary,
    fontWeight: FontWeight.w600,
  );

  static final TextStyle standardInverted = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14.0,
    color: BessColors.textInverted,
    fontWeight: FontWeight.w400,
    height: 1.2,
  );

  static final TextStyle standardLink = TextStyle(
      fontFamily: 'Inter',
      fontSize: 14.0,
      color: BessColors.textLink,
      fontWeight: FontWeight.w400,
      decoration: TextDecoration.underline
  );

  static final TextStyle label = TextStyle(
      fontFamily: 'Inter',
      fontSize: 12.0,
      color: BessColors.textSecondary,
      fontWeight: FontWeight.w300,
  );

  static final TextStyle largerLabel = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14.0,
    color: BessColors.textSecondary,
    fontWeight: FontWeight.w300,
  );

  static final TextStyle subtle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12.0,
    color: BessColors.textSubtle,
    fontWeight: FontWeight.w300,
  );
  static final TextStyle tiny = TextStyle(
    fontFamily: 'Inter',
    fontSize: 10.0,
    color: BessColors.textSubtle,
    fontWeight: FontWeight.w300,
  );

  static final TextStyle secondarySmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11.0,
    color: BessColors.textSecondary,
    fontWeight: FontWeight.w600,
  );

  static final TextStyle lightHeader = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    color: BessColors.textSubtle,
    fontWeight: FontWeight.w300,
    letterSpacing: 2.0,
  );

  static final TextStyle darkHeader = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    color: BessColors.textPrimary,
    fontWeight: FontWeight.w300,
    letterSpacing: 2.0,
  );

  static final TextStyle lightTitle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 36,
    color: BessColors.textSubtle,
    fontWeight: FontWeight.w300,
    letterSpacing: 2.0,
  );

  static final TextStyle darkTitle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 36,
    color: BessColors.textPrimary,
    fontWeight: FontWeight.w300,
    letterSpacing: 2.0,
  );

  static final TextStyle largeCardHeader = TextStyle(
    fontFamily: 'Inter',
    fontSize: 28,
    color: BessColors.textPrimary,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.0,
  );

  static final TextStyle tableHeader = TextStyle(
    fontFamily: 'Inter',
    fontSize: 24.0,
    color: BessColors.textPrimary,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.0,
  );

  static final TextStyle tableHeaderSecondary = TextStyle(
    fontFamily: 'Inter',
    fontSize: 18.0,
    color: BessColors.textSecondary,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.0,
  );

  static final TextStyle columnHeader = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    color: BessColors.textSubtle,
    fontWeight: FontWeight.w600,
    letterSpacing: 2.0,
  );

  static final TextStyle boldCardTitle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 18,
    color: BessColors.textPrimary,
    fontWeight: FontWeight.w600,
    letterSpacing: 2.0,
  );

  static final TextStyle textIcon = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    color: BessColors.textPrimary,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.0,
  );
}