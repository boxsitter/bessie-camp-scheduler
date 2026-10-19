import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../models/enums.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/sizes.dart';
import '../../../shared/styles/text_styles.dart';
import '../../../shared/widgets/buttons/icon_button.dart';
import '../../../shared/widgets/containers/titled_container.dart';
import '../../../shared/widgets/misc/list_reorderer.dart';
import '../../../shared/widgets/misc/widget_list.dart';
import '../controllers/rosters_controller.dart';
import '../models/roster_column.dart';

/// The panel where columns are shown, hidden and reordered, and where the
/// sorting and grouping column are chosen.
class ColumnConfig extends StatelessWidget {
  const ColumnConfig({super.key, required this.controller});

  final RostersController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BessSizes.md),
      decoration: BoxDecoration(border: BorderDirectional(bottom: BorderSide(color: BessColors.borderPrimary, width: 2))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TitledContainer(
              title: 'Visible Columns',
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: VerticalListReorderer<RosterColumn>(
                items: controller.columns,
                onReorder: controller.setColumnOrder,
                titleBuilder: (column) => Text(column.displayTitle, style: BessTextStyles.standard),
                trailingBuilder: (column) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...groupAndSortButtons(controller, column),
                    BessIconButton(iconData: LucideIcons.circleChevronRight, onPressed: () => controller.removeColumn(column)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: BessSizes.spaceBtwItems),
          Expanded(
            child: Column(
              children: [
                _HiddenColumns(controller: controller, title: 'Hidden Camper Data', columns: controller.hiddenFieldColumns),
                _HiddenColumns(controller: controller, title: 'Hidden Activity Periods', columns: controller.hiddenBlockColumns),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The group-by and sort-by buttons of one column.
List<Widget> groupAndSortButtons(RostersController controller, RosterColumn column) {
  final sorted = controller.sortBy == column;
  return [
    if (column.allowGrouping)
      BessIconButton(
        iconData: LucideIcons.group,
        onPressed: () => controller.setGroupBy(column),
        selected: controller.groupBy == column,
      ),
    BessIconButton(
      iconData: sorted && controller.sortDirection == SortDirection.desc ? LucideIcons.arrowDownZA : LucideIcons.arrowUpAZ,
      onPressed: () => controller.setSortBy(column),
      selected: sorted,
    ),
  ];
}

class _HiddenColumns extends StatelessWidget {
  const _HiddenColumns({required this.controller, required this.title, required this.columns});

  final RostersController controller;
  final String title;
  final List<RosterColumn> columns;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TitledContainer(
        title: title,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: WidgetList<RosterColumn>(
          items: columns,
          itemBuilder: (context, column) => SizedBox(
            height: 48,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.circleChevronLeft, size: 20),
                  onPressed: () => controller.addColumn(column),
                  splashRadius: 20,
                ),
                Expanded(child: Text(column.displayTitle, style: BessTextStyles.standard, overflow: TextOverflow.ellipsis)),
                ...groupAndSortButtons(controller, column),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
