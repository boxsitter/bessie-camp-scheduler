import 'package:bessie/src/features/schedule/schedule_grid.dart';
import 'package:bessie/src/models/schedule.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  final monday = day(0);
  final tuesday = day(1);
  final wednesday = day(2);

  final archery = activity('archery', name: 'Archery', capacity: 2);
  final pottery = activity('pottery', name: 'Pottery', capacity: 3);
  final drama = activity('drama', name: 'drama', capacity: 5);

  group('layout', () {
    test('has one column per day, in day order, leaving out days without blocks', () {
      final mondayBlock = block('m1', monday);
      final wednesdayBlock = block('w1', wednesday);
      final schedule = scheduleOf(
        days: [wednesday, tuesday, monday],
        blocks: [wednesdayBlock, mondayBlock],
        scheduled: [scheduled('s1', mondayBlock, archery), scheduled('s2', wednesdayBlock, pottery)],
        activities: [archery, pottery],
      );

      final grid = ScheduleGrid.build(schedule, const []);

      expect(grid.days.map((d) => d.weekday), ['Monday', 'Wednesday']);
      expect(grid.days.map((d) => d.date), [DateTime(2026, 7, 6), DateTime(2026, 7, 8)]);
      expect(grid.firstDate, DateTime(2026, 7, 6));
      expect(grid.lastDate, DateTime(2026, 7, 8));
    });

    test('orders the blocks of a day chronologically, whatever order they come in', () {
      final late = block('late', monday, title: 'Skills Rec', start: const Duration(hours: 14), end: const Duration(hours: 15));
      final early = block('early', monday, title: 'Choice 1', start: const Duration(hours: 9, minutes: 15), end: const Duration(hours: 10));
      final noon = block(
        'noon',
        monday,
        title: 'Choice 2',
        start: const Duration(hours: 11, minutes: 20),
        end: const Duration(hours: 12, minutes: 20),
      );
      final schedule = scheduleOf(days: [monday], blocks: [late, noon, early], scheduled: const [], activities: const []);

      final grid = ScheduleGrid.build(schedule, const []);

      expect(grid.days.single.blocks.map((b) => b.block.title), ['Choice 1', 'Choice 2', 'Skills Rec']);
      expect(grid.days.single.blocks.map((b) => b.timeRange), ['9:15-10:00 AM', '11:20 AM-12:20 PM', '2:00-3:00 PM']);
    });

    test('breaks ties between blocks that start together by end time, then title', () {
      final b = block('b', monday, title: 'B');
      final a = block('a', monday, title: 'A');
      final shorter = block('short', monday, title: 'Z', end: const Duration(hours: 10, minutes: 45));
      final schedule = scheduleOf(days: [monday], blocks: [b, a, shorter], scheduled: const [], activities: const []);

      final grid = ScheduleGrid.build(schedule, const []);

      expect(grid.days.single.blocks.map((c) => c.block.title), ['Z', 'A', 'B']);
    });

    test('lists a block\'s activities alphabetically, ignoring case', () {
      final b = block('b', monday);
      final schedule = scheduleOf(
        days: [monday],
        blocks: [b],
        scheduled: [scheduled('s1', b, pottery), scheduled('s2', b, drama), scheduled('s3', b, archery)],
        activities: [archery, pottery, drama],
      );

      final cell = ScheduleGrid.build(schedule, const []).days.single.blocks.single;

      expect(cell.slots.map((s) => s.activity.name), ['Archery', 'drama', 'Pottery']);
    });

    test('keeps each block\'s activities to that block', () {
      final b1 = block('b1', monday, title: 'One');
      final b2 = block('b2', monday, title: 'Two', start: const Duration(hours: 11, minutes: 20), end: const Duration(hours: 12));
      final schedule = scheduleOf(
        days: [monday],
        blocks: [b1, b2],
        scheduled: [scheduled('s1', b1, archery), scheduled('s2', b2, pottery)],
        activities: [archery, pottery],
      );

      final cells = ScheduleGrid.build(schedule, const []).days.single.blocks;

      expect(cells[0].slots.map((s) => s.activity.id), ['archery']);
      expect(cells[1].slots.map((s) => s.activity.id), ['pottery']);
    });

    test('skips scheduled activities missing from the catalog', () {
      final b = block('b', monday);
      final schedule = scheduleOf(
        days: [monday],
        blocks: [b],
        scheduled: [scheduled('s1', b, archery), scheduled('s2', b, pottery)],
        activities: [archery],
      );

      expect(ScheduleGrid.build(schedule, const []).days.single.blocks.single.slots.map((s) => s.activity.id), ['archery']);
    });

    test('an empty schedule has no days', () {
      final grid = ScheduleGrid.build(scheduleOf(days: [monday], blocks: const [], scheduled: const [], activities: const []), const []);
      expect(grid.isEmpty, isTrue);
      expect(grid.firstDate, isNull);
      expect(grid.lastDate, isNull);
      expect(grid.busiestBlockSize, 0);
      expect(grid.overCapacityCount, 0);
    });

    test('knows the busiest block', () {
      final b1 = block('b1', monday);
      final b2 = block('b2', tuesday);
      final schedule = scheduleOf(
        days: [monday, tuesday],
        blocks: [b1, b2],
        scheduled: [scheduled('s1', b1, archery), scheduled('s2', b2, archery), scheduled('s3', b2, pottery), scheduled('s4', b2, drama)],
        activities: [archery, pottery, drama],
      );
      expect(ScheduleGrid.build(schedule, const []).busiestBlockSize, 3);
    });
  });

  group('enrollment', () {
    late Block b1;
    late Block b2;
    late List<ScheduledActivity> scheduledActivities;

    setUp(() {
      b1 = block('b1', monday, title: 'One');
      b2 = block('b2', monday, title: 'Two', start: const Duration(hours: 11, minutes: 20), end: const Duration(hours: 12, minutes: 20));
      scheduledActivities = [
        scheduled('s-archery-1', b1, archery),
        scheduled('s-pottery-1', b1, pottery),
        scheduled('s-archery-2', b2, archery),
      ];
    });

    ScheduleGrid gridFor(List campers) => ScheduleGrid.build(
      scheduleOf(days: [monday], blocks: [b1, b2], scheduled: scheduledActivities, activities: [archery, pottery]),
      campers.cast(),
    );

    ActivitySlot slot(ScheduleGrid grid, String blockId, String activityId) =>
        grid.days.single.blocks.firstWhere((c) => c.block.id == blockId).slots.firstWhere((s) => s.activity.id == activityId);

    test('counts the campers assigned to each activity from their assignments', () {
      final grid = gridFor([
        camper('a', assignments: {'b1': 's-archery-1', 'b2': 's-archery-2'}),
        camper('b', assignments: {'b1': 's-archery-1'}),
        camper('c', assignments: {'b1': 's-pottery-1'}),
      ]);

      expect(slot(grid, 'b1', 'archery').enrolled, 2);
      expect(slot(grid, 'b1', 'pottery').enrolled, 1);
      expect(slot(grid, 'b2', 'archery').enrolled, 1, reason: 'the same activity in another block counts on its own');
      expect(slot(grid, 'b1', 'archery').enrollmentLabel, '2/2');
      expect(slot(grid, 'b1', 'pottery').enrollmentLabel, '1/3');
    });

    test('shows 0 for an activity nobody is in', () {
      final grid = gridFor([camper('a')]);
      expect(slot(grid, 'b1', 'archery').enrollmentLabel, '0/2');
    });

    test('is over capacity only when there are more campers than room', () {
      final grid = gridFor([
        camper('a', assignments: {'b1': 's-archery-1'}),
        camper('b', assignments: {'b1': 's-archery-1'}),
        camper('c', assignments: {'b2': 's-archery-2'}),
      ]);
      expect(slot(grid, 'b1', 'archery').isOverCapacity, isFalse, reason: '2 of 2 is full, not over');

      final crowded = gridFor([
        camper('a', assignments: {'b1': 's-archery-1'}),
        camper('b', assignments: {'b1': 's-archery-1'}),
        camper('c', assignments: {'b1': 's-archery-1'}),
      ]);
      expect(slot(crowded, 'b1', 'archery').isOverCapacity, isTrue);
      expect(slot(crowded, 'b1', 'archery').enrollmentLabel, '3/2');
      expect(slot(crowded, 'b1', 'pottery').isOverCapacity, isFalse);
      expect(crowded.days.single.blocks.first.hasOverCapacity, isTrue);
      expect(crowded.days.single.blocks.last.hasOverCapacity, isFalse);
      expect(crowded.overCapacityCount, 1);
    });

    test('counts how many campers have an activity in each block', () {
      final grid = gridFor([
        camper('a', assignments: {'b1': 's-archery-1', 'b2': 's-archery-2'}),
        camper('b', assignments: {'b1': 's-pottery-1'}),
        camper('c'),
      ]);

      final cells = grid.days.single.blocks;
      expect(cells[0].placedCampers, 2);
      expect(cells[1].placedCampers, 1);
      expect(cells.map((c) => c.totalCampers), [3, 3]);
    });

    test('ignores assignments to activities that are not on the schedule', () {
      final grid = gridFor([
        camper('a', assignments: {'b1': 'some-removed-activity'}),
      ]);
      expect(slot(grid, 'b1', 'archery').enrolled, 0);
      expect(grid.days.single.blocks.first.placedCampers, 1);
    });
  });
}
