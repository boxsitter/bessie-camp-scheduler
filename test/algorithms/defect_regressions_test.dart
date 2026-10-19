// Regression tests for the defects found in review of the original engine.
// Each group is named after the defect it proves fixed; several defects are
// also covered in more depth elsewhere (referenced in the group comments).

import 'dart:math';

import 'package:bessie/src/algorithms/assignment_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/invariants.dart';
import 'support/scenario_builder.dart';

String activityOf(String scheduledActivityId) =>
    scheduledActivityId.split('@').first;

void main() {
  // Defect 1 (file name case) and 10 (dead code), 11 (intl): source_hygiene_test.dart
  // Defect 2 (random comparator): sort_assignments_step_test.dart
  // Defect 3 (scoring side effects): scoring_test.dart, lazy_greedy_test.dart
  // Defect 7 (stalemate lookup, DateTime.now): stalemate_strategy_test.dart, satisfaction_test.dart
  // Defect 8 (randomize / fail): stalemate_strategy_test.dart
  // Defect 9 (performance): performance_test.dart

  group('Defect 3: scoring must not depend on which period is scored first', () {
    test(
      'a participant gets their request even when every earlier period is full',
      () {
        final builder = ScenarioBuilder()
            .day('mon', periods: 5)
            .activity('swim', capacity: 1)
            .activity('art', capacity: 20)
            .offerEverywhere('swim')
            .offerEverywhere('art')
            .participant('amy', requests: ['swim']);
        for (final p in ['mon1', 'mon2', 'mon3', 'mon4']) {
          builder.external('swim@$p', 1);
        }
        for (var seed = 0; seed < 10; seed++) {
          final result = AssignmentEngine.run(
            builder.build(),
            random: Random(seed),
          );
          expect(
            result.placedFor('amy'),
            contains('swim@mon5'),
            reason: 'seed $seed',
          );
        }
      },
    );
  });

  group('Defect 4: both halves of a double block are checked', () {
    test('a block whose SECOND period is full is never placed', () {
      // canoe has one seat per period; mon2 is already taken by an outsider.
      final context =
          ScenarioBuilder()
              .day('mon', periods: 3)
              .activity('canoe', capacity: 1, doubleSchedule: true)
              .activity('art', capacity: 20)
              .offerEverywhere('canoe')
              .offerEverywhere('art')
              .external('canoe@mon2', 1)
              .participant('amy', requests: ['canoe'])
              .build();

      for (var seed = 0; seed < 10; seed++) {
        final result = AssignmentEngine.run(context, random: Random(seed));
        expect(
          result.placedFor('amy').where((s) => s.startsWith('canoe')),
          isEmpty,
          reason: 'seed $seed: every canoe block needs mon2',
        );
        expectEngineInvariants(context, result, label: 'seed $seed:');
      }
    });

    test(
      'two campers cannot overbook the second period of a one-seat double activity',
      () {
        // Blocks: mon1+mon2 and mon2+mon3 share mon2. Whichever block is chosen
        // first, the other camper's block collides in mon2 -- in its FIRST period
        // or in its SECOND one, depending on the order. Only the second case was
        // missed by the original code.
        final context =
            ScenarioBuilder()
                .day('mon', periods: 3)
                .activity('canoe', capacity: 1, doubleSchedule: true)
                .offerEverywhere('canoe')
                .participant('a', requests: ['canoe'])
                .participant('b', requests: ['canoe'])
                .build();

        for (var seed = 0; seed < 40; seed++) {
          final result = AssignmentEngine.run(context, random: Random(seed));
          final canoes =
              result.newPlacements
                  .where((p) => p.scheduledActivityId.startsWith('canoe'))
                  .toList();
          expect(
            canoes,
            hasLength(2),
            reason: 'seed $seed: exactly one block fits',
          );
          expect(
            canoes.where((p) => p.scheduledActivityId == 'canoe@mon2'),
            hasLength(1),
            reason: 'seed $seed: canoe@mon2 has one seat',
          );
          expectEngineInvariants(context, result, label: 'seed $seed:');
        }
      },
    );

    test('a block that would break the cap is refused as a whole', () {
      // The cap is checked for the block once (it is one occurrence), but the
      // block is refused entirely, never half-placed.
      final context =
          ScenarioBuilder()
              .day('mon', periods: 4)
              .activity('canoe', doubleSchedule: true, maxAssignments: 1)
              .offerEverywhere('canoe')
              .participant('a')
              .existing('a', ['canoe@mon3', 'canoe@mon4'])
              .targets(['mon1', 'mon2'])
              .build();
      final result = AssignmentEngine.run(context, random: Random(0));

      expect(result.newPlacements, isEmpty);
      expect(result.stalemateKeys, ['a@mon1', 'a@mon2']);
    });
  });

  group('Defect 5: seats held by campers outside the run count', () {
    test('running for a subset of campers does not overfill an activity', () {
      // swim has 3 seats; 2 are taken by campers who are not in this run.
      final builder = ScenarioBuilder()
          .day('mon', periods: 1)
          .activity('swim', capacity: 3)
          .offer('swim', ['mon1'])
          .external('swim@mon1', 2);
      for (var i = 0; i < 4; i++) {
        builder.participant('p$i', requests: ['swim']);
      }
      final context = builder.build();
      final result = AssignmentEngine.run(context, random: Random(0));

      expect(result.newPlacements, hasLength(1));
      expect(result.stalemates, hasLength(3));
      expectEngineInvariants(context, result);
    });

    test(
      'without external enrollment the same camp would be accepted in full',
      () {
        final builder = ScenarioBuilder()
            .day('mon', periods: 1)
            .activity('swim', capacity: 3)
            .offer('swim', ['mon1']);
        for (var i = 0; i < 4; i++) {
          builder.participant('p$i', requests: ['swim']);
        }
        expect(
          AssignmentEngine.run(
            builder.build(),
            random: Random(0),
          ).newPlacements,
          hasLength(3),
        );
      },
    );

    test('external enrollment is per scheduled activity, not per activity', () {
      final context =
          ScenarioBuilder()
              .day('mon', periods: 2)
              .activity('swim', capacity: 1)
              .offerEverywhere('swim')
              .external('swim@mon1', 1)
              .participant('a')
              .build();
      final result = AssignmentEngine.run(context, random: Random(0));
      expect(result.placedFor('a'), ['swim@mon2']);
    });

    test('a full external enrollment leaves nothing to place', () {
      final context =
          ScenarioBuilder()
              .day('mon', periods: 1)
              .activity('swim', capacity: 2)
              .offer('swim', ['mon1'])
              .external('swim@mon1', 2)
              .participant('a', requests: ['swim'])
              .build();
      final result = AssignmentEngine.run(context, random: Random(0));
      expect(result.newPlacements, isEmpty);
      expect(result.stalemateKeys, ['a@mon1']);
    });
  });

  group('Defect 6: existing assignments are counted once, in one ledger', () {
    test('an existing assignment counts once towards the cap', () {
      // swim may be held twice. One existing + one new = 2 is allowed. The
      // original code saw the existing assignment twice and allowed none.
      final context =
          ScenarioBuilder()
              .day('mon', periods: 5)
              .activity('swim', maxAssignments: 2)
              .offer('swim', ['mon1', 'mon3', 'mon5'])
              .participant('a')
              .existing('a', ['swim@mon1'])
              .targets(['mon3', 'mon5'])
              .build();
      final result = AssignmentEngine.run(context, random: Random(0));

      expect(result.newPlacements, hasLength(1));
      expect(result.stalemates, hasLength(1));
      expect(
        result.stalemates.single.reason,
        contains('maximum number of assignments'),
      );
    });

    test('existing assignments are not echoed as new placements', () {
      final context =
          ScenarioBuilder()
              .day('mon', periods: 2)
              .activity('swim')
              .activity('art')
              .offerEverywhere('swim')
              .offerEverywhere('art')
              .participant('a')
              .participant('b')
              .existing('a', ['swim@mon1', 'art@mon2'])
              .existing('b', ['art@mon1', 'swim@mon2'])
              .build();
      final result = AssignmentEngine.run(context, random: Random(0));

      expect(result.newPlacements, isEmpty);
      expect(result.stalemates, isEmpty);
    });

    test('an existing double block counts as one occurrence towards the cap', () {
      final context =
          ScenarioBuilder()
              .day('mon', periods: 5)
              .activity('canoe', doubleSchedule: true, maxAssignments: 2)
              .offerEverywhere('canoe')
              .participant('a')
              .existing('a', ['canoe@mon1', 'canoe@mon2'])
              .targets(['mon4', 'mon5'])
              .build();
      final result = AssignmentEngine.run(context, random: Random(0));

      // One block exists (1 occurrence); a second block (mon4+mon5) is allowed.
      expect(result.placedFor('a'), ['canoe@mon4', 'canoe@mon5']);
    });

    test('hidden activities keep campers busy and are never proposed', () {
      final context =
          ScenarioBuilder()
              .day('mon', periods: 3)
              .activity('swim')
              .activity('lifeguard', assignable: false)
              .offerEverywhere('swim')
              .offerEverywhere('lifeguard')
              .participant('a', requests: ['lifeguard'])
              .existing('a', ['lifeguard@mon2'])
              .build();
      final result = AssignmentEngine.run(context, random: Random(0));

      expect(
        result.placedFor('a'),
        unorderedEquals(['swim@mon1', 'swim@mon3']),
      );
      for (final placement in result.newPlacements) {
        expect(activityOf(placement.scheduledActivityId), isNot('lifeguard'));
      }
      expectEngineInvariants(context, result);
    });

    test(
      'a camper busy with a hidden activity is neither placed nor reported as stuck',
      () {
        final context =
            ScenarioBuilder()
                .day('mon', periods: 1)
                .activity('meeting', capacity: 1, assignable: false)
                .activity('swim', capacity: 5)
                .offer('meeting', ['mon1'])
                .offer('swim', ['mon1'])
                .participant('a')
                .existing('a', ['meeting@mon1'])
                .build();
        final result = AssignmentEngine.run(context, random: Random(0));

        expect(result.newPlacements, isEmpty);
        expect(result.stalemates, isEmpty);
        expect(
          result.satisfaction.containsKey('a'),
          isTrue,
        ); // the week is not empty
      },
    );
  });

  group('Defect 11: misc', () {
    test(
      'PreferenceType has no "flexible": neutral is the absence of an entry',
      () {
        expect(PreferenceType.values, [
          PreferenceType.request,
          PreferenceType.veto,
        ]);
      },
    );

    test(
      'same-day checks compare dayIds, so the date a period starts at is irrelevant',
      () {
        // Two periods that start at the same instant but are different days...
        final context = AssignmentContext(
          participants: [AlgoParticipant(id: 'a', birthdate: DateTime(2013))],
          preferences: const {},
          periods: [
            AlgoPeriod(
              id: 'p1',
              dayId: 'day1',
              start: DateTime(2025, 7, 14, 9),
            ),
            AlgoPeriod(
              id: 'p2',
              dayId: 'day2',
              start: DateTime(2025, 7, 14, 10),
            ),
          ],
          targetPeriodIds: const {'p1', 'p2'},
          activities: const [
            AlgoActivity(id: 'canoe', capacity: 5, doubleSchedule: true),
          ],
          scheduledActivities: const [
            AlgoScheduledActivity(
              id: 'c1',
              activityId: 'canoe',
              periodId: 'p1',
            ),
            AlgoScheduledActivity(
              id: 'c2',
              activityId: 'canoe',
              periodId: 'p2',
            ),
          ],
          existingAssignments: const {},
          now: DateTime(2025, 7, 15),
        );
        // ...cannot form a double block, even though the calendar date is the same.
        expect(
          AssignmentEngine.run(context, random: Random(0)).newPlacements,
          isEmpty,
        );
      },
    );
  });
}
