import 'package:bessie/src/ember_core.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../shared/constants/colors.dart';
import '../../../shared/constants/sizes.dart';
import '../../../shared/styles/text_styles.dart';
import '../../../shared/widgets/buttons/icon_button.dart';
import '../../../shared/widgets/containers/titled_container.dart';
import '../../../shared/widgets/misc/widget_list.dart';
import '../../../shared/widgets/misc/list_reorderer.dart';
import '../controllers/rosters_controller.dart';

class ColumnConfig extends StatelessWidget {
  const ColumnConfig({
    super.key,
    required this.controller,
  });

  final RostersController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BessSizes.md),
      decoration: BoxDecoration(border: BorderDirectional(bottom: BorderSide(color: BessColors.borderPrimary, width: 2))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: TitledContainer(
              title: 'Visible Columns',
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: VerticalListReorderer<RosterField>(
                items: controller.fields,
                onReorder: controller.setColumnOrder,
                titleBuilder: (RosterField item) => Text(item.displayTitle, style: BessTextStyles.standard),
                trailingBuilder: (RosterField item) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (item.allowGrouping)
                        BessIconButton(
                          iconData: LucideIcons.group,
                          onPressed: () => controller.setGroupBy(item),
                          selected: controller.groupByField == item,
                        ),
                      BessIconButton(
                        iconData: controller.sortDirection == SortDirection.asc ? LucideIcons.arrowUpAZ : LucideIcons.arrowDownZA,
                        onPressed: () => controller.setSortBy(item),
                        selected: controller.sortByField == item,
                      ),
                      BessIconButton(
                        iconData: LucideIcons.circleChevronRight,
                        onPressed: () => controller.removeVisibleColumn(item),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          SizedBox(width: BessSizes.spaceBtwItems),
          Expanded(
            child: Column(
              children: [
                ColumnManager(controller: controller, title: 'Hidden Camper Data', items: controller.availableFields(false),),
                ColumnManager(controller: controller, title: 'Hidden Activity Periods', items: controller.availableFields(true),),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ColumnManager extends StatelessWidget {
  const ColumnManager({
    super.key,
    required this.controller,
    required this.title,
    required this.items,
  });

  final RostersController controller;
  final String title;
  final List<RosterField> items;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TitledContainer(
        title: title,
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: WidgetList(
          items: items,
          itemBuilder: (context, item) {
            return Container(
              height: 48,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.circleChevronLeft, size: 20),
                    onPressed: () => controller.addVisibleColumn(item),
                    splashRadius: 20,
                  ),
                  Text(item.displayTitle, style: BessTextStyles.standard),
                  Spacer(),
                  if (item.allowGrouping)
                    BessIconButton(
                      iconData: LucideIcons.group,
                      onPressed: () => controller.setGroupBy(item),
                      selected: controller.groupByField == item,
                    ),
                  BessIconButton(
                    iconData: controller.sortDirection == SortDirection.asc ? LucideIcons.arrowUpAZ : LucideIcons.arrowDownZA,
                    onPressed: () => controller.setSortBy(item),
                    selected: controller.sortByField == item,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
