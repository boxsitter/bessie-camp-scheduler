import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants/colors.dart';
import '../../mixins/route_aware_controller_mixin.dart';
import '../buttons/icon_button.dart';
import 'controllers/menu_bar_controller.dart';

/// The menus at the left of the header: the sidebar toggle plus a File, Edit
/// and View menu for the items a page provides (a menu with no items is left out).
///
/// Pass the page's controller as [externalPageController] to rebuild the menus
/// when it calls `update()`.
class BessMenuBar<T extends RouteAwareControllerMixin> extends StatelessWidget {
  const BessMenuBar({super.key, this.externalPageController, this.fileItems, this.viewItems, this.editItems, this.additionalItems});

  final T? externalPageController;
  final List<Widget>? fileItems;
  final List<Widget>? viewItems;
  final List<Widget>? editItems;
  final List<Widget>? additionalItems;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MenuBarController>(
      builder: (menuBarController) {
        // Listen to the page's controller only when there is one.
        if (externalPageController == null) return _buildBar(menuBarController);
        return GetBuilder<T>(builder: (_) => _buildBar(menuBarController));
      },
    );
  }

  Widget _buildBar(MenuBarController controller) {
    return ShadMenubar(
      padding: EdgeInsets.zero,
      selectOnHover: false,
      backgroundColor: Colors.transparent,
      radius: BorderRadius.zero,
      items: [
        Expanded(
          child: BessIconButton(
            iconData: controller.sidebarHidden ? LucideIcons.arrowRightFromLine : LucideIcons.arrowLeftFromLine,
            radius: 0,
            margin: 0,
            onPressed: controller.toggleHideSidebar,
          ),
        ),
        if (fileItems?.isNotEmpty ?? false) _menu(LucideIcons.fileSpreadsheet, fileItems!),
        if (editItems?.isNotEmpty ?? false) _menu(LucideIcons.pencilRuler, editItems!),
        if (viewItems?.isNotEmpty ?? false) _menu(LucideIcons.monitorCog, viewItems!),
        ...?additionalItems,
      ],
    );
  }

  Widget _menu(IconData icon, List<Widget> items) {
    return Expanded(
      child: ShadMenubarItem(
        height: 55,
        buttonDecoration: ShadDecoration(border: ShadBorder(radius: BorderRadius.zero)),
        items: items,
        child: Icon(icon, color: BessColors.textPrimary),
      ),
    );
  }
}
