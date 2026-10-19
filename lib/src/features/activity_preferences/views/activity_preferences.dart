import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../shared/widgets/layouts/templates/site_layout.dart';
import '../controllers/activity_preferences_controller.dart';
import '../widgets/header_builders.dart';
import 'activity_preferences_desktop.dart';

/// Collects each camper's activity requests and vetoes: pick a cabin, pick a
/// camper, drag activities into place.
class ActivityPreferences extends StatelessWidget {
  const ActivityPreferences({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ActivityPreferencesController>(
      // `state.controller` is not set yet while initState runs.
      initState: (_) => Get.find<ActivityPreferencesController>().ensureLoaded(),
      builder:
          (controller) => BessSiteTemplate(
            desktop: ActivityPreferencesDesktop(controller: controller),
            desktopPadding: false,
            tabletPadding: false,
            menuBar: buildActivityPreferencesMenuBar(controller: controller),
            centerActions: buildActivityPreferencesCenterActions(controller: controller),
          ),
    );
  }
}
