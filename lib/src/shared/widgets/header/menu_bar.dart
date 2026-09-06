import 'package:bessie/src/shared/mixins/route_aware_controller_mixin.dart';
import 'package:bessie/src/shared/widgets/buttons/icon_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants/colors.dart';
import 'controllers/menu_bar_controller.dart';

class BessMenuBar<T extends RouteAwareControllerMixin> extends StatelessWidget {
  const BessMenuBar({
    super.key,
    this.externalPageController,
    this.pageTitle,
    this.fileItems,
    this.viewItems,
    this.editItems,
    this.additionalItems,
    this.helpItems,
  });

  final T? externalPageController;
  final String? pageTitle;
  final List<Widget>? fileItems;
  final List<Widget>? viewItems;
  final List<Widget>? editItems;
  final List<Widget>? additionalItems;
  final List<Widget>? helpItems;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MenuBarController>(
      builder: (internalController) {
        // A function to construct the menu bar. This can be called from different
        // builder paths to avoid duplicating code.
        Widget buildActualMenuBar() {

          List<Widget> menuItems = [];

          menuItems.add(
            Expanded(child: BessIconButton(iconData: internalController.sidebarHidden == true ? LucideIcons.arrowRightFromLine : LucideIcons.arrowLeftFromLine, radius: 0, margin: 0, onPressed: internalController.toggleHideSidebar,)),
          );
          
          menuItems.add(
            Expanded(
              child: ShadMenubarItem(
                height: 55,
                buttonDecoration: ShadDecoration(border: ShadBorder(radius: BorderRadius.zero)),
                child: Icon(
                  LucideIcons.fileSpreadsheet,
                  color: BessColors.textPrimary,
                ),
                items: [
                  if (fileItems != null) ...fileItems!,
                ],
              ),
            ),
          );

          // Edit Menu (conditional)
          if (editItems != null && editItems!.isNotEmpty) {
            menuItems.add(
              Expanded(
                child: ShadMenubarItem(
                  height: 55,
                  buttonDecoration: ShadDecoration(border: ShadBorder(radius: BorderRadius.zero)),
                  child: Icon(
                    LucideIcons.pencilRuler,
                    color: BessColors.textPrimary,
                  ),
                  items: editItems!,
                ),
              ),
            );
          }

          // View Menu
          menuItems.add(
            Expanded(
              child: ShadMenubarItem(
                height: 55,
                buttonDecoration: ShadDecoration(border: ShadBorder(radius: BorderRadius.zero)),
                child: Icon(
                  LucideIcons.monitorCog,
                  color: BessColors.textPrimary,
                ),
                items: [
                  if (viewItems != null) ...viewItems!,
                ],
              ),
            ),
          );

          // Additional Items
          if (additionalItems != null) {
            menuItems.addAll(additionalItems!);
          }

          return ShadMenubar(
            padding: EdgeInsets.zero,
            selectOnHover: false,
            backgroundColor: Colors.transparent,
            radius: BorderRadius.zero,
            items: menuItems,
          );
        }

        // Conditionally listen to the external controller ONLY if it exists.
        // This prevents the null error.
        if (externalPageController != null) {
          return GetBuilder<T>(builder: (extController) {
            // Rebuilds when either internal or external controller updates.
            return buildActualMenuBar();
          });
        } else {
          // Only rebuilds when the internal controller updates.
          return buildActualMenuBar();
        }
      },
    );
  }
}
