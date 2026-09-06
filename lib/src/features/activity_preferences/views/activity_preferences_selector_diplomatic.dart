import 'package:bessie/src/shared/styles/text_styles.dart';
import 'package:bessie/src/shared/widgets/buttons/card_button.dart';
import 'package:bessie/src/shared/widgets/containers/titled_container.dart';
import 'package:bessie/src/shared/widgets/loaders/circular_loader.dart';
import 'package:bessie/src/shared/widgets/misc/tab_switcher.dart';
import 'package:bessie/src/shared/widgets/misc/widget_list.dart';
import 'package:bessie/src/features/activity_preferences/widgets/draggable_container.dart';
import 'package:bessie/src/ember_core.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../shared/constants/colors.dart';
import '../../../shared/widgets/misc/widget_grid.dart';
import '../controllers/activity_preferences_controller_diplomatic.dart';

class ActivityPreferencesSelectorDiplomatic extends StatelessWidget {
  ActivityPreferencesSelectorDiplomatic({super.key, required this.controller});

  final ActivityPreferencesControllerDiplomatic controller;

  @override
  Widget build(BuildContext context) {
    if (controller.isActivityDataLoaded == false) return const BessCircularLoader();

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: DragTarget<PrincipalActivity>(
                    onAcceptWithDetails: (data) => controller.addToNeutral(data.data),
                    builder: (context, candidateData, rejectedData) {
                      return TitledContainer(
                        title: 'Activity Library (I\'d Be Open To Trying It)',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (controller.selectedCategory != ActivityCategory.skills)
                                Container(
                                  child: TabSwitcher<ActivityCategory>(
                                    items: controller.categories,
                                    selectedItem: controller.selectedCategory ?? controller.categories[0],
                                    onItemSelected: (item) => controller.setSelectedCategory(item),
                                  ),
                                  width: double.infinity,
                                ),
                              if (controller.selectedCategory != ActivityCategory.skills)
                                SizedBox(
                                  height: 32,
                                ),
                              SizedBox(
                                child: WidgetGrid(
                                  items:
                                      controller.getActivitiesInCategory(controller.selectedCategory ?? controller.categories[0]),
                                  runSpacing: 4,
                                  spacing: 2,
                                  itemBuilder: (context, item) {
                                    return BessDraggableContainer<PrincipalActivity>(
                                      item: item,
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                      onDragStarted: () => controller.onDragStarted(item),
                                      onDragEnd: (_) => controller.onDragEnd(),
                                    );
                                  },
                                ),
                                width: double.infinity,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  height: 16,
                ),
                Row(
                  children: [
                    Expanded(
                      child: CardButton(
                        tintConditions: [(controller.selectedCategory != ActivityCategory.skills, BessColors.primary)],
                        onPressed: () => controller.setSelectedCategory(controller.categories.first),
                        child: Center(
                          child: Text(
                            'Standard Activities',
                            style: BessTextStyles.standard,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 16,
                    ),
                    Expanded(
                      child: CardButton(
                        tintConditions: [(controller.selectedCategory == ActivityCategory.skills, BessColors.yellow)],
                        onPressed: () => controller.setSelectedCategory(ActivityCategory.skills),
                        child: Center(
                          child: Text(
                            'Skills Recs',
                            style: BessTextStyles.standard,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 16,
          ),

          // Deny Area
          SizedBox(
            width: 300,
            child: Column(
              children: [
                Expanded(
                  child: DragTarget<PrincipalActivity>(
                    onAcceptWithDetails: (data) => controller.addToRequested(data.data),
                    builder: (context, candidateData, rejectedData) {
                      return TitledContainer(
                        title: 'Yes Please',
                        baseTint: BessColors.green,
                        padding: EdgeInsets.zero,
                        trailing: Text(
                          '${controller.getRemaining(true, controller.selectedCategory == ActivityCategory.skills)} available requests',
                          style: BessTextStyles.standard.copyWith(
                              color:
                                  controller.selectedCategory == ActivityCategory.skills ? BessColors.yellow : BessColors.green),
                        ),
                        child: Builder(builder: (context) {
                          if (controller.requestedActivities.isEmpty) {
                            return Center(
                                child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.replace,
                                  color: BessColors.green,
                                ),
                                const SizedBox(
                                  height: 16,
                                ),
                                Text(
                                  'Drag And Drop Here',
                                  style: BessTextStyles.standard.copyWith(color: BessColors.green),
                                )
                              ],
                            ));
                          }
                          return WidgetList(
                            items: controller.getFilteredActivities(true, controller.selectedCategory == ActivityCategory.skills),
                            itemBuilder: (context, item) {
                              return BessDraggableContainer<PrincipalActivity>(
                                item: item,
                                padding: const EdgeInsets.only(
                                  left: 32,
                                  right: 32,
                                  bottom: 0,
                                  top: 16,
                                ),
                                onDragStarted: () => controller.onDragStarted(item),
                                onDragEnd: (_) => controller.onDragEnd(),
                              );
                            },
                          );
                        }),
                      );
                    },
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                Expanded(
                  child: DragTarget<PrincipalActivity>(
                    onAcceptWithDetails: (data) => controller.addToVetoed(data.data),
                    builder: (context, candidateData, rejectedData) {
                      return TitledContainer(
                        title: 'No Thanks',
                        baseTint: BessColors.red,
                        padding: EdgeInsets.zero,
                        trailing: Text(
                          '${controller.getRemaining(false, controller.selectedCategory == ActivityCategory.skills)} available vetoes',
                          style: BessTextStyles.standard.copyWith(
                              color: controller.selectedCategory == ActivityCategory.skills ? BessColors.yellow : BessColors.red),
                        ),
                        child: Builder(builder: (context) {
                          if (controller.vetoedActivities.isEmpty) {
                            return Center(
                                child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.replace,
                                  color: BessColors.red,
                                ),
                                const SizedBox(
                                  height: 16,
                                ),
                                Text(
                                  'Drag And Drop Here',
                                  style: BessTextStyles.standard.copyWith(color: BessColors.red),
                                )
                              ],
                            ));
                          }
                          return WidgetList(
                            items: controller.getFilteredActivities(false, controller.selectedCategory == ActivityCategory.skills),
                            itemBuilder: (context, item) {
                              return BessDraggableContainer<PrincipalActivity>(
                                item: item,
                                padding: const EdgeInsets.only(
                                  left: 32,
                                  right: 32,
                                  bottom: 0,
                                  top: 16,
                                ),
                                onDragStarted: () => controller.onDragStarted(item),
                                onDragEnd: (_) => controller.onDragEnd(),
                              );
                            },
                          );
                        }),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Accept Area
        ],
      ),
    );
  }
}
