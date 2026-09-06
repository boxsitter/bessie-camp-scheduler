import 'package:bessie/src/shared/constants/colors.dart';
import 'package:bessie/src/shared/widgets/header/menu_bar.dart';
import 'package:flutter/material.dart';


class BessHeader extends StatelessWidget implements PreferredSizeWidget {
  const BessHeader(
      {super.key, required this.menuBar, this.scaffoldKey, this.centerActions = const [], this.trailingWidgets = const []});

  final GlobalKey<ScaffoldState>? scaffoldKey;
  final BessMenuBar menuBar;
  final List<Widget> centerActions;
  final List<Widget> trailingWidgets;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: BessColors.core,
        border: Border(bottom: BorderSide(color: BessColors.semiLow, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Menu Bar
          Container(
            width: 265,
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: BessColors.semiLow, width: 1)),
            ),
            child: menuBar,
          ),

          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  // GetBuilder<SaveController>(builder: (controller) {
                  //   return BessTextIconButton(
                  //     content: controller.isSaving
                  //         ? 'Saving...'
                  //         : controller.isAutoSaving
                  //             ? 'Auto Saving...'
                  //             : 'Save',
                  //     onPressed: controller.save,
                  //     enabled: controller.isSaving == false && controller.isAutoSaving == false && !controller.queueIsEmpty,
                  //     radius: 8,
                  //     backgroundColor: BessColors.crust,
                  //   );
                  // }),
                  // SizedBox(
                  //   width: 16,
                  // ),
                  ...centerActions,
                  Spacer(),
                  ...trailingWidgets,
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(40);
}
