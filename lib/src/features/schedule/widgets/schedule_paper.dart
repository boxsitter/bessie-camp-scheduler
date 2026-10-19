import 'package:flutter/material.dart';

import '../../../shared/constants/sizes.dart';
import '../schedule_formatting.dart';
import '../schedule_grid.dart';
import 'day_column.dart';

/// Proportions of the printed sheet: US Letter, landscape, drawn at 200
/// pixels per inch. The sheet grows taller (never wider) when a day has more
/// to list than fits.
class SchedulePaperLayout {
  const SchedulePaperLayout._();

  static const double pixelsPerInch = 200;
  static const double widthInches = 11;
  static const double heightInches = 8.5;
  static const double width = widthInches * pixelsPerInch;
  static const double minHeight = heightInches * pixelsPerInch;
  static const double padding = 40;
  static const double columnSpacing = BessSizes.md;
}

/// The weekly schedule as a white landscape sheet: one column per day, each
/// block listing its activities with `enrolled/capacity`.
class SchedulePaper extends StatelessWidget {
  const SchedulePaper({super.key, required this.grid, this.title});

  final ScheduleGrid grid;

  /// Usually the session's name.
  final String? title;

  @override
  Widget build(BuildContext context) {
    final first = grid.firstDate;
    final last = grid.lastDate;
    final dates = first == null || last == null ? '' : formatDateRange(first, last);
    final over = grid.overCapacityCount;

    return Container(
      width: SchedulePaperLayout.width,
      constraints: const BoxConstraints(minHeight: SchedulePaperLayout.minHeight),
      padding: const EdgeInsets.all(SchedulePaperLayout.padding),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(child: Text(title ?? 'Weekly schedule', style: SheetStyles.sheetTitle)),
              if (over > 0) ...[
                Text(
                  over == 1 ? '1 activity over capacity' : '$over activities over capacity',
                  style: SheetStyles.bold.copyWith(color: SheetStyles.warning),
                ),
                const SizedBox(width: 32),
              ],
              Text(dates, style: SheetStyles.small.copyWith(fontSize: 28)),
            ],
          ),
          const SizedBox(height: 24),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < grid.days.length; i++) ...[
                  if (i > 0) const SizedBox(width: SchedulePaperLayout.columnSpacing),
                  Expanded(child: DayColumnView(column: grid.days[i])),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
