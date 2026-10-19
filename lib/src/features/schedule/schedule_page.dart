import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../shared/widgets/buttons/icon_button.dart';
import '../../shared/widgets/header/menu_bar.dart';
import '../../shared/widgets/layouts/templates/site_layout.dart';
import 'schedule_page_controller.dart';
import 'widgets/schedule_body.dart';

/// The current session's weekly schedule, read-only and laid out to be
/// printed (landscape letter): one column per day, each block listing its
/// activities and how full they are.
class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SchedulePageController>(
      // `state.controller` is not set yet while initState runs.
      initState: (_) => Get.find<SchedulePageController>().ensureLoaded(),
      builder:
          (controller) => BessSiteTemplate(
            desktop: ScheduleBody(controller: controller),
            desktopPadding: false,
            menuBar: BessMenuBar<SchedulePageController>(externalPageController: controller),
            centerActions: [
              BessIconButton(
                iconData: LucideIcons.rotateCw500,
                onPressed: controller.reload,
                enabled: !controller.isLoading,
                isLoading: controller.isLoading,
                radius: 8,
              ),
            ],
          ),
    );
  }
}
