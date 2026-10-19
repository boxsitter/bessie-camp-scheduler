import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../shared/widgets/buttons/icon_button.dart';
import '../../../shared/widgets/header/menu_bar.dart';
import '../controllers/activity_preferences_controller.dart';

List<Widget> buildActivityPreferencesCenterActions({required ActivityPreferencesController controller}) {
  const gap = SizedBox(width: 16);
  return [
    BessIconButton(
      iconData: LucideIcons.house500,
      onPressed: controller.toggleCabins,
      selected: controller.showingCabins,
      enabled: controller.selectedGroup != null,
      radius: 8,
    ),
    gap,
    BessIconButton(
      iconData: LucideIcons.usersRound500,
      onPressed: controller.toggleCampersPane,
      selected: controller.campersPaneOpen && !controller.showingCabins,
      enabled: !controller.showingCabins,
      radius: 8,
    ),
    gap,
    BessIconButton(
      iconData: LucideIcons.save500,
      onPressed: controller.save,
      enabled: controller.hasUnsavedChanges && !controller.isSaving,
      isLoading: controller.isSaving,
      radius: 8,
    ),
    gap,
    BessIconButton(
      iconData: LucideIcons.rotateCw500,
      onPressed: controller.reload,
      enabled: !controller.isLoading,
      isLoading: controller.isLoading,
      radius: 8,
    ),
  ];
}

BessMenuBar<ActivityPreferencesController> buildActivityPreferencesMenuBar({required ActivityPreferencesController controller}) {
  return BessMenuBar<ActivityPreferencesController>(externalPageController: controller);
}
