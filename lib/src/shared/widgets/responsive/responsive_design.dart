import 'package:flutter/material.dart';

import '../../constants/sizes.dart';

class BessResponsiveWidget extends StatefulWidget {
  const BessResponsiveWidget(
      {super.key,
        required this.desktop,
        required this.tablet,
        required this.mobile});

  /// Widget for desktop layout
  final Widget desktop;

  /// Widget for tablet layout
  final Widget tablet;

  /// Widget for mobile layout
  final Widget mobile;

  @override
  BessResponsiveWidgetState createState() => BessResponsiveWidgetState();
}

class BessResponsiveWidgetState extends State<BessResponsiveWidget> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        if (constraints.maxWidth >= BessSizes.desktopScreenSize) {
          return widget.desktop;
        } else if (constraints.maxWidth < BessSizes.desktopScreenSize &&
            constraints.maxWidth >= BessSizes.tabletScreenSize) {
          return widget.tablet;
        } else {
          return widget.mobile;
        }
      },
    );
  }
}
