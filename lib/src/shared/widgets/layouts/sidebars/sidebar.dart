import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../constants/colors.dart';
import '../../../constants/sizes.dart';
import '../../context_switcher/context_display.dart';
import 'menu/menu_item.dart';
import 'sidebar_controller.dart';

/// The navigation column: the pages this user may open, and the session switcher.
class BessSidebar extends StatelessWidget {
  const BessSidebar({super.key});

  static const double width = 265;

  @override
  Widget build(BuildContext context) {
    final sidebar = Get.find<SidebarController>();
    return SafeArea(
      child: Container(
        width: width,
        padding: const EdgeInsets.all(BessSizes.md),
        decoration: BoxDecoration(color: BessColors.core, border: Border(right: BorderSide(color: BessColors.semiLow))),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Obx(
                  () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [for (final item in sidebar.items) BessMenuItem(item: item)],
                  ),
                ),
              ),
            ),
            const ContextDisplay(),
          ],
        ),
      ),
    );
  }
}
