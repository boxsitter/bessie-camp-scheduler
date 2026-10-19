import 'package:flutter/material.dart';

import '../../../shared/constants/colors.dart';
import '../schedule_formatting.dart';
import '../schedule_grid.dart';

/// Text sizes of the printed sheet. The sheet is drawn at 200 pixels per inch
/// of paper, so 24 pixels is about 8.5pt in print.
class SheetStyles {
  const SheetStyles._();

  static const double _bodySize = 24;

  static final Color ink = BessColors.textPrimary;
  static final Color secondaryInk = BessColors.textSecondary;
  static final Color line = BessColors.overlay2;
  static final Color warning = BessColors.red;

  static TextStyle get body => TextStyle(fontFamily: 'Inter', fontSize: _bodySize, color: ink, height: 1.25);
  static TextStyle get bold => body.copyWith(fontWeight: FontWeight.w600);
  static TextStyle get small => body.copyWith(fontSize: 20, color: secondaryInk);
  static TextStyle get dayTitle => body.copyWith(fontSize: 34, fontWeight: FontWeight.w600);
  static TextStyle get sheetTitle => body.copyWith(fontSize: 48, fontWeight: FontWeight.w600);
}

/// One day: its heading, then each block with the activities offered in it.
class DayColumnView extends StatelessWidget {
  const DayColumnView({super.key, required this.column});

  final DayColumn column;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(border: Border.all(color: SheetStyles.line, width: 2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: BessColors.background,
              border: Border(bottom: BorderSide(color: SheetStyles.line, width: 2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(child: Text(column.weekday, style: SheetStyles.dayTitle)),
                Text(formatShortDate(column.date), style: SheetStyles.small),
              ],
            ),
          ),
          for (var i = 0; i < column.blocks.length; i++) BlockView(cell: column.blocks[i], showTopRule: i > 0),
        ],
      ),
    );
  }
}

class BlockView extends StatelessWidget {
  const BlockView({super.key, required this.cell, required this.showTopRule});

  final BlockCell cell;
  final bool showTopRule;

  @override
  Widget build(BuildContext context) {
    final placed = cell.totalCampers == 0 ? '' : '  -  ${cell.placedCampers}/${cell.totalCampers} placed';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: showTopRule ? BoxDecoration(border: Border(top: BorderSide(color: SheetStyles.line, width: 2))) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(cell.block.title, style: SheetStyles.bold.copyWith(fontSize: 28)),
          Text('${cell.timeRange}$placed', style: SheetStyles.small),
          const SizedBox(height: 8),
          if (cell.slots.isEmpty) Text('Nothing scheduled', style: SheetStyles.small),
          for (final slot in cell.slots) SlotRow(slot: slot),
        ],
      ),
    );
  }
}

/// An activity and `enrolled/capacity`; red when there are more campers than room.
class SlotRow extends StatelessWidget {
  const SlotRow({super.key, required this.slot});

  final ActivitySlot slot;

  @override
  Widget build(BuildContext context) {
    final over = slot.isOverCapacity;
    final hidden = slot.activity.isHidden;
    final nameStyle = hidden ? SheetStyles.body.copyWith(fontStyle: FontStyle.italic, color: SheetStyles.secondaryInk) : SheetStyles.body;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      color: over ? SheetStyles.warning.withValues(alpha: 0.14) : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              slot.activity.name,
              style: over ? nameStyle.copyWith(color: SheetStyles.warning, fontWeight: FontWeight.w600) : nameStyle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            slot.enrollmentLabel,
            style: over ? SheetStyles.bold.copyWith(color: SheetStyles.warning) : SheetStyles.body.copyWith(color: SheetStyles.secondaryInk),
          ),
        ],
      ),
    );
  }
}
