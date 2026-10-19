import 'dart:math';

import 'package:bessie/src/algorithms/assignment_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/invariants.dart';
import 'support/random_scenario.dart';
import 'support/scenario_builder.dart';

/// Ten identical, neutral campers, three periods, two identical activities with
/// three seats each: almost every decision is a tie, so the output is decided by
/// the random tiebreaks.
AssignmentContext tieHeavy() {
  final builder = ScenarioBuilder()
      .day('mon', periods: 3)
      .activity('swim', capacity: 3)
      .activity('art', capacity: 3)
      .offerEverywhere('swim')
      .offerEverywhere('art');
  for (var i = 0; i < 10; i++) {
    builder.participant('p$i');
  }
  return builder.build();
}

/// Everything about a result except wall-clock durations.
Map<String, Object?> fingerprint(AssignmentResult result) => {
  'placements': result.newPlacements.map((p) => p.toString()).toList(),
  'stalemates': result.stalemates.map((s) => s.toString()).toList(),
  'satisfaction': result.satisfaction,
  'reports':
      result.evaluationReports.map((r) => r.toCsvRow().join(',')).toList(),
  'steps': [
    for (final s in result.stepReports)
      '${s.stepName}|${s.summary}|${s.details}',
  ],
};

void main() {
  group('determinism', () {
    for (final strategy in AssignmentStrategy.values) {
      for (final stalemateStrategy in [
        StalemateStrategy.leaveUnassigned,
        StalemateStrategy.randomize,
      ]) {
        test(
          '${strategy.name}/${stalemateStrategy.name}: the same seed gives identical output',
          () {
            final context = tieHeavy();
            for (var seed = 0; seed < 15; seed++) {
              AssignmentResult run() => AssignmentEngine.run(
                context,
                strategy: strategy,
                stalemateStrategy: stalemateStrategy,
                random: Random(seed),
              );
              expect(
                fingerprint(run()),
                fingerprint(run()),
                reason: 'seed $seed',
              );
            }
          },
        );
      }
    }

    test('different seeds may differ, and every outcome is valid', () {
      final context = tieHeavy();
      final outcomes = <String>{};
      for (var seed = 0; seed < 20; seed++) {
        final result = AssignmentEngine.run(context, random: Random(seed));
        expectEngineInvariants(context, result, label: 'seed $seed:');
        outcomes.add(result.placementStrings.join(' '));
      }
      expect(outcomes.length, greaterThan(5));
    });

    test('the output does not depend on the order periods are supplied in', () {
      for (var seed = 0; seed < 25; seed++) {
        final context = RandomScenario.generate(seed);
        final shuffled = AssignmentContext(
          participants: context.participants,
          preferences: context.preferences,
          periods: [...context.periods]..shuffle(Random(seed)),
          targetPeriodIds: context.targetPeriodIds,
          activities: context.activities,
          scheduledActivities: context.scheduledActivities,
          existingAssignments: context.existingAssignments,
          externalEnrollment: context.externalEnrollment,
          now: context.now,
        );
        expect(
          fingerprint(AssignmentEngine.run(shuffled, random: Random(seed))),
          fingerprint(AssignmentEngine.run(context, random: Random(seed))),
          reason: 'seed $seed',
        );
      }
    });

    test(
      'works without a Random: unseeded runs are valid (and free to differ)',
      () {
        final context = tieHeavy();
        for (var i = 0; i < 5; i++) {
          final result = AssignmentEngine.run(context);
          expectEngineInvariants(context, result);
        }
      },
    );

    test(
      'does not read the wall clock: same input in a far-past "now" is stable',
      () {
        final context = AssignmentContext(
          participants: [
            AlgoParticipant(id: 'a', birthdate: DateTime(1990)),
            AlgoParticipant(id: 'b', birthdate: DateTime(1991)),
          ],
          preferences: const {
            'a': {'swim': PreferenceType.request},
          },
          periods: [
            AlgoPeriod(id: 'p1', dayId: 'd', start: DateTime(2000, 1, 1, 9)),
            AlgoPeriod(id: 'p2', dayId: 'd', start: DateTime(2000, 1, 1, 10)),
          ],
          targetPeriodIds: const {'p1', 'p2'},
          activities: const [
            AlgoActivity(id: 'swim', capacity: 5),
            AlgoActivity(id: 'art', capacity: 5),
          ],
          scheduledActivities: const [
            AlgoScheduledActivity(id: 's1', activityId: 'swim', periodId: 'p1'),
            AlgoScheduledActivity(id: 's2', activityId: 'art', periodId: 'p2'),
          ],
          existingAssignments: const {},
          now: DateTime(2000, 6, 1),
        );
        final first = AssignmentEngine.run(context, random: Random(1));
        final second = AssignmentEngine.run(context, random: Random(1));
        expect(fingerprint(first), fingerprint(second));
        expect(first.satisfaction.keys, containsAll(['a', 'b']));
      },
    );
  });
}
