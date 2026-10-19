import 'package:flutter/material.dart';

import '../../constants/colors.dart';

/// Custom Class for Light & Dark Text Themes
class BessTextTheme {
  BessTextTheme._(); // To avoid creating instances

  static TextTheme textTheme = TextTheme(
    headlineLarge: const TextStyle().copyWith(
      fontSize: 28.0,
      fontWeight: FontWeight.w900, // Black weight
      color: BessColors.textPrimary,
      letterSpacing: 1.0,
      fontFamily: 'Inter',
    ),
    headlineMedium: const TextStyle().copyWith(
      fontSize: 24.0,
      fontWeight: FontWeight.w600, // SemiBold
      color: BessColors.textPrimary,
      letterSpacing: 1.0,
      fontFamily: 'Inter',
    ),
    headlineSmall: const TextStyle().copyWith(
      fontSize: 18.0,
      fontWeight: FontWeight.w500, // Medium
      color: BessColors.textPrimary,
      letterSpacing: 1.0,
      fontFamily: 'Inter',
    ),
    titleLarge: const TextStyle().copyWith(
      fontSize: 16.0,
      fontWeight: FontWeight.w600, // SemiBold
      color: BessColors.textPrimary,
      letterSpacing: 1.0,
      fontFamily: 'Inter',
    ),
    titleMedium: const TextStyle().copyWith(
      fontSize: 16.0,
      fontWeight: FontWeight.w400, // Regular
      fontStyle: FontStyle.italic, // Uses Inter_24pt-Italic.ttf
      color: BessColors.textSecondary,
      letterSpacing: 1.0,
      fontFamily: 'Inter',
    ),
    titleSmall: const TextStyle().copyWith(
      fontSize: 16.0,
      fontWeight: FontWeight.w400, // Regular
      color: BessColors.textSecondary,
      letterSpacing: 1.0,
      fontFamily: 'Inter',
    ),
    bodyLarge: const TextStyle().copyWith(
      fontSize: 14.0,
      fontWeight: FontWeight.w500, // Medium
      color: BessColors.textPrimary,
      letterSpacing: 1.0,
      fontFamily: 'Inter',
    ),
    bodyMedium: const TextStyle().copyWith(
      fontSize: 14.0,
      fontWeight: FontWeight.w400, // Regular
      color: BessColors.textPrimary,
      letterSpacing: 1.0,
      fontFamily: 'Inter',
    ),
    bodySmall: const TextStyle().copyWith(
      fontSize: 14.0,
      fontWeight: FontWeight.w400, // Regular
      fontStyle: FontStyle.italic, // Uses Inter_24pt-Italic.ttf
      color: BessColors.textSecondary,
      letterSpacing: 1.0,
      fontFamily: 'Inter',
    ),
    labelLarge: const TextStyle().copyWith(
      fontSize: 14.0,
      fontWeight: FontWeight.w400, // Regular
      color: BessColors.textPrimary,
      letterSpacing: 1.0,
      fontFamily: 'Inter',
    ),
    labelMedium: const TextStyle().copyWith(
      fontSize: 12.0,
      fontWeight: FontWeight.w300, // Light
      color: BessColors.textSecondary,
      letterSpacing: 1.0,
      fontFamily: 'Inter',
    ),
  );
}
