import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../shared/styles/text_styles.dart';
import '../../../shared/widgets/loaders/circular_loader.dart';
import '../controllers/rosters_controller.dart';
import '../models/roster_view.dart';
import 'activity_switcher.dart';
import 'column_config.dart';
import 'roster_colors.dart';
import 'roster_importer.dart';
import 'table/data_table.dart';

/// The page's content: whichever of the loader, a message, the column
/// settings, the activity switcher or the roster tables fits the state.
class RostersBody extends StatelessWidget {
  const RostersBody({super.key, required this.controller});

  final RostersController controller;

  @override
  Widget build(BuildContext context) {
    if (!controller.hasSession) {
      return const _Message('No session selected. Choose or create a session to see its roster.');
    }
    if (controller.loading) return const BessCircularLoader();
    if (controller.columnConfigOpened) return ColumnConfig(controller: controller);
    if (controller.activitySwitcherOpened && controller.canEdit) return ActivitySwitcher(controller: controller);
    if (controller.campers.isEmpty) return _EmptyRoster(controller: controller);
    if (controller.noMatches) return _Message('No campers match "${controller.searchQuery.trim()}".');
    return ClipRect(child: Padding(padding: const EdgeInsets.all(16.0), child: RosterTables(controller: controller)));
  }
}

/// One table, or one table per group when the roster is grouped.
class RosterTables extends StatelessWidget {
  const RosterTables({super.key, required this.controller});

  final RostersController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final groups = controller.groups;
        final layout = controller.layoutFor(constraints.maxWidth);
        final view = controller.view;

        Widget table(RosterGroup group, bool expanded) => BessDataTable(
          group: group,
          columns: controller.columns,
          layout: layout,
          view: view,
          style: controller.style,
          heading: group.heading,
          selectedIds: controller.selectedIds,
          selectionState: controller.groupSelectionState(group),
          cellTint: (camper, column) => repetitionColor(controller.repetitionOf(camper, column)),
          isGrouped: controller.isGrouped,
          isExpanded: expanded,
          onToggleRow: controller.toggleSelection,
          onToggleGroupSelection: () => controller.toggleSelectGroup(group),
          onToggleGroupExpanded: () => controller.toggleGroupExpanded(group),
        );

        if (!controller.isGrouped) return table(groups.single, true);

        return ListView.builder(
          clipBehavior: Clip.none,
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            final expanded = controller.isGroupExpanded(group);
            return Column(mainAxisSize: MainAxisSize.min, children: [table(group, expanded), SizedBox(height: expanded ? 16 : 8)]);
          },
        );
      },
    );
  }
}

class _EmptyRoster extends StatelessWidget {
  const _EmptyRoster({required this.controller});

  final RostersController controller;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('There are no campers in this session yet.', style: BessTextStyles.tableHeaderSecondary),
          if (controller.canEdit) ...[
            const SizedBox(height: 16),
            ShadButton(onPressed: () => showRosterImporter(controller), child: const Text('Import From UltraCamp')),
          ],
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Center(child: Text(text, style: BessTextStyles.tableHeaderSecondary));
}
