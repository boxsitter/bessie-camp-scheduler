// import 'package:bessie/src/shared/styles/text_styles.dart';
// import 'package:bessie/src/shared/utils/helpers/helper_functions.dart';
// import 'package:bessie/src/features/rosters/widgets/table/table_header.dart';
// import 'package:bessie/src/features/rosters/widgets/table/table_row.dart';
// import 'package:bessie/src/ember_core.dart';
// import 'package:flutter/material.dart';
//
// import '../../../../common/constants/colors.dart';
// import '../../controllers/rosters_controller.dart';
//
// class RostersTable extends StatelessWidget {
//   const RostersTable({
//     super.key,
//     required this.controller,
//   });
//
//   final RostersController controller;
//
//   static const double _checkboxColumnWidth = 50.0;
//   static const double indentWidth = 24.0;
//
//   @override
//   Widget build(BuildContext context) {
//     if (controller.fields.isEmpty) {
//       return const Center(child: Text('Add some columns!'));
//     } else if (controller.filteredRoster.isEmpty && controller.searchQuery.isNotEmpty) {
//       return Center(child: Text('No campers found for "${controller.searchQuery}".'));
//     } else {
//       return LayoutBuilder(
//         builder: (context, constraints) {
//           final tableWidths = _calculateTableWidths(constraints);
//           final outlineColor = controller.highContrast ? BessColors.element3 : BessColors.borderPrimary;
//
//           return SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: SizedBox(
//               width: tableWidths.actualTableWidth,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisSize: MainAxisSize.max,
//                 children: [
//                   _TableHeader(
//                     controller: controller,
//                     widths: tableWidths.adjustedDataWidths,
//                     outlineColor: outlineColor,
//                   ),
//                   Expanded(
//                     child: _TableBody(
//                       controller: controller,
//                       widths: tableWidths.adjustedDataWidths,
//                       outlineColor: outlineColor,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       );
//     }
//   }
//
//   _TableWidths _calculateTableWidths(BoxConstraints constraints) {
//     final List<double> defaultDataWidths = controller.fields.map((field) => field.defaultWidth).toList();
//     final double minDataWidthSum = defaultDataWidths.reduce((a, b) => a + b);
//
//     final double totalMinWidth = minDataWidthSum + _checkboxColumnWidth;
//
//     List<double> adjustedDataWidths = List.from(defaultDataWidths);
//     double actualTableWidth;
//
//     if (constraints.maxWidth >= totalMinWidth) {
//       final double excessSpace = constraints.maxWidth - totalMinWidth;
//       if (adjustedDataWidths.isNotEmpty) {
//         adjustedDataWidths[adjustedDataWidths.length - 1] += excessSpace;
//       }
//       actualTableWidth = constraints.maxWidth;
//     } else {
//       actualTableWidth = totalMinWidth;
//     }
//
//     if (controller.groupByField != null) {
//       actualTableWidth += indentWidth;
//     }
//
//     return _TableWidths(adjustedDataWidths: adjustedDataWidths, actualTableWidth: actualTableWidth);
//   }
// }
//
// class _TableWidths {
//   final List<double> adjustedDataWidths;
//   final double actualTableWidth;
//
//   _TableWidths({required this.adjustedDataWidths, required this.actualTableWidth});
// }
//
// class _TableHeader extends StatelessWidget {
//   const _TableHeader({
//     required this.controller,
//     required this.widths,
//     required this.outlineColor,
//   });
//
//   final RostersController controller;
//   final List<double> widths;
//   final Color outlineColor;
//
//   @override
//   Widget build(BuildContext context) {
//     return BessTableRow(
//       height: 34,
//       data: controller.fields.map((field) => field.displayTitle).toList(),
//       widths: widths,
//       color: BessColors.crust,
//       maxLines: 1,
//       textOverflow: TextOverflow.clip,
//       isSelected: controller.headingCheckboxState,
//       onToggle: controller.toggleSelectAll,
//       textStyle: BessTextStyles.columnHeader,
//       showHorizontalSeparator: true,
//       showVerticalSeparators: controller.columnSeparators,
//       separatorsColor: outlineColor,
//       toggleableRow: false,
//       indent: controller.groupByField != null,
//     );
//   }
// }
//
// class _TableBody extends StatelessWidget {
//   const _TableBody({
//     required this.controller,
//     required this.widths,
//     required this.outlineColor,
//   });
//
//   final RostersController controller;
//   final List<double> widths;
//   final Color outlineColor;
//
//   @override
//   Widget build(BuildContext context) {
//     if (controller.groupByField == null) {
//       return _UngroupedList(controller: controller, widths: widths, outlineColor: outlineColor);
//     } else {
//       return _GroupedList(controller: controller, widths: widths, outlineColor: outlineColor);
//     }
//   }
// }
//
// class _UngroupedList extends StatelessWidget {
//   const _UngroupedList({
//     required this.controller,
//     required this.widths,
//     required this.outlineColor,
//   });
//
//   final RostersController controller;
//   final List<double> widths;
//   final Color outlineColor;
//
//   @override
//   Widget build(BuildContext context) {
//     return ListView.builder(
//       itemCount: controller.filteredRoster.length,
//       itemBuilder: (context, rowIndex) {
//         final rosterItem = controller.filteredRoster[rowIndex];
//         return _RosterRow(
//           controller: controller,
//           rosterItem: rosterItem,
//           rowIndex: rowIndex,
//           widths: widths,
//           outlineColor: outlineColor,
//           isGrouped: false,
//         );
//       },
//     );
//   }
// }
//
// class _GroupedList extends StatelessWidget {
//   const _GroupedList({
//     required this.controller,
//     required this.widths,
//     required this.outlineColor,
//   });
//
//   final RostersController controller;
//   final List<double> widths;
//   final Color outlineColor;
//
//   @override
//   Widget build(BuildContext context) {
//     final groups = controller.groupedRoster;
//     return ListView.builder(
//       itemCount: groups.fold<int>(0, (prev, group) => prev + 1 + (group.isExpanded ? group.items.length : 0)),
//       itemBuilder: (context, index) {
//         int cumulativeItemCount = 0;
//         for (var group in groups) {
//           if (index == cumulativeItemCount) {
//             return BessTableHeader(
//               height: 50,
//               groupTitle: group.groupTitle,
//               isSelected: group.isSelected,
//               showHorizontalSeparator: true,
//               separatorsColor: BessColors.overlay1,
//               color: BessColors.element1,
//               onToggle: () {
//                 groups[index].isExpanded = false;
//               },
//             );
//           }
//           cumulativeItemCount++;
//
//           if (group.isExpanded) {
//             if (index < cumulativeItemCount + group.items.length) {
//               final itemIndex = index - cumulativeItemCount;
//               final rosterItem = group.items[itemIndex];
//               final overallIndex = controller.roster.indexOf(rosterItem);
//               return _RosterRow(
//                 controller: controller,
//                 rosterItem: rosterItem,
//                 rowIndex: overallIndex,
//                 widths: widths,
//                 outlineColor: outlineColor,
//                 isGrouped: true,
//               );
//             }
//             cumulativeItemCount += group.items.length;
//           }
//         }
//         return const SizedBox.shrink(); // Should not be reached
//       },
//     );
//   }
// }
//
// class _RosterRow extends StatelessWidget {
//   const _RosterRow({
//     required this.controller,
//     required this.rosterItem,
//     required this.rowIndex,
//     required this.widths,
//     required this.outlineColor,
//     required this.isGrouped,
//   });
//
//   final RostersController controller;
//   final Rosterable rosterItem;
//   final int rowIndex;
//   final List<double> widths;
//   final Color outlineColor;
//   final bool isGrouped;
//
//   @override
//   Widget build(BuildContext context) {
//     final baseColor = _getBaseColor();
//     final rowColor = controller.selectedItems.contains(rosterItem)
//         ? BessHelperFunctions.blendColors(
//         baseColor, BessColors.primary, 30)
//         : baseColor;
//     return BessTableRow(
//       height: controller.compact ? 40 : 80,
//       data: controller.getRowDataFromItem(rosterItem),
//       widths: widths,
//       color: rowColor,
//       maxLines: controller.compact ? 1 : 3,
//       textOverflow: TextOverflow.ellipsis,
//       isSelected: controller.selectedItems.contains(rosterItem),
//       onToggle: () => controller.toggleRowSelection(rosterItem),
//       textStyle: BessTextStyles.standard,
//       showHorizontalSeparator: controller.rowSeparators,
//       showVerticalSeparators: controller.columnSeparators,
//       separatorsColor: outlineColor,
//       indent: isGrouped,
//     );
//   }
//
//   Color _getBackgroundColor() {
//     if (controller.highContrast) {
//       return controller.alternateRowColors ? BessColors.crust : BessColors.core;
//     }
//     return BessColors.background;
//   }
//
//   Color _getBaseColor() {
//     final backgroundColor = _getBackgroundColor();
//     if (controller.alternateRowColors && !controller.highContrast) {
//       return rowIndex % 2 == 0 ? BessColors.core : backgroundColor;
//     }
//     return backgroundColor;
//   }
// }
