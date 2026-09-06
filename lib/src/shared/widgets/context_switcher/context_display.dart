import 'package:bessie/src/shared/constants/colors.dart';
import 'package:bessie/src/shared/styles/text_styles.dart';
import 'package:bessie/src/shared/widgets/buttons/card_button.dart';
import 'package:bessie/src/shared/widgets/context_switcher/context_switcher.dart';
import 'package:bessie/src/shared/widgets/context_switcher/controller/session_selector_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class ContextDisplay extends StatelessWidget {
  const ContextDisplay({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    SessionSelectorController controller = Get.find<SessionSelectorController>();
    return CardButton(
      backgroundColor: BessColors.element1,
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 0),
      height: 55,
      onPressed: () => showContextSwitcher(),
      showBorder: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Obx( () {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.seasonName.value,
                  style: BessTextStyles.tiny,
                ),
                Text(
                  controller.sessionName.value,
                  style: BessTextStyles.standardBold,
                )
              ],
            );
          }),

          SizedBox(width: 15),

          const Icon(LucideIcons.folderCog),
        ],
      ),
    );
  }
}
