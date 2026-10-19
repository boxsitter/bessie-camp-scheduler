import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants/colors.dart';
import '../../styles/text_styles.dart';
import '../buttons/card_button.dart';
import 'context_switcher.dart';
import 'controller/session_selector_controller.dart';

/// The current season and session; tap to change session.
class ContextDisplay extends StatelessWidget {
  const ContextDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SessionSelectorController>();
    return CardButton(
      backgroundColor: BessColors.element1,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      height: 55,
      onPressed: showContextSwitcher,
      showBorder: false,
      child: Row(
        children: [
          Expanded(
            child: Obx(
              () => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(controller.seasonName, style: BessTextStyles.tiny, overflow: TextOverflow.ellipsis),
                  Text(controller.sessionName, style: BessTextStyles.standardBold, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
          const SizedBox(width: 15),
          const Icon(LucideIcons.folderCog),
        ],
      ),
    );
  }
}
