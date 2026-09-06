import 'package:bessie/src/features/rosters/widgets/table/table_cell.dart';
import 'package:flutter/material.dart';

import '../../../../shared/constants/colors.dart';
import '../../../../shared/widgets/buttons/card_button.dart';

class BessTableRow extends StatelessWidget {
  final double height;
  final List<String> data;
  final List<double?>? widths;
  final bool? isSelected;
  final VoidCallback? onToggle;
  final Color? color;
  final TextStyle? textStyle;
  final int? maxLines;
  final TextOverflow? textOverflow;
  final bool? showVerticalSeparators;
  final bool? showHorizontalSeparator;
  final Color? separatorsColor;
  final bool toggleableRow;
  final double indentWidth;
  final bool showCheckbox;
  final List<Color?>? backgroundColors;

  final Set<String> makeRed = const {
    'Unassigned',
    'Error (not found)',
    'Error (no principal activity)',
    'No',
  };

  const BessTableRow({
    super.key,
    required this.height,
    required this.data,
    this.widths,
    this.isSelected,
    this.onToggle,
    this.color,
    this.textStyle,
    this.maxLines,
    this.textOverflow,
    this.showVerticalSeparators,
    this.showHorizontalSeparator,
    this.separatorsColor,
    this.toggleableRow = true,
    this.indentWidth = 0,
    this.showCheckbox = true,
    this.backgroundColors,
  });

  @override
  Widget build(BuildContext context) {
    final Widget dataRow = Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        SizedBox(width: indentWidth),
        BessTableCell(
          width: 50,
          showVerticalSeparator: showVerticalSeparators,
          separatorColor: separatorsColor,
          padding: EdgeInsets.zero,
          child: showCheckbox ? CheckboxCellContent(
            value: isSelected,
            onChanged: onToggle,
            enabled: !toggleableRow,
          ) : StringCellContent(content: ''),
        ),
        // The rest are the data cells
        ...List.generate(data.length, (index) {
          final String content = data[index];
          return BessTableCell(
            width: widths?[index] ?? 100,
            showVerticalSeparator: showVerticalSeparators,
            separatorColor: separatorsColor,
            backgroundColor: backgroundColors?[index],
            child: StringCellContent(
              content: content,
              textStyle: textStyle,
              maxLines: maxLines,
              textOverflow: textOverflow,
              textColor: makeRed.contains(content) ? BessColors.red : null,
            ),
          );
        }),
      ],
    );

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: toggleableRow == true ? null : color,
        border: showHorizontalSeparator == true
            ? BorderDirectional(bottom: BorderSide(color: separatorsColor ?? BessColors.borderPrimary, width: 1))
            : null,
      ),
      child: toggleableRow == true
          ? CardButton(
              onPressed: onToggle,
              padding: EdgeInsets.zero,
              radius: 0,
              showBorder: false,
              backgroundColor: color,
              enabled: toggleableRow,
              child: dataRow,
            )
          : dataRow,
    );
  }
}
