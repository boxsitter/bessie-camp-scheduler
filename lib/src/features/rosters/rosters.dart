import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../shared/styles/text_styles.dart';
import '../../shared/widgets/layouts/templates/site_layout.dart';
import '../../shared/widgets/loaders/circular_loader.dart';
import 'controllers/rosters_controller.dart';
import 'models/roster_view.dart';
import 'widgets/activity_switcher.dart';
import 'widgets/column_config.dart';
import 'widgets/header_builders.dart';
import 'widgets/roster_colors.dart';
import 'widgets/roster_importer.dart';
import 'widgets/table/data_table.dart';

/// The Rosters page: the session's campers in an editable table, with the
/// column settings and the activity switcher as alternative panels.
class Rosters extends StatelessWidget {
  const Rosters({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RostersController>(
      // The navigation observer normally starts the roster; this makes sure
      // it is running whenever the page is on screen.
      initState: (_) => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.isRegistered<RostersController>()) Get.find<RostersController>().activate();
      }),
      builder: (controller) => BessSiteTemplate(
        desktop: RostersBody(controller: controller),
        desktopPadding: false,
        tabletPadding: false,
        menuBar: buildRostersMenuBar(controller: controller),
        centerActions: buildRostersCenterActions(controller: controller),
        trailingWidgets: buildRostersTrailingWidgets(controller: controller),
      ),
    );
  }
}

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
    return ClipRect(
      child: Padding(padding: const EdgeInsets.all(16.0), child: RosterTables(controller: controller)),
    );
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
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [table(group, expanded), SizedBox(height: expanded ? 16 : 8)],
            );
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
