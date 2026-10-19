import 'package:bessie/src/algorithms/assignment_engine.dart';
import 'package:bessie/src/algorithms/common/constraints/adjacent_repetition_constraint.dart';
import 'package:bessie/src/algorithms/common/constraints/capacity_constraint.dart';
import 'package:bessie/src/algorithms/common/constraints/constraint_checks.dart';
import 'package:bessie/src/algorithms/common/constraints/double_schedule_constraint.dart';
import 'package:bessie/src/algorithms/common/constraints/reassignment_constraint.dart';
import 'package:bessie/src/algorithms/common/constraints/standard_constraints.dart';
import 'package:bessie/src/algorithms/data_models/assignment_ledger.dart';
import 'package:bessie/src/algorithms/data_models/interfaces/constraint.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/candidates.dart';
import 'support/scenario_builder.dart';

void main() {
  group('CapacityConstraint', () {
    final constraint = CapacityConstraint();

    test('is satisfied while seats are free and violated once they are gone', () {
      final context = ScenarioBuilder()
          .day('mon', periods: 1)
          .activity('swim', capacity: 2)
          .offer('swim', ['mon1'])
          .participant('a')
          .participant('b')
          .participant('c')
          .build();
      final ledger = AssignmentLedger(context);

      expect(constraint.isViolated(candidateOf(context, 'c', 'swim', 'mon1'), context, ledger),
          isFalse);
      ledger.place(candidateOf(context, 'a', 'swim', 'mon1'));
      expect(constraint.isViolated(candidateOf(context, 'c', 'swim', 'mon1'), context, ledger),
          isFalse);
      ledger.place(candidateOf(context, 'b', 'swim', 'mon1'));
      expect(constraint.isViolated(candidateOf(context, 'c', 'swim', 'mon1'), context, ledger),
          isTrue);
    });

    test('counts seats held by campers outside the run (external enrollment)', () {
      final context = ScenarioBuilder()
          .day('mon', periods: 1)
          .activity('swim', capacity: 3)
          .offer('swim', ['mon1'])
          .external('swim@mon1', 3)
          .participant('a')
          .build();
      expect(
        constraint.isViolated(candidateOf(context, 'a', 'swim', 'mon1'), context,
            AssignmentLedger(context)),
        isTrue,
      );
    });

    test('counts existing assignments of the run participants', () {
      final context = ScenarioBuilder()
          .day('mon', periods: 1)
          .activity('swim', capacity: 1)
          .offer('swim', ['mon1'])
          .participant('a')
          .participant('b')
          .existing('a', ['swim@mon1'])
          .build();
      expect(
        constraint.isViolated(candidateOf(context, 'b', 'swim', 'mon1'), context,
            AssignmentLedger(context)),
        isTrue,
      );
    });

    test('treats a capacity of zero as always full', () {
      final context = ScenarioBuilder()
          .day('mon', periods: 1)
          .activity('swim', capacity: 0)
          .offer('swim', ['mon1'])
          .participant('a')
          .build();
      expect(
        constraint.isViolated(candidateOf(context, 'a', 'swim', 'mon1'), context,
            AssignmentLedger(context)),
        isTrue,
      );
    });

    test('checks BOTH periods of a double block', () {
      final context = ScenarioBuilder()
          .day('mon', periods: 2)
          .activity('canoe', capacity: 2, doubleSchedule: true)
          .offer('canoe', ['mon1', 'mon2'])
          .external('canoe@mon2', 2) // only the SECOND period is full
          .participant('a')
          .build();
      final block = candidateOf(context, 'a', 'canoe', 'mon1', linkedPeriodId: 'mon2');
      expect(constraint.isViolated(block, context, AssignmentLedger(context)), isTrue);
    });
  });

  group('ReassignmentConstraint', () {
    final constraint = ReassignmentConstraint();

    test('never applies without a maxAssignments', () {
      final context = ScenarioBuilder()
          .day('mon', periods: 5)
          .activity('swim')
          .offerEverywhere('swim')
          .participant('a')
          .existing('a', ['swim@mon1', 'swim@mon3'])
          .build();
      expect(
        constraint.isViolated(candidateOf(context, 'a', 'swim', 'mon5'), context,
            AssignmentLedger(context)),
        isFalse,
      );
    });

    test('is violated exactly when the participant is at the cap', () {
      final context = ScenarioBuilder()
          .day('mon', periods: 5)
          .activity('swim', maxAssignments: 2)
          .offerEverywhere('swim')
          .participant('a')
          .build();
      final ledger = AssignmentLedger(context);

      expect(constraint.isViolated(candidateOf(context, 'a', 'swim', 'mon1'), context, ledger),
          isFalse);
      ledger.place(candidateOf(context, 'a', 'swim', 'mon1'));
      expect(constraint.isViolated(candidateOf(context, 'a', 'swim', 'mon3'), context, ledger),
          isFalse);
      ledger.place(candidateOf(context, 'a', 'swim', 'mon3'));
      expect(constraint.isViolated(candidateOf(context, 'a', 'swim', 'mon5'), context, ledger),
          isTrue);
    });

    test('counts an existing assignment once, not twice (no double counting)', () {
      final context = ScenarioBuilder()
          .day('mon', periods: 5)
          .activity('swim', maxAssignments: 2)
          .offerEverywhere('swim')
          .participant('a')
          .existing('a', ['swim@mon1'])
          .build();
      final ledger = AssignmentLedger(context);

      expect(ledger.occurrences('a', 'swim'), 1);
      // One existing + one new = 2 <= 2, so a second occurrence is allowed.
      expect(constraint.isViolated(candidateOf(context, 'a', 'swim', 'mon3'), context, ledger),
          isFalse);
    });

    test('counts a double-schedule block as ONE occurrence', () {
      final context = ScenarioBuilder()
          .day('mon', periods: 6)
          .activity('canoe', doubleSchedule: true, maxAssignments: 2)
          .offerEverywhere('canoe')
          .participant('a')
          .build();
      final ledger = AssignmentLedger(context);

      ledger.place(candidateOf(context, 'a', 'canoe', 'mon1', linkedPeriodId: 'mon2'));
      expect(ledger.occurrences('a', 'canoe'), 1);
      final second = candidateOf(context, 'a', 'canoe', 'mon3', linkedPeriodId: 'mon4');
      expect(constraint.isViolated(second, context, ledger), isFalse);

      ledger.place(second);
      expect(ledger.occurrences('a', 'canoe'), 2);
      final third = candidateOf(context, 'a', 'canoe', 'mon5', linkedPeriodId: 'mon6');
      expect(constraint.isViolated(third, context, ledger), isTrue);
    });
  });

  group('AdjacentRepetitionConstraint', () {
    final constraint = AdjacentRepetitionConstraint();

    ScenarioBuilder twoDays() => ScenarioBuilder()
        .day('mon', periods: 3)
        .day('tue', periods: 3)
        .activity('swim')
        .activity('art')
        .offerEverywhere('swim')
        .offerEverywhere('art')
        .participant('a');

    test('forbids the same activity in the period right before or after', () {
      final context = twoDays().build();
      final ledger = AssignmentLedger(context);
      ledger.place(candidateOf(context, 'a', 'swim', 'mon2'));

      expect(constraint.isViolated(candidateOf(context, 'a', 'swim', 'mon1'), context, ledger),
          isTrue);
      expect(constraint.isViolated(candidateOf(context, 'a', 'swim', 'mon3'), context, ledger),
          isTrue);
    });

    test('allows a gap, another activity, or the same activity on another day', () {
      final context = twoDays().build();
      final ledger = AssignmentLedger(context);
      ledger.place(candidateOf(context, 'a', 'swim', 'mon1'));

      expect(constraint.isViolated(candidateOf(context, 'a', 'swim', 'mon3'), context, ledger),
          isFalse); // a gap
      expect(constraint.isViolated(candidateOf(context, 'a', 'art', 'mon2'), context, ledger),
          isFalse); // another activity
      expect(constraint.isViolated(candidateOf(context, 'a', 'swim', 'tue1'), context, ledger),
          isFalse); // another day
    });

    test('does not treat last-of-day and first-of-next-day as adjacent', () {
      final context = twoDays().build();
      final ledger = AssignmentLedger(context);
      ledger.place(candidateOf(context, 'a', 'swim', 'mon3'));

      expect(constraint.isViolated(candidateOf(context, 'a', 'swim', 'tue1'), context, ledger),
          isFalse);
    });

    test('takes existing assignments into account', () {
      final context = twoDays().existing('a', ['swim@mon2']).build();
      expect(
        constraint.isViolated(candidateOf(context, 'a', 'swim', 'mon3'), context,
            AssignmentLedger(context)),
        isTrue,
      );
    });

    test('never applies to double-schedule activities', () {
      final context = ScenarioBuilder()
          .day('mon', periods: 4)
          .activity('canoe', doubleSchedule: true)
          .offerEverywhere('canoe')
          .participant('a')
          .existing('a', ['canoe@mon1', 'canoe@mon2'])
          .build();
      final next = candidateOf(context, 'a', 'canoe', 'mon3', linkedPeriodId: 'mon4');
      expect(constraint.isViolated(next, context, AssignmentLedger(context)), isFalse);
    });
  });

  group('DoubleScheduleConstraint', () {
    final constraint = DoubleScheduleConstraint();

    AssignmentContext scenario() => ScenarioBuilder()
        .day('mon', periods: 3)
        .day('tue', periods: 2)
        .activity('canoe', doubleSchedule: true)
        .activity('swim')
        .activity('art')
        .offer('canoe', ['mon1', 'mon2', 'mon3', 'tue1'])
        .offer('swim', ['mon1'])
        .offer('art', ['mon2'])
        .participant('a')
        .build();

    test('accepts a well-formed block', () {
      final context = scenario();
      final block = candidateOf(context, 'a', 'canoe', 'mon1', linkedPeriodId: 'mon2');
      expect(constraint.isViolated(block, context, AssignmentLedger(context)), isFalse);
    });

    test('ignores activities that are not double-schedule', () {
      final context = scenario();
      expect(
        constraint.isViolated(candidateOf(context, 'a', 'swim', 'mon1'), context,
            AssignmentLedger(context)),
        isFalse,
      );
    });

    test('rejects a double activity without its second period', () {
      final context = scenario();
      final single = candidateOf(context, 'a', 'canoe', 'mon1');
      expect(constraint.isViolated(single, context, AssignmentLedger(context)), isTrue);
    });

    test('rejects a block that runs into the next day', () {
      final context = scenario();
      final block = candidateOf(context, 'a', 'canoe', 'mon3', linkedPeriodId: 'tue1');
      expect(constraint.isViolated(block, context, AssignmentLedger(context)), isTrue);
    });

    test('rejects a second period that is not the next chronological one', () {
      final context = scenario();
      final block = candidateOf(context, 'a', 'canoe', 'mon1', linkedPeriodId: 'mon3');
      expect(constraint.isViolated(block, context, AssignmentLedger(context)), isTrue);
    });

    test('rejects a second half that is a different activity', () {
      final context = scenario();
      final base = candidateOf(context, 'a', 'canoe', 'mon1', linkedPeriodId: 'mon2');
      final mismatched =
          withLinkedScheduledActivity(base, context.scheduledActivityOf('art', 'mon2')!);
      expect(constraint.isViolated(mismatched, context, AssignmentLedger(context)), isTrue);
    });
  });

  group('constraint sets', () {
    test('standardConstraints enforces all four rules, essentialConstraints only two', () {
      expect(standardConstraints().map((c) => c.runtimeType).toSet(), {
        CapacityConstraint,
        ReassignmentConstraint,
        AdjacentRepetitionConstraint,
        DoubleScheduleConstraint,
      });
      expect(essentialConstraints().map((c) => c.runtimeType).toSet(),
          {CapacityConstraint, DoubleScheduleConstraint});
    });

    test('firstViolation and violations report the constraints that are broken', () {
      final context = ScenarioBuilder()
          .day('mon', periods: 3)
          .activity('swim', capacity: 1, maxAssignments: 1)
          .offerEverywhere('swim')
          .participant('a')
          .participant('b')
          .existing('a', ['swim@mon1'])
          .build();
      final ledger = AssignmentLedger(context);

      // 'a' again in mon2: the cap (1) is reached and mon2 is adjacent to mon1.
      final candidate = candidateOf(context, 'a', 'swim', 'mon2');
      final constraints = <Constraint>[
        CapacityConstraint(),
        ReassignmentConstraint(),
        AdjacentRepetitionConstraint(),
      ];
      expect(constraints.violations(candidate, context, ledger), [
        ReassignmentConstraint().violationMessage,
        AdjacentRepetitionConstraint().violationMessage,
      ]);
      expect(constraints.firstViolation(candidate, context, ledger),
          ReassignmentConstraint().violationMessage);

      // 'b' in mon3 breaks nothing.
      final fine = candidateOf(context, 'b', 'swim', 'mon3');
      expect(constraints.violations(fine, context, ledger), isEmpty);
      expect(constraints.firstViolation(fine, context, ledger), isNull);
    });
  });
}
