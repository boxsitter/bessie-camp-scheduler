import 'package:bessie/src/models/schedule.dart';
import 'package:bessie/src/features/rosters/models/activity_hints.dart';
import 'package:bessie/src/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

import 'roster_fixtures.dart';

void main() {
  final blocks = [for (var i = 1; i <= 4; i++) makeBlock('b$i', 'B$i', dayIndex: i)];
  final schedule = makeSchedule(
    blocks: blocks,
    activities: [makeActivity('archery', 'Archery', capacity: 2), makeActivity('canoe', 'Canoeing')],
    scheduled: {
      'b1-archery': ('b1', 'archery'),
      'b1-canoe': ('b1', 'canoe'),
      'b2-archery': ('b2', 'archery'),
      'b3-archery': ('b3', 'archery'),
      'b4-archery': ('b4', 'archery'),
      'b4-canoe': ('b4', 'canoe'),
    },
  );
  ScheduledActivity scheduled(String id) => schedule.scheduledActivityById(id)!;

  test('enrollment counts campers per scheduled activity', () {
    final campers = [
      makeCamper(first: 'A', assignments: {'b1': 'b1-archery', 'b2': 'b2-archery'}),
      makeCamper(first: 'B', assignments: {'b1': 'b1-archery'}),
      makeCamper(first: 'C'),
    ];
    expect(ActivityHints.enrollment(campers), {'b1-archery': 2, 'b2-archery': 1});
  });

  group('repetition', () {
    test('is green for once, yellow for twice, red for three or more', () {
      final camper = makeCamper(assignments: {'b1': 'b1-archery', 'b2': 'b2-archery', 'b3': 'b3-archery', 'b4': 'b4-canoe'});
      expect(ActivityHints.repetition(camper, 'b4', schedule), RepetitionLevel.once);
      expect(ActivityHints.repetition(camper, 'b1', schedule), RepetitionLevel.many);

      final twice = makeCamper(assignments: {'b1': 'b1-archery', 'b2': 'b2-archery'});
      expect(ActivityHints.repetition(twice, 'b2', schedule), RepetitionLevel.twice);
    });

    test('is null when nothing is assigned in the block', () {
      expect(ActivityHints.repetition(makeCamper(assignments: {'b1': 'b1-archery'}), 'b2', schedule), isNull);
    });
  });

  group('preferenceHint', () {
    test('reflects a request, a veto, or no preference', () {
      final camper = makeCamper(preferences: {'archery': PreferenceKind.request, 'canoe': PreferenceKind.veto});
      expect(ActivityHints.preferenceHint(camper, scheduled('b1-archery'), schedule), PreferenceHint.requested);
      expect(ActivityHints.preferenceHint(camper, scheduled('b1-canoe'), schedule), PreferenceHint.vetoed);
      expect(ActivityHints.preferenceHint(makeCamper(), scheduled('b1-archery'), schedule), PreferenceHint.neutral);
    });

    test('is repeated when the camper already has the activity twice elsewhere, whatever they asked for', () {
      final camper = makeCamper(assignments: {'b2': 'b2-archery', 'b3': 'b3-archery'}, preferences: {'archery': PreferenceKind.request});
      expect(ActivityHints.preferenceHint(camper, scheduled('b1-archery'), schedule), PreferenceHint.repeated);
    });

    test('does not count the assignment the candidate would replace', () {
      final camper = makeCamper(assignments: {'b1': 'b1-archery', 'b2': 'b2-archery'}, preferences: {'archery': PreferenceKind.request});
      expect(ActivityHints.preferenceHint(camper, scheduled('b1-archery'), schedule), PreferenceHint.requested);
      // ...but a different block would be the third time.
      expect(ActivityHints.preferenceHint(camper, scheduled('b4-archery'), schedule), PreferenceHint.repeated);
    });
  });

  group('seats', () {
    final archery = scheduled('b1-archery');

    test('counts only selected campers that are not in the activity yet', () {
      final inside = makeCamper(first: 'In', assignments: {'b1': 'b1-archery'});
      final elsewhere = makeCamper(first: 'Else', assignments: {'b1': 'b1-canoe'});
      final free = makeCamper(first: 'Free');
      final seats = ActivityHints.seats(
        scheduled: archery,
        capacity: 2,
        selected: [inside, elsewhere, free],
        enrollment: {'b1-archery': 1},
      );
      expect(seats.enrolled, 1);
      expect(seats.incoming, 2);
      expect(seats.wouldOverflow, isTrue);
    });

    test('fits exactly up to capacity', () {
      final seats = ActivityHints.seats(scheduled: archery, capacity: 2, selected: [makeCamper()], enrollment: {'b1-archery': 1});
      expect(seats.wouldOverflow, isFalse);
    });

    test('an activity that is already over capacity overflows even with no one added', () {
      final seats = ActivityHints.seats(scheduled: archery, capacity: 2, selected: const [], enrollment: {'b1-archery': 3});
      expect(seats.wouldOverflow, isTrue);
    });
  });
}
