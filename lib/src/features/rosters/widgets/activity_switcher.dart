import 'package:bessie/src/shared/styles/text_styles.dart';
import 'package:bessie/src/shared/widgets/buttons/card_button.dart';
import 'package:bessie/src/shared/widgets/containers/titled_container.dart';
import 'package:bessie/src/shared/widgets/misc/card_selector.dart';
import 'package:bessie/src/ember_core.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../shared/constants/colors.dart';
import '../../../shared/constants/sizes.dart';
import '../../../shared/widgets/buttons/action_initiator.dart';
import '../../../shared/widgets/misc/widget_list.dart';
import '../../../shared/widgets/wrappers/tint.dart';
import '../controllers/rosters_controller.dart';

class ActivitySwitcher extends StatelessWidget {
  const ActivitySwitcher({
    super.key,
    required this.controller,
  });

  final RostersController controller;

  @override
  Widget build(BuildContext context) {
    final List<ActivityDependent>? filteredDependents = controller.selectedAma != null
        ? controller.activityDependents.where((d) => d.blockRef == controller.selectedAma!.id).toList()
        : null;
    return Container(
      padding: const EdgeInsets.all(BessSizes.md),
      decoration: BoxDecoration(border: BorderDirectional(bottom: BorderSide(color: BessColors.borderPrimary, width: 2))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TitledContainer(
              title: 'Select Activity Period',
              child: CardSelector(
                items: controller.amas,
                onSelectItem: controller.setSelectedAma,
                selectedItem: controller.selectedAma,
                isHorizontal: false,
                childBuilder: (BuildContext context, AMABlock item) {
                  return SizedBox(
                    height: 25,
                    child: Center(
                      child: Text(
                        item.displayTitle,
                        style: BessTextStyles.standardBold.copyWith(
                          // This will now correctly find the foregroundColor provided by Tint.
                          color: Tint.of(context)?.foregroundColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SizedBox(width: BessSizes.spaceBtwItems),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: TitledContainer(
                    title: 'Select Activity',
                    child: controller.selectedAma != null
                        ? ListView.builder(
                            clipBehavior: Clip.none,
                            itemCount: filteredDependents!.length,
                            itemBuilder: (context, index) {
                              final item = filteredDependents[index];
                              final PrincipalActivity? principalActivity = controller.principalActivities[item.principalPar];
                              final int countAdded = controller.selectedItems.length -
                                  (controller.selectedItems.where((camper) => item.camperRefs.contains(camper.id))).length;
                              final bool? atCap = principalActivity != null
                                  ? item.camperRefs.length + countAdded > principalActivity.capacity
                                  : null;

            // Determine the background color based on preference or capacity
            final Color? preferenceColor = controller.getActivityPreferenceColor(item);

            List<(bool, Color)>? tintConditions;
            if (preferenceColor != null) {
              tintConditions = [(true, preferenceColor)];
            } else if (atCap != null) {
              tintConditions = [
                (controller.selectedActivity == item, BessColors.primary),
                (atCap, BessColors.red),
                (!atCap, BessColors.green),
              ];
            }


                              return Padding(
                                // Add some vertical padding between items for better spacing
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: CardButton(
                tintConditions: tintConditions,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Expanded helps prevent text overflow issues if the name is long
                                      Expanded(
                                        child: Text(
                                          principalActivity?.name ?? 'Error',
                                          style: BessTextStyles.boldCardTitle,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      // Add some spacing between the title and the capacity info
                                      const SizedBox(width: 16),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          if (controller.selectedItems.isNotEmpty && atCap != null)
                                            Text(
                                              '$countAdded+',
                                              overflow: TextOverflow.clip,
                                              // Use the atCap boolean to decide the color
                                              style: BessTextStyles.standard.copyWith(
                                                color: atCap ? BessColors.red : BessColors.green,
                                              ),
                                            ),
                                          const SizedBox(width: 4), // A little space for readability
                                          Text(
                                            '${item.camperRefs.length}/${principalActivity?.capacity}',
                                            overflow: TextOverflow.clip,
                                            style: BessTextStyles.standardBold,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  onPressed: () => controller.setSelectedActivity(item),
                                  height: 60,
                                ),
                              );
                            },
                          )
                        : Center(child: Text('Select an activity period first!', style: BessTextStyles.tableHeaderSecondary)),
)
                ),
                Expanded(
                  child: TitledContainer(
                    title: 'Summary',
                    child: controller.selectedItems.isNotEmpty
                        ? WidgetList<Rosterable>(
                            items: controller.selectedItems.toList(),
                            itemBuilder: (context, item) {
                              String? selectedAmaId = controller.selectedAma?.id;
                              String? selectedActivityTitle =
                                  controller.principalActivities[controller.selectedActivity?.principalPar]?.displayTitle;
                              Widget trailing;
                              if (selectedAmaId == null || selectedActivityTitle == null) {
                                trailing = Text('No change', style: BessTextStyles.standardBold);
                              } else {
                                String? oldActivityId = item.activityAssignmentRefs[selectedAmaId];
                                String? oldActivityTitle;
                                if (oldActivityId != null) {
                                  ActivityDependent? oldActivity;
                                  for (ActivityDependent activityDep in controller.activityDependents) {
                                    if (activityDep.id == oldActivityId) {
                                      oldActivity = activityDep;
                                    }
                                  }
                                  oldActivityTitle = controller.principalActivities[oldActivity?.principalPar]?.displayTitle;
                                }
                                if (oldActivityId == null || oldActivityTitle == null) {
                                  trailing = Text('Assign to $selectedActivityTitle', style: BessTextStyles.standardBold);
                                } else if (oldActivityId == controller.selectedActivity!.id) {
                                  trailing = Text('No change', style: BessTextStyles.standardBold);
                                } else {
                                  trailing =
                                      Text('$oldActivityTitle to $selectedActivityTitle', style: BessTextStyles.standardBold);
                                  trailing = Row(
                                    children: [
                                      Text(oldActivityTitle, style: BessTextStyles.standardBold),
                                      SizedBox(
                                        width: 8,
                                      ),
                                      Icon(LucideIcons.arrowRight600),
                                      SizedBox(
                                        width: 8,
                                      ),
                                      Text(selectedActivityTitle, style: BessTextStyles.standardBold),
                                    ],
                                  );
                                }
                              }

                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text(item.displayTitle, style: BessTextStyles.standard)),
                                    trailing,
                                  ],
                                ),
                              );
                            },
                          )
                        : Center(child: Text('Select some campers first!', style: BessTextStyles.tableHeaderSecondary)),
                  ),
                ),
                SizedBox(
                  height: BessSizes.spaceBtwItems,
                ),
                ActionInitiator(
                  onPressed: () => controller.assignSelected(),
                  disabled:
                      controller.selectedAma == null || controller.selectedActivity == null || controller.selectedItems.isEmpty,
                  awaiting: controller.assigningCamper,
                  enabledText: 'Commit',
                  disabledText: 'Nothing to commit yet',
                  awaitingText: 'One moment...',
                  width: double.infinity,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
