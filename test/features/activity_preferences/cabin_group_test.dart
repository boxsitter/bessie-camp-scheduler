import 'package:bessie/src/features/activity_preferences/models/cabin_group.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  final oak = cabin('oak', name: 'Oak', position: 1);
  final squirt = cabin('squirt', name: 'Squirt', displayName: 'Ernie', position: 2);
  final empty = cabin('empty', name: 'Empty', position: 3);

  test('groups campers by cabin in cabin order, sorted by last then first name', () {
    final groups = groupCampersByCabin(
      [oak, squirt, empty],
      [
        camper('1', first: 'Zoe', last: 'adams', cabinId: 'squirt'),
        camper('2', first: 'Ben', last: 'Young', cabinId: 'oak'),
        camper('3', first: 'Amy', last: 'Young', cabinId: 'oak'),
        camper('4', first: 'Cal', last: 'Brown', cabinId: 'oak'),
      ],
    );

    expect(groups.map((g) => g.title), ['Oak', 'Ernie']);
    expect(groups.first.campers.map((c) => c.id), ['4', '3', '2']);
    expect(groups.last.campers.map((c) => c.id), ['1']);
    expect(groups.map((g) => g.key), ['oak', 'squirt']);
  });

  test('leaves out cabins without campers', () {
    final groups = groupCampersByCabin([oak, empty], [camper('1', cabinId: 'oak')]);
    expect(groups.map((g) => g.title), ['Oak']);
  });

  test('gathers campers without a session cabin in a last group', () {
    final groups = groupCampersByCabin(
      [oak],
      [camper('1', last: 'A', cabinId: 'oak'), camper('2', last: 'B'), camper('3', last: 'C', cabinId: 'removed-cabin')],
    );

    expect(groups.map((g) => g.title), ['Oak', noCabinTitle]);
    final strays = groups.last;
    expect(strays.cabinId, isNull);
    expect(strays.key, noCabinKey);
    expect(strays.campers.map((c) => c.id), ['2', '3']);
  });

  test('has no groups without campers', () {
    expect(groupCampersByCabin([oak], const []), isEmpty);
  });

  group('progress', () {
    final now = DateTime(2026, 7, 6);

    test('counts campers whose preferences were saved', () {
      final group =
          groupCampersByCabin(
            [oak],
            [camper('1', cabinId: 'oak', submittedAt: now), camper('2', cabinId: 'oak'), camper('3', cabinId: 'oak', submittedAt: now)],
          ).single;

      expect(group.total, 3);
      expect(group.submitted, 2);
      expect(group.isInProgress, isTrue);
      expect(group.isComplete, isFalse);
    });

    test('is complete when everyone is done, untouched when nobody is', () {
      final done = groupCampersByCabin([oak], [camper('1', cabinId: 'oak', submittedAt: now)]).single;
      expect(done.isComplete, isTrue);
      expect(done.isInProgress, isFalse);

      final untouched = groupCampersByCabin([oak], [camper('1', cabinId: 'oak')]).single;
      expect(untouched.isComplete, isFalse);
      expect(untouched.isInProgress, isFalse);
    });
  });
}
