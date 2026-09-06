import 'package:bessie/src/shared/controllers/user_controller.dart';
import 'package:bessie/src/shared/widgets/header/controllers/menu_bar_controller.dart';
import 'package:bessie/src/shared/widgets/layouts/sidebars/sidebar_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../routes/routes.dart';
import '../../../constants/colors.dart';
import '../../../constants/sizes.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../../buttons/card_button.dart';
import '../../context_switcher/context_display.dart';
import 'menu/menu_item.dart';

class BessSidebar extends StatelessWidget {
  const BessSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final sideBarController = Get.find<SidebarController>();
    Get.find<UserController>();
    Get.find<MenuBarController>();
    return Drawer(
      shape: BoxBorder.all(color: Colors.transparent),
      width: 265,
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: BessColors.core,
            border: Border(right: BorderSide(color: BessColors.semiLow, width: 1)),
            borderRadius: BorderRadius.zero,
          ),

          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(BessSizes.md),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - (BessSizes.md * 2)),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const BessMenuItem(route: BessRoutes.rosters, icon: LucideIcons.bookUser, itemName: 'Rosters'),
                            const BessMenuItem(
                                route: BessRoutes.activityPreferences,
                                icon: LucideIcons.listOrdered,
                                itemName: 'Activity Preferences'),
                            // const BessMenuItem(route: BessRoutes.schedulePage, icon: LucideIcons.columns3, itemName: 'Schedule'),
                            const BessMenuItem(
                                route: BessRoutes.sessionManager, icon: LucideIcons.calendarCog, itemName: 'Session Manager'),
                            // const BessMenuItem(
                            //     route: BessRoutes.branchManager, icon: LucideIcons.flameKindling, itemName: 'Branch Manager'),
                            const BessMenuItem(route: BessRoutes.console, icon: LucideIcons.squareTerminal, itemName: 'Console'),
                            // const BessMenuItem(
                            //     route: BessRoutes.dev_testing, icon: LucideIcons.flaskConical, itemName: 'Dev Testing'),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CardButton(
                              backgroundColor: BessHelperFunctions.blendColors(BessColors.crust, BessColors.red, 100),
                              showBorder: false,
                              padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                              height: 55,
                              width: 55,
                              onPressed: () => sideBarController.logOut(),
                              child: Icon(LucideIcons.logOut,
                                  color: BessHelperFunctions.blendColors(BessColors.textPrimary, BessColors.red, 150)),
                            ),
                            SizedBox(width: BessSizes.md),
                            Expanded(child: ContextDisplay()),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
