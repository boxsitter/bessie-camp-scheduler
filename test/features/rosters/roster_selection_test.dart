import 'package:bessie/src/features/rosters/models/roster_selection.dart';
import 'package:flutter_test/flutter_test.dart';

import 'roster_fixtures.dart';

void main() {
  group('arrivedTarget', () {
    test('marks everyone arrived when anyone has not', () {
      expect(RosterSelection.arrivedTarget([makeCamper(arrived: true), makeCamper(first: 'B', arrived: false)]), isTrue);
      expect(RosterSelection.arrivedTarget([makeCamper(arrived: false)]), isTrue);
    });

    test('marks everyone not arrived when they all have', () {
      expect(RosterSelection.arrivedTarget([makeCamper(arrived: true), makeCamper(first: 'B', arrived: true)]), isFalse);
    });
  });

  group('cabinSwapProblem', () {
    test('accepts campers spread over exactly two cabins', () {
      final campers = [
        makeCamper(first: 'A', cabinId: 'c1'),
        makeCamper(first: 'B', cabinId: 'c1'),
        makeCamper(first: 'C', cabinId: 'c2'),
      ];
      expect(RosterSelection.cabinSwapProblem(campers), isNull);
    });

    test('rejects one cabin, three cabins, nobody, and campers without a cabin', () {
      expect(RosterSelection.cabinSwapProblem([makeCamper(cabinId: 'c1'), makeCamper(first: 'B', cabinId: 'c1')]), isNotNull);
      expect(
        RosterSelection.cabinSwapProblem([makeCamper(cabinId: 'c1'), makeCamper(first: 'B', cabinId: 'c2'), makeCamper(first: 'C', cabinId: 'c3')]),
        isNotNull,
      );
      expect(RosterSelection.cabinSwapProblem([]), isNotNull);
      expect(RosterSelection.cabinSwapProblem([makeCamper(cabinId: 'c1'), makeCamper(first: 'B', cabinId: 'c2'), makeCamper(first: 'C')]), isNotNull);
    });
  });

  group('stateOf', () {
    test('is true for all, null for some, false for none', () {
      expect(RosterSelection.stateOf(['a', 'b'], {'a', 'b', 'z'}), isTrue);
      expect(RosterSelection.stateOf(['a', 'b'], {'a'}), isNull);
      expect(RosterSelection.stateOf(['a', 'b'], {'z'}), isFalse);
      expect(RosterSelection.stateOf([], {'a'}), isFalse);
    });
  });

  test('invert keeps only what was not selected', () {
    expect(RosterSelection.invert(['a', 'b', 'c'], {'b'}), {'a', 'c'});
    expect(RosterSelection.invert(['a'], {'a'}), isEmpty);
  });
}
