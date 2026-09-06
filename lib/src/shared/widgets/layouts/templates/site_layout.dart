import 'package:bessie/src/shared/widgets/responsive/responsive_design.dart';
import 'package:bessie/src/shared/widgets/responsive/screens/mobile_layout.dart';
import 'package:flutter/material.dart';

import '../../header/menu_bar.dart';
import '../../responsive/screens/desktop_layout.dart';

/// Template for overall site layout, responsive to different screen sizes
class BessSiteTemplate extends StatelessWidget {
  const BessSiteTemplate({
    super.key,
    required this.menuBar,
    this.desktop,
    this.tablet,
    this.mobile,
    this.useLayout = true,
    this.desktopPadding = true,
    this.tabletPadding = true,
    this.centerActions,
    this.trailingWidgets,
  });

  /// Widget for desktop layout
  final Widget? desktop;
  final bool desktopPadding;
  final bool tabletPadding;
  final BessMenuBar menuBar;
  final List<Widget>? centerActions;
  final List<Widget>? trailingWidgets;

  /// Widget for tablet layout
  final Widget? tablet;

  /// Widget for mobile layout
  final Widget? mobile;

  /// Flag to determine whether to use layout
  final bool useLayout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BessResponsiveWidget(
        desktop: useLayout
            ? DesktopLayout(
                body: desktop,
                usePadding: desktopPadding,
                menuBar: menuBar,
                centerActions: centerActions ?? [],
                trailingWidgets: trailingWidgets ?? [],
                hideSidebarByDefault: false,
              )
            : desktop ?? Container(),
        tablet: useLayout
            ? DesktopLayout(
                body: desktop,
                usePadding: desktopPadding,
                menuBar: menuBar,
                centerActions: centerActions ?? [],
                trailingWidgets: trailingWidgets ?? [],
          hideSidebarByDefault: true,
              )
            : desktop ?? Container(),

        // tablet: useLayout
        //     ? TabletLayout(
        //         body: tablet ?? desktop,
        //         usePadding: tabletPadding,
        //         menuBar: menuBar,
        //       )
        //     : tablet ?? desktop ?? Container(),
        mobile: useLayout ? MobileLayout(body: mobile ?? desktop) : mobile ?? desktop ?? Container(),
      ),
    );
  }
}
