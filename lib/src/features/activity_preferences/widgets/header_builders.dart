import 'package:bessie/src/shared/widgets/buttons/icon_button.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../shared/widgets/header/menu_bar.dart';
import '../controllers/activity_preferences_controller_diplomatic.dart';

List<Widget> buildActivityPreferencesCenterActions({
  required ActivityPreferencesControllerDiplomatic controller,
}) {
  return [
    BessIconButton(
      iconData: LucideIcons.house500,
      onPressed: () => controller.setCabinsOpened(!controller.cabinsOpened),
      selected: controller.cabinsOpened,
      enabled: controller.selectedCabin != null,
      radius: 8,
    ),

    SizedBox(width: 16,),

    BessIconButton(
      iconData: LucideIcons.usersRound500,
      onPressed: () => controller.setCampersOpened(!controller.campersOpened),
      selected: controller.campersOpened,
      enabled: !controller.cabinsOpened,
      radius: 8,
    ),

    SizedBox(width: 16,),

    BessIconButton(
      iconData: LucideIcons.save500,
      onPressed: controller.save,
      enabled: controller.entriesToSave.isNotEmpty && controller.isSaving == false,
      isLoading: controller.isSaving == true,
      radius: 8,
    ),

    //if (controller.cabinsOpened == true)
    SizedBox(width: 16,),

    //if (controller.cabinsOpened == true)
    BessIconButton(
      iconData: LucideIcons.rotateCw500,
      onPressed: controller.reload,
      enabled: controller.isLoading == false,
      isLoading: controller.isLoading,
      radius: 8,
    ),
  ];
}

BessMenuBar<ActivityPreferencesControllerDiplomatic> buildActivityPreferencesMenuBar({
  required ActivityPreferencesControllerDiplomatic controller,
}) {
  return BessMenuBar<ActivityPreferencesControllerDiplomatic>(
    externalPageController: controller,
  );
}
