import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../shared/widgets/layouts/templates/site_layout.dart';
import 'controllers/rosters_controller.dart';
import 'widgets/header_builders.dart';
import 'widgets/roster_body.dart';

/// The Rosters page: the session's campers in an editable table, with the
/// column settings and the activity switcher as alternative panels.
class Rosters extends StatelessWidget {
  const Rosters({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RostersController>(
      // The navigation observer normally starts the roster; this makes sure
      // it is running whenever the page is on screen.
      initState:
          (_) => WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Get.isRegistered<RostersController>()) Get.find<RostersController>().activate();
          }),
      builder:
          (controller) => BessSiteTemplate(
            desktop: RostersBody(controller: controller),
            desktopPadding: false,
            tabletPadding: false,
            menuBar: buildRostersMenuBar(controller: controller),
            centerActions: buildRostersCenterActions(controller: controller),
            trailingWidgets: buildRostersTrailingWidgets(controller: controller),
          ),
    );
  }
}
