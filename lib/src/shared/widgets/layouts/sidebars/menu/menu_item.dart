import 'package:bessie/src/shared/widgets/layouts/sidebars/sidebar_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/sizes.dart';

class BessMenuItem extends StatelessWidget {
  const BessMenuItem({
    super.key,
    required this.route,
    required this.icon,
    required this.itemName,
  });

  final String route;
  final IconData icon;
  final String itemName;

  @override
  Widget build(BuildContext context) {
    final menuController = Get.find<SidebarController>();

    return InkWell(
      onTap: () => menuController.menuonPressed(route),
      onHover: (hovering) => hovering ? menuController.changeHoverItem(route) : menuController.changeHoverItem(''),
      child: Obx(
        () => Padding(
          padding: const EdgeInsets.symmetric(vertical: BessSizes.spaceBtwMenuItems),
          child: Container(
              decoration: BoxDecoration(
                color:
                    menuController.isHovering(route) || menuController.isActive(route) ? BessColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(BessSizes.cardRadiusMd),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  //Icon
                  Padding(
                    padding:
                        const EdgeInsets.only(left: BessSizes.lg, top: BessSizes.md, bottom: BessSizes.md, right: BessSizes.md),
                    child: menuController.isActive(route)
                        ? Icon(icon, size: 22, color: BessColors.low)
                        : Icon(icon,
                            size: 22, color: menuController.isHovering(route) ? BessColors.textInverted : BessColors.textPrimary),
                  ),

                  // Text
                  if (menuController.isHovering(route) || menuController.isActive(route))
                    Flexible(child: Text(itemName, style: Theme.of(context).textTheme.bodyMedium!.apply(color: BessColors.low)))
                  else
                    Flexible(
                        child: Text(itemName, style: Theme.of(context).textTheme.bodyMedium!.apply(color: BessColors.semiHigh))),
                ],
              )),
        ),
      ),
    );
  }
}
