import 'package:bessie/src/shared/styles/text_styles.dart';
import 'package:bessie/src/shared/utils/helpers/helper_functions.dart';
import 'package:bessie/src/shared/widgets/containers/rounded_container.dart';
import 'package:bessie/src/features/rosters/widgets/table/table_header.dart';
import 'package:bessie/src/features/rosters/widgets/table/table_row.dart';
import 'package:bessie/src/ember_core.dart';
import 'package:flutter/material.dart';

import '../../../../shared/constants/colors.dart';
import '../../controllers/rosters_controller.dart';

class BessDataTable extends StatelessWidget {
  const BessDataTable({
    super.key,
    required this.group,
    required this.fields,
    required this.selectedItems,
    required this.getRowDataFromItem,
    required this.onToggleRowSelection,
    required this.onToggleGroupSelection,
    required this.calculateTableWidths,
    required this.constraintsMaxWidth,
    required this.onToggleGroupExpanded,
    required this.isExpanded,
    required this.headerTitle,
    required this.controller,
    this.isGrouped = false,
    this.alternateRowColors = true,
    this.highContrast = false,
    this.rowSeparators = false,
    this.columnSeparators = false,
    this.compact = true,
  });

  // Data
  final RosterGroup group;
  final List<RosterField> fields;
  final Set<Rosterable> selectedItems;
  final List<String> Function(Rosterable) getRowDataFromItem;
  final Function(double, double) calculateTableWidths;
  final double constraintsMaxWidth;
  final String headerTitle;

  // Configuration
  final bool isGrouped;
  final bool isExpanded;
  final bool alternateRowColors;
  final bool highContrast;
  final bool rowSeparators;
  final bool columnSeparators;
  final bool compact;

  // Callbacks & State
  final RostersController controller;
  final void Function(Rosterable) onToggleRowSelection;
  final void Function(RosterGroup) onToggleGroupSelection;
  final void Function(RosterGroup) onToggleGroupExpanded;

  @override
  Widget build(BuildContext context) {
    if (fields.isEmpty) {
      return const Center(child: Text('Add some columns!'));
    }

    final outlineColor = highContrast ? BessColors.element3 : BessColors.borderPrimary;

    final tableWidths = calculateTableWidths(constraintsMaxWidth, 0); // TODO: The 0 is for zero indent, fix this!

    final row = (int index) {
      final Rosterable rosterItem = group.items[index];
      final Color highContrastDark = highContrast ? BessColors.crust : BessColors.background;
      final Color baseColor = alternateRowColors == true
          ? index % 2 == 0
              ? BessColors.core
              : highContrastDark
          : BessColors.core;
      final rowColor =
          selectedItems.contains(rosterItem) ? BessHelperFunctions.blendColors(baseColor, BessColors.primary, 30) : baseColor;
      final backgroundColors = controller.getRepetitionColors(rosterItem);
      return BessTableRow(
        height: compact ? 40 : 80,
        data: getRowDataFromItem(rosterItem),
        widths: tableWidths.adjustedDataWidths,
        color: rowColor,
        maxLines: compact ? 1 : 3,
        textOverflow: TextOverflow.ellipsis,
        isSelected: selectedItems.contains(rosterItem),
        onToggle: () => onToggleRowSelection(rosterItem),
        textStyle: BessTextStyles.standard,
        showHorizontalSeparator: rowSeparators,
        showVerticalSeparators: columnSeparators,
        separatorsColor: outlineColor,
        backgroundColors: backgroundColors,
      );
    };

    final fieldRow = BessTableRow(
      height: 34,
      data: fields.map((field) => field.displayTitle).toList(),
      widths: tableWidths.adjustedDataWidths,
      color: highContrast ? BessColors.crust : BessColors.background,
      maxLines: 1,
      textOverflow: TextOverflow.clip,
      textStyle: BessTextStyles.columnHeader,
      showHorizontalSeparator: rowSeparators,
      showVerticalSeparators: columnSeparators,
      separatorsColor: outlineColor,
      toggleableRow: false,
      indentWidth: 0,
      showCheckbox: false,
    );

    final tableHeader = BessTableHeader(
      headerTitle: headerTitle,
      group: group,
      onToggle: () => onToggleGroupSelection(group),
      isSelected: group.items.every(selectedItems.contains) ? true : (group.items.any(selectedItems.contains) ? null : false),
      isSingle: isGrouped == false,
      separatorsColor: outlineColor,
      onToggleGroupExpanded: () => onToggleGroupExpanded(group),
      isExpanded: isExpanded,
    );

    final tableContents = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: tableWidths.actualTableWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            fieldRow,
            if (isGrouped)
              if (isExpanded)
                ...List.generate(
                  group.items.length,
                  (index) => row(index),
                ),
            if (!isGrouped)
              Expanded(
                child: ListView.builder(
                  itemCount: group.items.length,
                  itemBuilder: (context, index) {
                    return row(index);
                  },
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
          tableHeader,
          if (isExpanded)
            Divider(thickness: 3, height: 0, color: outlineColor),
          if (isExpanded)
            if (isGrouped) tableContents else Expanded(child: tableContents),
        ],
      ),
    );
  }
}
