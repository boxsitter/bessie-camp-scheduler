import 'package:flutter/material.dart';

import '../../constants/sizes.dart';

/// Picks the desktop, tablet or mobile widget for the width it is given.
class BessResponsiveWidget extends StatelessWidget {
  const BessResponsiveWidget({super.key, required this.desktop, required this.tablet, required this.mobile});

  final Widget desktop;
  final Widget tablet;
  final Widget mobile;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        if (constraints.maxWidth >= BessSizes.desktopScreenSize) return desktop;
        if (constraints.maxWidth >= BessSizes.tabletScreenSize) return tablet;
        return mobile;
      },
    );
  }
}
