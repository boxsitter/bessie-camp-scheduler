import 'package:bessie/src/shared/widgets/loaders/circular_loader.dart';
import 'package:bessie/src/features/rosters/widgets/activity_switcher.dart';
import 'package:bessie/src/features/rosters/widgets/column_config.dart';
import 'package:bessie/src/features/rosters/widgets/header_builders.dart';
import 'package:bessie/src/features/rosters/widgets/table/data_table.dart';
import 'package:bessie/src/ember_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../shared/widgets/layouts/templates/site_layout.dart';
import 'controllers/rosters_controller.dart';

/// A stateless widget that represents the main Rosters page.
/// It uses a [BessSiteTemplate] to provide a consistent layout
/// and displays the [RostersDesktop] widget for desktop view.
class Rosters extends StatelessWidget {
  const Rosters({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RostersController>(builder: (controller) {
      return BessSiteTemplate(
        desktop: RostersDesktop(
          controller: controller,
        ),
        desktopPadding: false,
        tabletPadding: false,
        menuBar: buildRostersMenuBar(controller: controller),
        centerActions: buildRostersCenterActions(controller: controller),
        trailingWidgets: buildRostersTrailingWidgets(controller: controller),
      );
    });
  }
}

class RostersDesktop extends StatelessWidget {
  const RostersDesktop({
    super.key,
    required this.controller,
  });

  final RostersController controller;

  @override
  Widget build(BuildContext context) {
    final List<RosterGroup> groups = controller.rosterGroups;
    final bool isGrouped = groups.length > 1;
    final isExpanded = (int index) => controller.isGroupExpanded(groups[index]);

    final table = (double constraintsMaxWidth, int index) {
      final RosterGroup group = groups[index];
      final groupField = group.groupByField;
      String? headerTitle = null;
      if (groupField != null) {
        if (groupField is AMABlock) {
          headerTitle = controller.getActivityDependentName(group.items.first, groupField);
        } else {
          headerTitle = '${group.groupByField!.displayTitle} - ${group.title}';
        }
      } else {
        headerTitle = group.title;
      }

      return BessDataTable(
        group: group,
        fields: controller.fields,
        selectedItems: controller.selectedItems,
        getRowDataFromItem: (Rosterable rosterItem) => controller.getRowDataFromItem(rosterItem),
        onToggleRowSelection: (Rosterable rosterItem) => controller.toggleRowSelection(rosterItem),
        onToggleGroupSelection: (RosterGroup rosterGroup) => controller.toggleSelectGroup(rosterGroup),
        onToggleGroupExpanded: (RosterGroup rosterGroup) => controller.toggleGroupExpanded(rosterGroup),
        calculateTableWidths: controller.calculateTableWidths,
        constraintsMaxWidth: constraintsMaxWidth,
        alternateRowColors: controller.alternateRowColors,
        columnSeparators: controller.columnSeparators,
        rowSeparators: controller.rowSeparators,
        compact: controller.compact,
        highContrast: controller.highContrast,
        isGrouped: isGrouped,
        isExpanded: isExpanded(index),
        headerTitle: headerTitle,
        controller: controller,
      );
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        if (controller.initializing == true) {
          return BessCircularLoader();
        } else if (controller.columnConfigOpened) {
          return ColumnConfig(controller: controller);
        } else if (controller.activitySwitcherOpened) {
          return ActivitySwitcher(controller: controller);
        } else {
          return ClipRect(
            clipBehavior: Clip.hardEdge,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Builder(builder: (context) {
                if (!isGrouped) {
                  return table(constraints.maxWidth, 0);
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ListView.builder(
                          clipBehavior: Clip.none,
                          itemCount: controller.rosterGroups.length,
                          itemBuilder: (context, index) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                table(constraints.maxWidth, index),
                                SizedBox(height: isExpanded(index) ? 16 : 8),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  );
                }
              }),
            ),
          );
        }
      },
    );
  }
}
