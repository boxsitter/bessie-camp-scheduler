import 'package:bessie/src/shared/widgets/buttons/text_icon_button.dart';
import 'package:bessie/src/features/rosters/widgets/searchbar.dart';
import 'package:bessie/src/ember_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../shared/constants/colors.dart';
import '../../../shared/styles/text_styles.dart';
import '../../../shared/widgets/buttons/icon_button.dart';
import '../../../shared/widgets/header/menu_bar.dart';
import '../controllers/rosters_controller.dart';

List<Widget> buildRostersCenterActions({
  required RostersController controller,
}) {
  return [
    BessIconButton(
      iconData: LucideIcons.columns3Cog500,
      onPressed: () => controller.toggleSecondaryPage(1),
      selected: controller.columnConfigOpened,
      radius: 8,
      backgroundColor: BessColors.crust,
    ),
    SizedBox(
      width: 16,
    ),
    BessIconButton(
      iconData: LucideIcons.arrowRightLeft500,
      onPressed: () => controller.toggleSecondaryPage(2),
      selected: controller.activitySwitcherOpened,
      radius: 8,
      backgroundColor: BessColors.crust,
    ),
    SizedBox(
      width: 64,
    ),
    BessTextIconButton(
      content: controller.selectedItems.containsAll(controller.roster)
          ? 'Unselect All'
          : controller.selectedItems.isEmpty
              ? 'Select All'
              : 'Unselect All',
      onPressed: controller.toggleSelectAll,
      selected: controller.selectedItems.containsAll(controller.roster),
      radius: 8,
      backgroundColor: BessColors.crust,
      width: 100,
    ),
    SizedBox(
      width: 16,
    ),
    BessIconButton(
      iconData: LucideIcons.userRoundCheck500,
      onPressed: controller.toggleArrived,
      selected: controller.activitySwitcherOpened,
      enabled: controller.selectedItems.isNotEmpty,
      radius: 8,
      backgroundColor: BessColors.crust,
    ),
    if (controller.columnConfigOpened == false &&
        controller.activitySwitcherOpened == false &&
        controller.fields.firstWhereOrNull((element) => element is AMABlock) != null)
      SizedBox(
        width: 16,
      ),
    if (controller.columnConfigOpened == false &&
        controller.activitySwitcherOpened == false &&
        controller.fields.firstWhereOrNull((element) => element is AMABlock) != null)
      BessIconButton(
        iconData: LucideIcons.squareStack500,
        onPressed: controller.toggleAssignmentRepetition,
        selected: controller.showAssignmentRepetition,
        radius: 8,
        backgroundColor: BessColors.crust,
      ),
    if (controller.activitySwitcherOpened == true)
      SizedBox(
        width: 16,
      ),
    if (controller.activitySwitcherOpened == true)
      BessIconButton(
        iconData: LucideIcons.laugh500,
        onPressed: controller.togglePreferenceColors,
        selected: controller.showPreferenceColors,
        radius: 8,
        backgroundColor: BessColors.crust,
      ),
  ];
}

BessMenuBar<RostersController> buildRostersMenuBar({
  required RostersController controller,
}) {
  return BessMenuBar<RostersController>(
    externalPageController: controller,
    fileItems: [
      ShadContextMenuItem(child: const Text('Import From Ultracamp'), onPressed: controller.importCsv),
      ShadSeparator.horizontal(
        margin: const EdgeInsets.symmetric(vertical: 4),
        color: BessColors.borderPrimary,
      ),
      ShadContextMenuItem(
        child: const Text('Export As CSV'),
        onPressed: controller.exportAsCsv,
      ),
      ShadContextMenuItem(
        child: const Text('Export Activity Backup'),
        onPressed: controller.exportCamperBackup,
        enabled: controller.selectedItems.isNotEmpty,
      ),
      //const ShadContextMenuItem(child: Text('Print')),
    ],
    viewItems: [
      // const ShadContextMenuItem(
      //   leading: Icon(LucideIcons.check, color: Colors.transparent),
      //   child: Text('Paginated'),
      // ),
      ShadContextMenuItem(
        child: const Text('Alternate Row Colors'),
        onPressed: controller.toggleAlternateRowColors,
        leading: controller.alternateRowColors
            ? Icon(
                LucideIcons.check,
                color: BessColors.textPrimary,
              )
            : const Icon(
                LucideIcons.check,
                color: Colors.transparent,
              ),
      ),
      ShadContextMenuItem(
        child: const Text('High Contrast'),
        onPressed: controller.toggleHighContrast,
        leading: controller.highContrast
            ? Icon(
                LucideIcons.check,
                color: BessColors.textPrimary,
              )
            : const Icon(LucideIcons.check, color: Colors.transparent),
      ),
      ShadContextMenuItem(
        child: const Text('Row Dividers'),
        onPressed: controller.toggleRowSeparators,
        leading: controller.rowSeparators
            ? Icon(
                LucideIcons.check,
                color: BessColors.textPrimary,
              )
            : const Icon(
                LucideIcons.check,
                color: Colors.transparent,
              ),
      ),
      ShadContextMenuItem(
        child: const Text('Column Dividers'),
        onPressed: controller.toggleColumnSeparators,
        leading: controller.columnSeparators
            ? Icon(
                LucideIcons.check,
                color: BessColors.textPrimary,
              )
            : const Icon(
                LucideIcons.check,
                color: Colors.transparent,
              ),
      ),
      ShadContextMenuItem(
        child: const Text('Compact'),
        onPressed: controller.toggleCompact,
        leading: controller.compact
            ? Icon(
                LucideIcons.check,
                color: BessColors.textPrimary,
              )
            : const Icon(
                LucideIcons.check,
                color: Colors.transparent,
              ),
      ),
      ShadContextMenuItem(
        child: const Text('Repetition View'),
        onPressed: controller.toggleAssignmentRepetition,
        leading: controller.showAssignmentRepetition
            ? Icon(
                LucideIcons.check,
                color: BessColors.textPrimary,
              )
            : const Icon(
                LucideIcons.check,
                color: Colors.transparent,
              ),
      ),
      ShadContextMenuItem(
        child: const Text('Preference Colors'),
        onPressed: controller.togglePreferenceColors,
        leading: controller.showPreferenceColors
            ? Icon(
                LucideIcons.check,
                color: BessColors.textPrimary,
              )
            : const Icon(
                LucideIcons.check,
                color: Colors.transparent,
              ),
      ),
    ],
    editItems: [
      ShadContextMenuItem(
        child: const Text('Invert Selection'),
        onPressed: controller.invertSelection,
        enabled: controller.selectedItems.isNotEmpty,
      ),
      ShadSeparator.horizontal(
        margin: const EdgeInsets.symmetric(vertical: 4),
        color: BessColors.borderPrimary,
      ),
      ShadContextMenuItem(
        child: const Text('Rank Random'),
        onPressed: controller.rankRandomSelected,
        enabled: controller.selectedItems.isNotEmpty,
      ),
      ShadContextMenuItem(
        child: const Text('Clear Preferences'),
        onPressed: controller.clearPrefsSelected,
        enabled: controller.selectedItems.isNotEmpty,
      ),
      ShadSeparator.horizontal(
        margin: const EdgeInsets.symmetric(vertical: 4),
        color: BessColors.borderPrimary,
      ),
      ShadContextMenuItem(
        child: const Text('Assign To Activity'),
        onPressed: controller.assignSelected,
        enabled: controller.selectedItems.isNotEmpty && controller.selectedAma != null && controller.selectedActivity != null,
      ),
      ShadContextMenuItem(
        child: const Text('Smart Assign All'),
        onPressed: controller.smartAssignAll,
      ),
      ShadContextMenuItem(
        child: const Text('Smart Assign Selected'),
        onPressed: controller.smartAssignSelected,
        enabled: controller.selectedItems.isNotEmpty,
      ),
      ShadContextMenuItem(
        child: const Text('Unassign From Selected Activity'),
        onPressed: controller.unassignSelectedFromActivity,
        enabled: controller.selectedItems.isNotEmpty && controller.selectedAma != null && controller.selectedActivity != null,
      ),
      ShadContextMenuItem(
        child: const Text('Unassign For Selected Period'),
        onPressed: controller.unassignSelectedFromAma,
        enabled: controller.selectedItems.isNotEmpty && controller.selectedAma != null,
      ),
      ShadContextMenuItem(
        child: Text('Unassign From All Periods',
            style: controller.isSingleSelected() || controller.isMultiSelected()
                ? BessTextStyles.standard.copyWith(color: BessColors.red)
                : BessTextStyles.standardSecondary),
        onPressed: controller.unassignSelectedFromAll,
        enabled: controller.selectedItems.isNotEmpty,
      ),
      ShadContextMenuItem(
        child: const Text('Set Cabin Of Campers'),
        onPressed: controller.setCabin,
        enabled: controller.selectedItems.isNotEmpty,
      ),
      ShadContextMenuItem(
        child: const Text('Swap Cabins Of Campers'),
        onPressed: controller.swapCabinsOfSelected,
        enabled: controller.selectedItems.isNotEmpty,
      ),
      ShadSeparator.horizontal(
        margin: const EdgeInsets.symmetric(vertical: 4),
        color: BessColors.borderPrimary,
      ),
      ShadContextMenuItem(
        child: Text('Delete',
            style: controller.isSingleSelected() || controller.isMultiSelected()
                ? BessTextStyles.standard.copyWith(color: BessColors.red)
                : BessTextStyles.standardSecondary),
        onPressed: controller.deleteSelected,
        enabled: controller.isSingleSelected() || controller.isMultiSelected(),
      ),
    ],
  );
}

List<Widget> buildRostersTrailingWidgets({
  required RostersController controller,
}) {
  return [
    BessSearchbar(
      onSearchChange: controller.setSearchQuery,
      noMatches: controller.getFilteredRoster().isEmpty,
      controller: controller.searchController,
    ),
  ];
}
