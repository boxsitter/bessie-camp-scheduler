import 'package:flutter/material.dart';

import '../../header/menu_bar.dart';
import '../../responsive/responsive_design.dart';
import '../../responsive/screens/desktop_layout.dart';
import '../../responsive/screens/mobile_layout.dart';

/// The frame of every signed-in page: header, sidebar and the page's [desktop]
/// content, adapting to the window width.
class BessSiteTemplate extends StatelessWidget {
  const BessSiteTemplate({
    super.key,
    required this.desktop,
    this.menuBar = const BessMenuBar(),
    this.desktopPadding = true,
    this.tabletPadding = true,
    this.centerActions = const [],
    this.trailingWidgets = const [],
  });

  final Widget desktop;
  final BessMenuBar menuBar;
  final bool desktopPadding;
  final bool tabletPadding;

  /// Shown in the header next to the menu bar.
  final List<Widget> centerActions;

  /// Shown at the right of the header, before the user menu.
  final List<Widget> trailingWidgets;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BessResponsiveWidget(
        desktop: DesktopLayout(
          body: desktop,
          usePadding: desktopPadding,
          menuBar: menuBar,
          centerActions: centerActions,
          trailingWidgets: trailingWidgets,
          hideSidebarByDefault: false,
        ),
        tablet: DesktopLayout(
          body: desktop,
          usePadding: tabletPadding,
          menuBar: menuBar,
          centerActions: centerActions,
          trailingWidgets: trailingWidgets,
          hideSidebarByDefault: true,
        ),
        mobile: const MobileLayout(),
      ),
    );
  }
}
