import 'package:flutter/material.dart';

import '../../../../shared/constants/colors.dart';
import '../../../../shared/styles/text_styles.dart';
import '../../../../shared/utils/helpers/helper_functions.dart';
import '../../../../shared/widgets/containers/rounded_container.dart';
import '../../../../models/camper.dart';
import '../../models/roster_column.dart';
import '../../models/roster_table_style.dart';
import '../../models/roster_view.dart';
import '../../models/table_layout.dart';
import 'table_header.dart';
import 'table_row.dart';

/// A table of campers (the whole roster, or one group of it) with a header bar.
class BessDataTable extends StatelessWidget {
  const BessDataTable({
    super.key,
    required this.group,
    required this.columns,
    required this.layout,
    required this.view,
    required this.style,
    required this.heading,
    required this.selectedIds,
    required this.selectionState,
    required this.onToggleRow,
    required this.onToggleGroupSelection,
    required this.onToggleGroupExpanded,
    this.cellTint,
    this.isGrouped = false,
    this.isExpanded = true,
  });

  final RosterGroup group;
  final List<RosterColumn> columns;
  final TableLayout layout;
  final RosterView view;
  final RosterTableStyle style;
  final String heading;

  final Set<String> selectedIds;

  /// True when the whole group is selected, null when part of it is.
  final bool? selectionState;

  /// Background of one cell, for views such as repetition colors.
  final Color? Function(Camper camper, RosterColumn column)? cellTint;

  final bool isGrouped;
  final bool isExpanded;

  final void Function(Camper) onToggleRow;
  final VoidCallback onToggleGroupSelection;
  final VoidCallback onToggleGroupExpanded;

  @override
  Widget build(BuildContext context) {
    if (columns.isEmpty) return const Center(child: Text('Add some columns!'));

    final outlineColor = style.highContrast ? BessColors.element3 : BessColors.borderPrimary;

    final columnTitles = BessTableRow(
      height: 34,
      cells: [for (final column in columns) RosterCell(column.displayTitle)],
      widths: layout.columnWidths,
      color: style.highContrast ? BessColors.crust : BessColors.background,
      maxLines: 1,
      textOverflow: TextOverflow.clip,
      textStyle: BessTextStyles.columnHeader,
      showHorizontalSeparator: style.rowSeparators,
      showVerticalSeparators: style.columnSeparators,
      separatorsColor: outlineColor,
      toggleableRow: false,
      showCheckbox: false,
    );

    final header = BessTableHeader(
      heading: heading,
      count: group.campers.length,
      isSelected: selectionState,
      isSingle: !isGrouped,
      isExpanded: isExpanded,
      onToggle: onToggleGroupSelection,
      onToggleExpanded: onToggleGroupExpanded,
    );

    final tableContents = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: layout.tableWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            columnTitles,
            if (isGrouped && isExpanded) ...[for (var i = 0; i < group.campers.length; i++) _row(i, outlineColor)],
            if (!isGrouped)
              Expanded(
                child: ListView.builder(
                  itemCount: group.campers.length,
                  itemBuilder: (context, index) => _row(index, outlineColor),
                ),
              ),
          ],
        ),
      ),
    );

    return BessRoundedContainer(
      backgroundColor: BessColors.core,
      showBorder: true,
      showShadow: isExpanded,
      strokeAlign: 1.0,
      borderThickness: 2.0,
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          header,
          if (isExpanded) Divider(thickness: 3, height: 0, color: outlineColor),
          if (isExpanded) isGrouped ? tableContents : Expanded(child: tableContents),
        ],
      ),
    );
  }

  Widget _row(int index, Color outlineColor) {
    final camper = group.campers[index];
    final selected = selectedIds.contains(camper.id);
    final alternateColor = style.highContrast ? BessColors.crust : BessColors.background;
    final baseColor = style.alternateRowColors && index.isOdd ? alternateColor : BessColors.core;
    final rowColor = selected ? BessHelperFunctions.blendColors(baseColor, BessColors.primary, 30) : baseColor;

    return BessTableRow(
      key: ValueKey(camper.id),
      height: style.compact ? 40 : 80,
      cells: [for (final column in columns) view.cell(camper, column)],
      widths: layout.columnWidths,
      color: rowColor,
      maxLines: style.compact ? 1 : 3,
      textOverflow: TextOverflow.ellipsis,
      isSelected: selected,
      onToggle: () => onToggleRow(camper),
      textStyle: BessTextStyles.standard,
      showHorizontalSeparator: style.rowSeparators,
      showVerticalSeparators: style.columnSeparators,
      separatorsColor: outlineColor,
      cellColors: cellTint == null ? null : [for (final column in columns) cellTint!(camper, column)],
    );
  }
}
