import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/sizes.dart';
import '../sidebar_controller.dart';
import '../sidebar_item.dart';

class BessMenuItem extends StatelessWidget {
  const BessMenuItem({super.key, required this.item});

  final SidebarItem item;

  @override
  Widget build(BuildContext context) {
    final sidebar = Get.find<SidebarController>();
    final route = item.route;

    return InkWell(
      onTap: () => sidebar.open(route),
      onHover: (hovering) => sidebar.changeHoverItem(hovering ? route : ''),
      child: Obx(() {
        final active = sidebar.isActive(route);
        final highlighted = active || sidebar.isHovering(route);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: BessSizes.spaceBtwMenuItems),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: highlighted ? BessColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(BessSizes.cardRadiusMd),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: BessSizes.lg, top: BessSizes.md, bottom: BessSizes.md, right: BessSizes.md),
                  child: Icon(
                    item.icon,
                    size: 22,
                    color: active ? BessColors.low : (highlighted ? BessColors.textInverted : BessColors.textPrimary),
                  ),
                ),
                Flexible(
                  child: Text(
                    item.title,
                    style: Theme.of(context).textTheme.bodyMedium!.apply(color: highlighted ? BessColors.low : BessColors.semiHigh),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
