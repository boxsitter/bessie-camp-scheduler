import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../constants/sizes.dart';
import '../../header/controllers/menu_bar_controller.dart';
import '../../header/header.dart';
import '../../header/menu_bar.dart';
import '../../layouts/sidebars/sidebar.dart';

/// Header across the top, sidebar down the left, the page's [body] in the rest.
class DesktopLayout extends StatelessWidget {
  const DesktopLayout({
    super.key,
    required this.menuBar,
    this.body,
    this.usePadding = true,
    this.centerActions = const [],
    this.trailingWidgets = const [],
    required this.hideSidebarByDefault,
  });

  final Widget? body;
  final bool usePadding;
  final BessMenuBar menuBar;
  final List<Widget> centerActions;
  final List<Widget> trailingWidgets;
  final bool hideSidebarByDefault;

  @override
  Widget build(BuildContext context) {
    Get.find<MenuBarController>().hiddenByDefault = hideSidebarByDefault;

    return GetBuilder<MenuBarController>(
      builder: (controller) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BessHeader(menuBar: menuBar, centerActions: centerActions, trailingWidgets: trailingWidgets),
            Expanded(
              child: Row(
                children: [
                  if (!controller.sidebarHidden) const BessSidebar(),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: usePadding ? const EdgeInsets.all(BessSizes.lg) : EdgeInsets.zero,
                        child: body ?? const SizedBox(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
