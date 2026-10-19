import 'package:bessie/src/algorithms/assignment_engine.dart';
import 'package:bessie/src/algorithms/common/steps/generate_potential_assignments_step.dart';
import 'package:bessie/src/algorithms/data_models/pipeline_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/candidates.dart';
import 'support/scenario_builder.dart';

/// Runs the generate step and returns the candidates as `participant:sa[+sa]`.
List<String> generate(AssignmentContext context, {PipelineState? state}) {
  final s = state ?? stateFor(context);
  GeneratePotentialAssignmentsStep().execute(s);
  return [
    for (final c in s.potentialAssignments)
      '${c.participant.id}:${c.scheduledActivity.id}'
          '${c.linkedScheduledActivity != null ? '+${c.linkedScheduledActivity!.id}' : ''}',
  ];
}

void main() {
  group('GeneratePotentialAssignmentsStep', () {
    test('produces one candidate per assignable activity per free target slot', () {
      final context =
          ScenarioBuilder()
              .day('mon', periods: 2)
              .activity('swim')
              .activity('art')
              .offerEverywhere('swim')
              .offer('art', ['mon2'])
              .participant('a')
              .participant('b')
              .build();

      expect(generate(context), ['a:swim@mon1', 'a:swim@mon2', 'a:art@mon2', 'b:swim@mon1', 'b:swim@mon2', 'b:art@mon2']);
    });

    test('excludes vetoed activities, and only those', () {
      final context =
          ScenarioBuilder()
              .day('mon', periods: 1)
              .activity('swim')
              .activity('art')
              .offer('swim', ['mon1'])
              .offer('art', ['mon1'])
              .participant('a', vetoes: ['swim'])
              .participant('b', requests: ['swim'], vetoes: ['art'])
              .build();

      expect(generate(context), ['a:art@mon1', 'b:swim@mon1']);
    });

    test('never proposes hidden (non-assignable) activities', () {
      final context =
          ScenarioBuilder()
              .day('mon', periods: 1)
              .activity('swim')
              .activity('staffMeeting', assignable: false)
              .offer('swim', ['mon1'])
              .offer('staffMeeting', ['mon1'])
              .participant('a', requests: ['staffMeeting'])
              .build();

      expect(generate(context), ['a:swim@mon1']);
    });

    test('skips periods in which the participant is already busy, hidden ones included', () {
      final context =
          ScenarioBuilder()
              .day('mon', periods: 3)
              .activity('swim')
              .activity('staffMeeting', assignable: false)
              .offerEverywhere('swim')
              .offer('staffMeeting', ['mon2'])
              .participant('a')
              .existing('a', ['staffMeeting@mon2', 'swim@mon3'])
              .build();

      expect(generate(context), ['a:swim@mon1']);
    });

    test('only generates for target periods', () {
      final context =
          ScenarioBuilder().day('mon', periods: 3).activity('swim').offerEverywhere('swim').participant('a').targets(['mon2']).build();

      expect(generate(context), ['a:swim@mon2']);
    });

    test('follows the supplied participant order and chronological periods', () {
      // Periods are supplied out of order on purpose.
      final periods = [
        AlgoPeriod(id: 'late', dayId: 'd', start: DateTime(2025, 7, 14, 15)),
        AlgoPeriod(id: 'early', dayId: 'd', start: DateTime(2025, 7, 14, 9)),
      ];
      final context = AssignmentContext(
        participants: [AlgoParticipant(id: 'z', birthdate: DateTime(2013)), AlgoParticipant(id: 'a', birthdate: DateTime(2013))],
        preferences: const {},
        periods: periods,
        targetPeriodIds: {'late', 'early'},
        activities: const [AlgoActivity(id: 'swim', capacity: 5)],
        scheduledActivities: const [
          AlgoScheduledActivity(id: 's1', activityId: 'swim', periodId: 'late'),
          AlgoScheduledActivity(id: 's2', activityId: 'swim', periodId: 'early'),
        ],
        existingAssignments: const {},
        now: DateTime(2025, 7, 15),
      );
      final state = stateFor(context);
      generate(context, state: state);

      expect(
        [for (final c in state.potentialAssignments) '${c.participant.id}:${c.period.id}'],
        ['z:early', 'z:late', 'a:early', 'a:late'],
      );
      expect([for (final c in state.potentialAssignments) c.sequence], [0, 1, 2, 3]);
    });

    group('double-schedule activities', () {
      ScenarioBuilder base() =>
          ScenarioBuilder().day('mon', periods: 3).day('tue', periods: 2).activity('canoe', doubleSchedule: true).participant('a');

      test('yield ONE linked candidate for the whole block', () {
        final context = base().offer('canoe', ['mon1', 'mon2']).build();
        final state = stateFor(context);

        expect(generate(context, state: state), ['a:canoe@mon1+canoe@mon2']);
        final block = state.potentialAssignments.single;
        expect(block.isDoubleAssignment, isTrue);
        expect(block.period.id, 'mon1');
        expect(block.linkedPeriod!.id, 'mon2');
        expect(block.scheduledActivities.map((s) => s.id), ['canoe@mon1', 'canoe@mon2']);
        expect(block.periods.map((p) => p.id), ['mon1', 'mon2']);
      });

      test('overlapping blocks are all offered (mon1+mon2 and mon2+mon3)', () {
        final context = base().offer('canoe', ['mon1', 'mon2', 'mon3']).build();
        expect(generate(context), ['a:canoe@mon1+canoe@mon2', 'a:canoe@mon2+canoe@mon3']);
      });

      test('are not generated for the last period of a day', () {
        // mon3 is followed by tue1, which is on another day.
        final context = base().offer('canoe', ['mon3', 'tue1']).build();
        expect(generate(context), isEmpty);
      });

      test('are not generated when the next period does not offer the activity', () {
        final context = base().offer('canoe', ['mon1', 'mon3']).build();
        expect(generate(context), isEmpty);
      });

      test('are not generated when the participant is busy in the second period', () {
        final context =
            base().activity('swim').offer('canoe', ['mon1', 'mon2']).offer('swim', ['mon2']).existing('a', ['swim@mon2']).build();
        expect(generate(context), isEmpty);
      });

      test('may extend into a period that is not a target period', () {
        final context = base().offer('canoe', ['mon1', 'mon2']).targets(['mon1']).build();
        expect(generate(context), ['a:canoe@mon1+canoe@mon2']);
      });

      test('respect vetoes', () {
        final context =
            ScenarioBuilder()
                .day('mon', periods: 2)
                .activity('canoe', doubleSchedule: true)
                .offer('canoe', ['mon1', 'mon2'])
                .participant('a', vetoes: ['canoe'])
                .build();
        expect(generate(context), isEmpty);
      });
    });

    test('reports what it skipped', () {
      final context =
          ScenarioBuilder()
              .day('mon', periods: 1)
              .activity('swim')
              .activity('canoe', doubleSchedule: true)
              .offer('swim', ['mon1'])
              .offer('canoe', ['mon1'])
              .participant('a', vetoes: ['swim'])
              .build();
      final outcome = GeneratePotentialAssignmentsStep().execute(stateFor(context));

      expect(outcome.details['count'], 0);
      expect(outcome.details['skippedVetoed'], 1);
      expect(outcome.details['skippedUnfinishableDoubles'], 1);
    });
  });
}
