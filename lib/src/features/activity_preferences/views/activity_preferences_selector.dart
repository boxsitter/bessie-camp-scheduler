import 'package:flutter/material.dart';

import '../../../models/camper.dart';
import '../../../models/enums.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/styles/text_styles.dart';
import '../../../shared/widgets/buttons/card_button.dart';
import '../controllers/activity_preferences_controller.dart';
import '../widgets/activity_library.dart';
import '../widgets/preference_drop_zone.dart';

/// Where the selected camper's activities are dragged into place.
class ActivityPreferencesSelector extends StatelessWidget {
  const ActivityPreferencesSelector({super.key, required this.controller});

  final ActivityPreferencesController controller;

  @override
  Widget build(BuildContext context) {
    final camper = controller.selectedCamper;
    if (camper == null || controller.board == null) return const SizedBox();

    final skills = controller.skillsMode;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CamperHeader(controller: controller, camper: camper),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ActivityLibrary(
                    activities: controller.libraryActivities,
                    categories: controller.categories,
                    selectedCategory: controller.selectedCategory,
                    skillsMode: skills,
                    canSwitchMode: controller.canSwitchMode,
                    onCategorySelected: controller.selectCategory,
                    onModeSelected: controller.setSkillsMode,
                    onDrop: (activity) => controller.place(activity, null),
                    onDragStarted: controller.onDragStarted,
                    onActivityTap: controller.showActivityInfo,
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 300,
                  child: Column(
                    children: [
                      Expanded(
                        child: PreferenceDropZone(
                          title: 'Yes Please',
                          color: BessColors.green,
                          activities: controller.chosenActivities(PreferenceKind.request),
                          remaining: controller.remaining(PreferenceKind.request),
                          highlightRemaining: skills,
                          onDrop: (activity) => controller.place(activity, PreferenceKind.request),
                          onDragStarted: controller.onDragStarted,
                          onActivityTap: controller.showActivityInfo,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: PreferenceDropZone(
                          title: 'No Thanks',
                          color: BessColors.red,
                          activities: controller.chosenActivities(PreferenceKind.veto),
                          remaining: controller.remaining(PreferenceKind.veto),
                          highlightRemaining: skills,
                          onDrop: (activity) => controller.place(activity, PreferenceKind.veto),
                          onDragStarted: controller.onDragStarted,
                          onActivityTap: controller.showActivityInfo,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Who is being edited, whether it is saved, and the button to mark a camper
/// as done without choosing anything.
class _CamperHeader extends StatelessWidget {
  const _CamperHeader({required this.controller, required this.camper});

  final ActivityPreferencesController controller;
  final Camper camper;

  @override
  Widget build(BuildContext context) {
    final pending = controller.isPending(camper.id);
    final status =
        pending
            ? 'Saving...'
            : camper.preferencesSubmitted
            ? 'Saved'
            : 'Not saved yet';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(camper.fullNamePreferred, style: BessTextStyles.boldCardTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text('${controller.selectedCabinTitle ?? ''} · $status', style: BessTextStyles.largerLabel),
            ],
          ),
        ),
        if (!camper.preferencesSubmitted && !pending)
          CardButton(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            baseTint: BessColors.green,
            onPressed: controller.markSelectedDone,
            child: Center(
              child: Text(controller.board!.isEmpty ? 'No preferences - mark as done' : 'Mark as done', style: BessTextStyles.standard),
            ),
          ),
      ],
    );
  }
}
