import 'package:bessie/src/shared/constants/catppuccin_base.dart';
import 'package:flutter/material.dart';

class BessColors {
  static Flavor flavor = catppuccin.latte;

  // Primary theme colors
  static Color primary = flavor.blue;
  static Color secondary = flavor.mauve;
  static Color accent = flavor.lavender;

  // Text colors
  static Color textPrimary = flavor.text;
  static Color textSecondary = flavor.subtext0;
  static Color textSubtle = flavor.overlay1;
  static Color textLink = flavor.blue;
  static Color textInverted = flavor.crust;

  // Background colors
  static Color background = flavor.mantle;
  static Color core = flavor.base;
  static Color crust = flavor.crust;

  // Element colors
  static Color element1 = flavor.surface0;
  static Color element2 = flavor.surface1;
  static Color element3 = flavor.surface2;
  static Color icon = flavor.overlay2;
  static Color disabled = flavor.overlay2;

  // Overlay colors
  static Color overlay1 = flavor.overlay0;
  static Color overlay2 = flavor.overlay1;
  static Color overlay3 = flavor.overlay2;

  // Misc colors
  static Color borderPrimary = flavor.surface0;
  static Color borderSecondary = flavor.text;
  static Color shadow = const Color(0xFFCCD0DA).withValues(alpha: 0.9);

  // Error and validation colors
  static Color success = flavor.green;
  static Color warning = flavor.yellow;
  static Color error = flavor.red;
  static Color info = flavor.blue;

  // Colors
  static Color rosewater = flavor.rosewater;
  static Color flamingo = flavor.flamingo;
  static Color pink = flavor.pink;
  static Color mauve = flavor.mauve;
  static Color red = flavor.red;
  static Color maroon = flavor.maroon;
  static Color peach = flavor.peach;
  static Color yellow = flavor.yellow;
  static Color green = flavor.green;
  static Color teal = flavor.teal;
  static Color sky = flavor.sky;
  static Color sapphire = flavor.sapphire;
  static Color blue = flavor.blue;
  static Color lavender = flavor.lavender;

  // Shades
  // Ordered from background to foreground
  // Low is light on light themes and dark on dark themes
  // High is dark on light themes and light on dark themes
  static Color low = flavor.crust;
  static Color semiLow = flavor.surface1;
  static Color middle = flavor.overlay0;
  static Color semiHigh = flavor.subtext0;
  static Color high = flavor.text;
}
