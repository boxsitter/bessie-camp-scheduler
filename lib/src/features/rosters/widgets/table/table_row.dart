import 'package:flutter/material.dart';

import '../../../../shared/constants/colors.dart';
import '../../../../shared/widgets/buttons/card_button.dart';
import '../../models/roster_view.dart';
import '../../models/table_layout.dart';
import 'table_cell.dart';

/// One row of the roster table: a checkbox followed by a cell per column.
class BessTableRow extends StatelessWidget {
  const BessTableRow({
    super.key,
    required this.height,
    required this.cells,
    required this.widths,
    this.isSelected,
    this.onToggle,
    this.color,
    this.textStyle,
    this.maxLines,
    this.textOverflow,
    this.showVerticalSeparators = false,
    this.showHorizontalSeparator = false,
    this.separatorsColor,
    this.toggleableRow = true,
    this.showCheckbox = true,
    this.cellColors,
  });

  final double height;
  final List<RosterCell> cells;
  final List<double> widths;
  final bool? isSelected;
  final VoidCallback? onToggle;
  final Color? color;
  final TextStyle? textStyle;
  final int? maxLines;
  final TextOverflow? textOverflow;
  final bool showVerticalSeparators;
  final bool showHorizontalSeparator;
  final Color? separatorsColor;

  /// Whether tapping the row toggles its selection.
  final bool toggleableRow;
  final bool showCheckbox;

  /// Background of each cell, by column; null entries (or a null list) leave the row's color.
  final List<Color?>? cellColors;

  @override
  Widget build(BuildContext context) {
    final dataRow = Row(
      children: [
        BessTableCell(
          width: TableLayout.checkboxWidth,
          showVerticalSeparator: showVerticalSeparators,
          separatorColor: separatorsColor,
          padding: EdgeInsets.zero,
          child: showCheckbox ? CheckboxCellContent(value: isSelected, onChanged: onToggle) : const StringCellContent(content: ''),
        ),
        for (var i = 0; i < cells.length; i++)
          BessTableCell(
            width: widths[i],
            showVerticalSeparator: showVerticalSeparators,
            separatorColor: separatorsColor,
            backgroundColor: cellColors?[i],
            child: StringCellContent(
              content: cells[i].text,
              textStyle: textStyle,
              maxLines: maxLines,
              textOverflow: textOverflow,
              textColor: cells[i].tone == CellTone.alert ? BessColors.red : null,
            ),
          ),
      ],
    );

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: toggleableRow ? null : color,
        border: showHorizontalSeparator ? BorderDirectional(bottom: BorderSide(color: separatorsColor ?? BessColors.borderPrimary)) : null,
      ),
      child:
          toggleableRow
              ? CardButton(
                onPressed: onToggle,
                padding: EdgeInsets.zero,
                radius: 0,
                showBorder: false,
                backgroundColor: color,
                child: dataRow,
              )
              : dataRow,
    );
  }
}
