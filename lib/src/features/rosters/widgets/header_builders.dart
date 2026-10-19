import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../shared/constants/colors.dart';
import '../../../shared/styles/text_styles.dart';
import '../../../shared/widgets/buttons/icon_button.dart';
import '../../../shared/widgets/buttons/text_icon_button.dart';
import '../../../shared/widgets/header/menu_bar.dart';
import '../controllers/rosters_controller.dart';
import 'roster_importer.dart';
import 'searchbar.dart';

/// The page's toolbar: panels, selection and the toggles that go with them.
List<Widget> buildRostersCenterActions({required RostersController controller}) {
  const gap = SizedBox(width: 16);
  final showingTable = !controller.columnConfigOpened && !controller.activitySwitcherOpened;

  Widget iconButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
    bool selected = false,
    bool enabled = true,
  }) => Tooltip(
    message: tooltip,
    child: BessIconButton(
      iconData: icon,
      onPressed: onPressed,
      selected: selected,
      enabled: enabled,
      radius: 8,
      backgroundColor: BessColors.crust,
    ),
  );

  return [
    iconButton(
      tooltip: 'Columns, sorting and grouping',
      icon: LucideIcons.columns3Cog500,
      onPressed: controller.toggleColumnConfig,
      selected: controller.columnConfigOpened,
    ),
    if (controller.canEdit) ...[
      gap,
      iconButton(
        tooltip: 'Move campers between activities',
        icon: LucideIcons.arrowRightLeft500,
        onPressed: controller.toggleActivitySwitcher,
        selected: controller.activitySwitcherOpened,
      ),
    ],
    const SizedBox(width: 64),
    BessTextIconButton(
      content: controller.hasSelection ? 'Unselect All' : 'Select All',
      onPressed: controller.toggleSelectAll,
      selected: controller.allVisibleSelected,
      radius: 8,
      backgroundColor: BessColors.crust,
      width: 100,
    ),
    if (controller.canEdit) ...[
      gap,
      iconButton(
        tooltip: 'Toggle arrived for the selected campers',
        icon: LucideIcons.userRoundCheck500,
        onPressed: controller.toggleArrived,
        enabled: controller.hasSelection,
      ),
    ],
    if (showingTable && controller.hasBlockColumns) ...[
      gap,
      iconButton(
        tooltip: 'Highlight repeated activities',
        icon: LucideIcons.squareStack500,
        onPressed: controller.toggleAssignmentRepetition,
        selected: controller.showAssignmentRepetition,
      ),
    ],
    if (controller.activitySwitcherOpened) ...[
      gap,
      iconButton(
        tooltip: 'Color activities by the selected camper\'s preferences',
        icon: LucideIcons.laugh500,
        onPressed: controller.togglePreferenceColors,
        selected: controller.showPreferenceColors,
      ),
    ],
  ];
}

ShadContextMenuItem _toggleItem(String label, bool on, VoidCallback onPressed) => ShadContextMenuItem(
  onPressed: onPressed,
  leading: Icon(LucideIcons.check, color: on ? BessColors.textPrimary : Colors.transparent),
  child: Text(label),
);

Widget _divider() => ShadSeparator.horizontal(margin: const EdgeInsets.symmetric(vertical: 4), color: BessColors.borderPrimary);

Widget _destructiveLabel(String label, {required bool enabled}) =>
    Text(label, style: enabled ? BessTextStyles.standard.copyWith(color: BessColors.red) : BessTextStyles.standardSecondary);

BessMenuBar<RostersController> buildRostersMenuBar({required RostersController controller}) {
  final hasSelection = controller.hasSelection;
  final canEdit = controller.canEdit;
  final style = controller.style;

  return BessMenuBar<RostersController>(
    externalPageController: controller,
    fileItems: [
      if (canEdit) ...[
        ShadContextMenuItem(child: const Text('Import From Ultracamp'), onPressed: () => showRosterImporter(controller)),
        _divider(),
      ],
      ShadContextMenuItem(child: const Text('Export As CSV'), onPressed: controller.exportCsv),
      ShadContextMenuItem(child: const Text('Export Activity Backup'), onPressed: controller.exportBackup, enabled: hasSelection),
      if (canEdit)
        ShadContextMenuItem(
          child: const Text('Download Smart Assign Report'),
          onPressed: controller.exportEvaluationReport,
          enabled: controller.lastRunReport != null,
        ),
    ],
    viewItems: [
      _toggleItem('Alternate Row Colors', style.alternateRowColors, controller.toggleAlternateRowColors),
      _toggleItem('High Contrast', style.highContrast, controller.toggleHighContrast),
      _toggleItem('Row Dividers', style.rowSeparators, controller.toggleRowSeparators),
      _toggleItem('Column Dividers', style.columnSeparators, controller.toggleColumnSeparators),
      _toggleItem('Compact', style.compact, controller.toggleCompact),
      _toggleItem('Expand Groups', controller.expandedByDefault, controller.toggleExpandedByDefault),
      _toggleItem('Repetition View', controller.showAssignmentRepetition, controller.toggleAssignmentRepetition),
      _toggleItem('Preference Colors', controller.showPreferenceColors, controller.togglePreferenceColors),
    ],
    editItems: [
      ShadContextMenuItem(child: const Text('Invert Selection'), onPressed: controller.invertSelection, enabled: hasSelection),
      if (canEdit) ...[
        _divider(),
        ShadContextMenuItem(child: const Text('Clear Preferences'), onPressed: controller.clearPreferencesOfSelected, enabled: hasSelection),
        ShadContextMenuItem(
          leading: const Icon(LucideIcons.flaskConical),
          child: const Text('Rank Random (testing only)'),
          onPressed: controller.rankRandomSelected,
          enabled: hasSelection,
        ),
        _divider(),
        ShadContextMenuItem(child: const Text('Smart Assign All'), onPressed: controller.smartAssignAll),
        ShadContextMenuItem(child: const Text('Smart Assign Selected'), onPressed: controller.smartAssignSelected, enabled: hasSelection),
        _divider(),
        ShadContextMenuItem(
          child: const Text('Assign To Activity'),
          onPressed: controller.assignSelected,
          enabled: controller.canAssignToSelectedActivity,
        ),
        ShadContextMenuItem(
          child: const Text('Unassign From Selected Activity'),
          onPressed: controller.unassignSelectedFromActivity,
          enabled: controller.canAssignToSelectedActivity,
        ),
        ShadContextMenuItem(
          child: const Text('Unassign For Selected Period'),
          onPressed: controller.unassignSelectedFromBlock,
          enabled: controller.canUnassignFromSelectedBlock,
        ),
        ShadContextMenuItem(
          child: _destructiveLabel('Unassign From All Periods', enabled: hasSelection),
          onPressed: controller.unassignSelectedFromAll,
          enabled: hasSelection,
        ),
        _divider(),
        ShadContextMenuItem(child: const Text('Set Cabin Of Campers'), onPressed: controller.setCabin, enabled: hasSelection),
        ShadContextMenuItem(child: const Text('Swap Cabins Of Campers'), onPressed: controller.swapCabinsOfSelected, enabled: hasSelection),
        _divider(),
        ShadContextMenuItem(child: _destructiveLabel('Delete', enabled: hasSelection), onPressed: controller.deleteSelected, enabled: hasSelection),
      ],
    ],
  );
}

List<Widget> buildRostersTrailingWidgets({required RostersController controller}) => [
  BessSearchbar(onSearchChange: controller.setSearchQuery, noMatches: controller.noMatches, controller: controller.searchController),
];
