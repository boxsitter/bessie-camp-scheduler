import 'package:bessie/src/shared/widgets/header/controllers/menu_bar_controller.dart';
import 'package:bessie/src/shared/widgets/header/header.dart';
import 'package:bessie/src/shared/widgets/header/menu_bar.dart';
import 'package:bessie/src/shared/widgets/layouts/sidebars/sidebar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../constants/sizes.dart';

class DesktopLayout extends StatelessWidget {
  const DesktopLayout({super.key, required this.menuBar, this.body, this.usePadding = true, this.centerActions, this.trailingWidgets, required this.hideSidebarByDefault});

  final Widget? body;
  final bool usePadding;
  final BessMenuBar menuBar;
  final List<Widget>? centerActions;
  final List<Widget>? trailingWidgets;
  final bool hideSidebarByDefault;

  @override
  Widget build(BuildContext context) {
    MenuBarController menuBarController = Get.find<MenuBarController>();
    if (hideSidebarByDefault && menuBarController.sidebarHiddenRaw == null) {
      menuBarController.setHideSidebar(true);
    } else if (!hideSidebarByDefault && menuBarController.sidebarHiddenRaw == null) {
      menuBarController.setHideSidebar(false);
    }

    return GetBuilder<MenuBarController>(
      builder: (controller) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BessHeader(
              menuBar: menuBar,
              centerActions: centerActions ?? [],
              trailingWidgets: trailingWidgets ?? [],
            ),
            // Main Content Area
            Expanded(
              child: Row(
                children: [
                  if (!controller.sidebarHidden) ...[
                    const BessSidebar(),
                  ],
                  Expanded(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: usePadding ? const EdgeInsets.all(BessSizes.lg) : const EdgeInsets.all(0),
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
