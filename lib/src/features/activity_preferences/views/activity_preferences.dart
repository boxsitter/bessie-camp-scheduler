import 'package:bessie/src/features/activity_preferences/views/activity_preferences_cabins.dart';
import 'package:bessie/src/features/activity_preferences/views/activity_preferences_selector_diplomatic.dart';
import 'package:bessie/src/features/activity_preferences/views/camper_selector.dart';
import 'package:bessie/src/ember_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';

import '../../../shared/constants/colors.dart';
import '../../../shared/widgets/containers/rounded_container.dart';
import '../../../shared/widgets/layouts/templates/site_layout.dart';
import '../controllers/activity_preferences_controller_diplomatic.dart';
import '../widgets/header_builders.dart';

class ActivityPreferences extends StatelessWidget {
  const ActivityPreferences({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ActivityPreferencesControllerDiplomatic>(builder: (controller) {
      return BessSiteTemplate(
        desktop: ActivityPreferencesDesktop(
          controller: controller,
        ),
        desktopPadding: false,
        tabletPadding: false,
        menuBar: buildActivityPreferencesMenuBar(controller: controller),
        centerActions: buildActivityPreferencesCenterActions(controller: controller),
      );
    });
  }
}

class ActivityPreferencesDesktop extends StatelessWidget {
  const ActivityPreferencesDesktop({super.key, required this.controller});

  final ActivityPreferencesControllerDiplomatic controller;

  @override
  Widget build(BuildContext context) {
    if (controller.cabinsOpened) {
      return ActivityPreferencesCabins(controller: controller);
    } else {
      return Row(
        children: [
          if (controller.campersOpened)
            BessRoundedContainer(
              width: 200,
              height: double.infinity,
              backgroundColor: BessColors.crust,
              showBorder: true,
              borderThickness: 1,
              borderColor: BessColors.borderPrimary,
              padding: EdgeInsets.only(right: 16, left: 16, top: 16, bottom: 0),
              radius: 32,
              manualBorderRadius: BorderRadius.only(bottomRight: Radius.circular(32), topRight: Radius.circular(32)),
              showShadow: true,
              child: Row(
                children: [
                  if (controller.campersOpened)
                    Expanded(
                      child: CamperSelector(
                        campers: controller.campersInSelectedCabin,
                        selectedCamper: controller.selectedCamper,
                        onSelectCamper: (Camper camper) => controller.setSelectedCamper(camper),
                        isCampersLoaded: controller.isCamperDataLoaded,
                        cabinName: controller.selectedCabin?.$2.displayTitle,
                        entriesSaving: controller.entriesSaving.keys.toSet(),
                        isLoading: controller.isSaving,
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: Row(
              children: [
                Expanded(child: ActivityPreferencesSelectorDiplomatic(controller: controller)),
              ],
            ),
          ),
        ],
      );
    }
  }
}
