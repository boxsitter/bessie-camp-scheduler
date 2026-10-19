import 'package:collection/collection.dart';

import '../../models/activity.dart';
import '../../models/camper.dart';
import '../../models/schedule.dart';
import 'schedule_formatting.dart';

/// One activity offered in a block, with how many campers are signed up.
class ActivitySlot {
  const ActivitySlot({required this.scheduled, required this.activity, required this.enrolled});

  final ScheduledActivity scheduled;
  final Activity activity;
  final int enrolled;

  int get capacity => activity.capacity;
  bool get isOverCapacity => enrolled > capacity;

  /// `n/capacity`.
  String get enrollmentLabel => '$enrolled/$capacity';
}

/// A block of one day with the activities offered in it.
class BlockCell {
  const BlockCell({required this.block, required this.slots, required this.placedCampers, required this.totalCampers});

  final Block block;

  /// Alphabetical.
  final List<ActivitySlot> slots;

  /// Campers who have an activity in this block, out of all campers.
  final int placedCampers;
  final int totalCampers;

  String get timeRange => formatTimeRange(block.startTime, block.endTime);
  bool get hasOverCapacity => slots.any((s) => s.isOverCapacity);
}

/// A day of the schedule: its blocks in chronological order.
class DayColumn {
  const DayColumn({required this.day, required this.blocks});

  final ScheduleDay day;
  final List<BlockCell> blocks;

  DateTime get date => day.date;
  String get weekday => weekdayName(day.date);
}

/// The weekly schedule laid out as columns of days: everything the printed
/// sheet shows, without any widgets.
class ScheduleGrid {
  const ScheduleGrid(this.days);

  /// Days in order. Days without any block are left out.
  final List<DayColumn> days;

  /// Builds the grid of [schedule]; enrollment comes from the
  /// assignments of [campers].
  factory ScheduleGrid.build(Schedule schedule, Iterable<Camper> campers) {
    final roster = campers.toList();
    final enrolled = <String, int>{};
    final placedInBlock = <String, int>{};
    for (final camper in roster) {
      for (final entry in camper.assignments.entries) {
        placedInBlock.update(entry.key, (n) => n + 1, ifAbsent: () => 1);
        enrolled.update(entry.value, (n) => n + 1, ifAbsent: () => 1);
      }
    }

    BlockCell cellOf(Block block) {
      final slots = <ActivitySlot>[
        for (final scheduled in schedule.scheduledIn(block.id))
          if (schedule.activityOf(scheduled) case final activity?)
            ActivitySlot(scheduled: scheduled, activity: activity, enrolled: enrolled[scheduled.id] ?? 0),
      ];
      return BlockCell(
        block: block,
        slots: slots.sortedBy((s) => s.activity.name.toLowerCase()),
        placedCampers: placedInBlock[block.id] ?? 0,
        totalCampers: roster.length,
      );
    }

    final blocksByDay = groupBy(schedule.blocks, (Block b) => b.dayId);
    return ScheduleGrid([
      for (final day in schedule.days)
        if (blocksByDay[day.id] case final blocks? when blocks.isNotEmpty)
          DayColumn(
            day: day,
            blocks: blocks
                .sorted((a, b) {
                  final byStart = a.startTime.compareTo(b.startTime);
                  if (byStart != 0) return byStart;
                  final byEnd = a.endTime.compareTo(b.endTime);
                  return byEnd != 0 ? byEnd : a.title.compareTo(b.title);
                })
                .map(cellOf)
                .toList(),
          ),
    ]);
  }

  bool get isEmpty => days.isEmpty;

  /// The activities that have more campers than room.
  int get overCapacityCount => days.expand((d) => d.blocks).expand((b) => b.slots).where((s) => s.isOverCapacity).length;

  DateTime? get firstDate => days.firstOrNull?.date;
  DateTime? get lastDate => days.lastOrNull?.date;

  /// The most activities offered in one block, to size the sheet.
  int get busiestBlockSize => days.expand((d) => d.blocks).fold(0, (most, b) => b.slots.length > most ? b.slots.length : most);
}
