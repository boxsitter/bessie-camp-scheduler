import 'dart:ui';

import 'package:bessie/src/shared/constants/palettes/frappe.dart';
import 'package:bessie/src/shared/constants/palettes/latte.dart';
import 'package:bessie/src/shared/constants/palettes/macchiato.dart';
import 'package:bessie/src/shared/constants/palettes/mocha.dart';

typedef Flavor = ({
  Color rosewater,
  Color flamingo,
  Color pink,
  Color mauve,
  Color red,
  Color maroon,
  Color peach,
  Color yellow,
  Color green,
  Color teal,
  Color sky,
  Color sapphire,
  Color blue,
  Color lavender,
  Color text,
  Color subtext1,
  Color subtext0,
  Color overlay2,
  Color overlay1,
  Color overlay0,
  Color surface2,
  Color surface1,
  Color surface0,
  Color crust,
  Color mantle,
  Color base,
});

typedef Catppuccin = ({Flavor latte, Flavor frappe, Flavor macchiato, Flavor mocha});

Catppuccin catppuccin = (latte: latte, frappe: frappe, macchiato: macchiato, mocha: mocha);
