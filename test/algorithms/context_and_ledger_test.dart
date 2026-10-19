import 'package:bessie/src/algorithms/assignment_engine.dart';
import 'package:bessie/src/algorithms/data_models/assignment_ledger.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/candidates.dart';
import 'support/scenario_builder.dart';

void main() {
  group('AssignmentContext', () {
    test(
      'sorts periods chronologically whatever order they are supplied in',
      () {
        final context = AssignmentContext(
          participants: const [],
          preferences: const {},
          periods: [
            AlgoPeriod(
              id: 'tue1',
              dayId: 'tue',
              start: DateTime(2025, 7, 15, 9),
            ),
            AlgoPeriod(
              id: 'mon2',
              dayId: 'mon',
              start: DateTime(2025, 7, 14, 10),
            ),
            AlgoPeriod(
              id: 'mon1',
              dayId: 'mon',
              start: DateTime(2025, 7, 14, 9),
            ),
          ],
          targetPeriodIds: {'tue1', 'mon1'},
          activities: const [],
          scheduledActivities: const [],
          existingAssignments: const {},
          now: DateTime(2025, 7, 15),
        );

        expect(context.periods.map((p) => p.id), ['mon1', 'mon2', 'tue1']);
        expect(context.targetPeriods.map((p) => p.id), ['mon1', 'tue1']);
        expect(context.periodIndex('tue1'), 2);
        expect(context.nextPeriod('mon1')!.id, 'mon2');
        expect(context.nextPeriod('mon2')!.id, 'tue1');
        expect(context.nextPeriod('tue1'), isNull);
        expect(() => context.periodIndex('nope'), throwsArgumentError);
      },
    );

    test('decides "same day" by dayId, not by formatting dates', () {
      final context =
          ScenarioBuilder()
              .day('mon', periods: 2)
              .day('tue', periods: 1)
              .build();
      final mon1 = context.periodById('mon1')!;
      final mon2 = context.periodById('mon2')!;
      final tue1 = context.periodById('tue1')!;

      expect(context.isSameDay(mon1, mon2), isTrue);
      expect(context.isSameDay(mon2, tue1), isFalse);

      // Two periods with the same calendar date but different dayIds are
      // different days, and vice versa.
      final a = AlgoPeriod(
        id: 'a',
        dayId: 'x',
        start: DateTime(2025, 7, 14, 9),
      );
      final b = AlgoPeriod(
        id: 'b',
        dayId: 'y',
        start: DateTime(2025, 7, 14, 10),
      );
      final c = AlgoPeriod(
        id: 'c',
        dayId: 'x',
        start: DateTime(2025, 7, 20, 10),
      );
      expect(context.isSameDay(a, b), isFalse);
      expect(context.isSameDay(a, c), isTrue);
    });

    test('computes ages against the supplied now, never the system clock', () {
      DateTime birth(int y, int m, int d) => DateTime(y, m, d);
      AssignmentContext at(DateTime now) => AssignmentContext(
        participants: [
          AlgoParticipant(id: 'birthdayToday', birthdate: birth(2010, 7, 15)),
          AlgoParticipant(
            id: 'birthdayTomorrow',
            birthdate: birth(2010, 7, 16),
          ),
          AlgoParticipant(
            id: 'birthdayYesterday',
            birthdate: birth(2010, 7, 14),
          ),
          AlgoParticipant(id: 'laterMonth', birthdate: birth(2010, 12, 1)),
          AlgoParticipant(id: 'earlierMonth', birthdate: birth(2010, 1, 1)),
        ],
        preferences: const {},
        periods: const [],
        targetPeriodIds: const {},
        activities: const [],
        scheduledActivities: const [],
        existingAssignments: const {},
        now: now,
      );

      final c2025 = at(DateTime(2025, 7, 15));
      expect(c2025.ageOf('birthdayToday'), 15);
      expect(c2025.ageOf('birthdayTomorrow'), 14);
      expect(c2025.ageOf('birthdayYesterday'), 15);
      expect(c2025.ageOf('laterMonth'), 14);
      expect(c2025.ageOf('earlierMonth'), 15);

      // The same people are 10 years younger in 2015, whatever today is.
      final c2015 = at(DateTime(2015, 7, 15));
      expect(c2015.ageOf('birthdayToday'), 5);
      expect(c2015.ageOf('laterMonth'), 4);
    });

    test('rejects duplicate ids and unknown target periods', () {
      AssignmentContext withPeriods(
        List<AlgoPeriod> periods,
        Set<String> targets,
      ) => AssignmentContext(
        participants: const [],
        preferences: const {},
        periods: periods,
        targetPeriodIds: targets,
        activities: const [],
        scheduledActivities: const [],
        existingAssignments: const {},
        now: DateTime(2025),
      );
      final p = AlgoPeriod(id: 'p', dayId: 'd', start: DateTime(2025));

      expect(() => withPeriods([p, p], {}), throwsArgumentError);
      expect(() => withPeriods([p], {'missing'}), throwsArgumentError);
      expect(() => withPeriods([p], {'p'}), returnsNormally);
    });

    test('ignores dangling references instead of crashing', () {
      final context = AssignmentContext(
        participants: [AlgoParticipant(id: 'a', birthdate: DateTime(2013))],
        preferences: const {
          'ghost': {'swim': PreferenceType.veto},
        },
        periods: [
          AlgoPeriod(id: 'p', dayId: 'd', start: DateTime(2025, 7, 14, 9)),
        ],
        targetPeriodIds: {'p'},
        activities: const [AlgoActivity(id: 'swim', capacity: 2)],
        scheduledActivities: const [
          AlgoScheduledActivity(id: 'ok', activityId: 'swim', periodId: 'p'),
          AlgoScheduledActivity(
            id: 'noActivity',
            activityId: 'missing',
            periodId: 'p',
          ),
          AlgoScheduledActivity(
            id: 'noPeriod',
            activityId: 'swim',
            periodId: 'missing',
          ),
        ],
        existingAssignments: const {
          'a': {'ghostScheduled'},
        },
        now: DateTime(2025, 7, 15),
      );

      expect(context.scheduledActivitiesIn('p').map((s) => s.id), ['ok']);
      expect(context.scheduledActivityById('noActivity'), isNull);
      expect(context.scheduledActivityById('noPeriod'), isNull);
      final result = AssignmentEngine.run(context);
      expect(result.newPlacements.map((p) => p.scheduledActivityId), ['ok']);
    });

    test(
      'copies its inputs, so later mutation by the caller changes nothing',
      () {
        final period = AlgoPeriod(
          id: 'p',
          dayId: 'd',
          start: DateTime(2025, 7, 14, 9),
        );
        final periods = [period];
        final existing = <String, Set<String>>{
          'a': {'s'},
        };
        final context = AssignmentContext(
          participants: [AlgoParticipant(id: 'a', birthdate: DateTime(2013))],
          preferences: const {},
          periods: periods,
          targetPeriodIds: {'p'},
          activities: const [AlgoActivity(id: 'swim', capacity: 2)],
          scheduledActivities: const [
            AlgoScheduledActivity(id: 's', activityId: 'swim', periodId: 'p'),
          ],
          existingAssignments: existing,
          now: DateTime(2025, 7, 15),
        );

        periods.clear();
        existing['a']!.clear();

        expect(context.periods, hasLength(1));
        expect(context.existingAssignments['a'], {'s'});
        expect(() => context.periods.add(period), throwsUnsupportedError);
      },
    );

    test('looks up the scheduled instance of an activity in a period', () {
      final context =
          ScenarioBuilder().day('mon', periods: 2).activity('swim').offer(
            'swim',
            ['mon2'],
          ).build();
      expect(context.scheduledActivityOf('swim', 'mon2')!.id, 'swim@mon2');
      expect(context.scheduledActivityOf('swim', 'mon1'), isNull);
    });
  });

  group('AssignmentLedger', () {
    test('counts every existing assignment exactly once', () {
      final context =
          ScenarioBuilder()
              .day('mon', periods: 3)
              .activity('swim', capacity: 5, maxAssignments: 3)
              .offerEverywhere('swim')
              .participant('a')
              .participant('b')
              .existing('a', ['swim@mon1', 'swim@mon3'])
              .existing('b', ['swim@mon1'])
              .build();
      final ledger = AssignmentLedger(context);

      expect(ledger.seatsTaken('swim@mon1'), 2);
      expect(ledger.seatsTaken('swim@mon2'), 0);
      expect(ledger.seatsTaken('swim@mon3'), 1);
      expect(ledger.occurrences('a', 'swim'), 2);
      expect(ledger.occurrences('b', 'swim'), 1);
      expect(ledger.newPlacements, isEmpty);
    });

    test(
      'seeds seats from external enrollment, on top of the run participants',
      () {
        final context =
            ScenarioBuilder()
                .day('mon', periods: 1)
                .activity('swim', capacity: 5)
                .offer('swim', ['mon1'])
                .participant('a')
                .existing('a', ['swim@mon1'])
                .external('swim@mon1', 3)
                .build();
        expect(AssignmentLedger(context).seatsTaken('swim@mon1'), 4);
      },
    );

    test(
      'ignores existing assignments of people who are not part of the run',
      () {
        final context =
            ScenarioBuilder()
                .day('mon', periods: 1)
                .activity('swim', capacity: 5)
                .offer('swim', ['mon1'])
                .participant('a')
                .existing('stranger', [
                  'swim@mon1',
                ]) // their seat belongs in `external`
                .build();
        expect(AssignmentLedger(context).seatsTaken('swim@mon1'), 0);
      },
    );

    test(
      'treats hidden activities as first-class: busy and occupying a seat',
      () {
        final context =
            ScenarioBuilder()
                .day('mon', periods: 2)
                .activity('swim')
                .activity('lifeguard', capacity: 1, assignable: false)
                .offerEverywhere('swim')
                .offer('lifeguard', ['mon1'])
                .participant('a')
                .existing('a', ['lifeguard@mon1'])
                .build();
        final ledger = AssignmentLedger(context);

        expect(ledger.isBusy('a', context.periodIndex('mon1')), isTrue);
        expect(ledger.isBusy('a', context.periodIndex('mon2')), isFalse);
        expect(ledger.seatsTaken('lifeguard@mon1'), 1);
        expect(
          ledger.heldIn('a', context.periodIndex('mon1'))!.id,
          'lifeguard@mon1',
        );
        expect(ledger.holds('a', 'lifeguard'), isTrue);
      },
    );

    test(
      'place() records seats, busy periods and occurrences, and reports new placements',
      () {
        final context =
            ScenarioBuilder()
                .day('mon', periods: 3)
                .activity('swim')
                .offerEverywhere('swim')
                .participant('a')
                .existing('a', ['swim@mon1'])
                .build();
        final ledger = AssignmentLedger(context);

        ledger.place(candidateOf(context, 'a', 'swim', 'mon3'));

        expect(ledger.isBusy('a', context.periodIndex('mon3')), isTrue);
        expect(ledger.seatsTaken('swim@mon3'), 1);
        expect(ledger.occurrences('a', 'swim'), 2);
        expect(ledger.periodIndicesOf('a', 'swim'), [0, 2]);
        expect(ledger.newPlacements, [
          const NewPlacement(
            participantId: 'a',
            scheduledActivityId: 'swim@mon3',
          ),
        ]);
      },
    );

    test('place() records both halves of a double block as one occurrence', () {
      final context =
          ScenarioBuilder()
              .day('mon', periods: 3)
              .activity('canoe', doubleSchedule: true)
              .offerEverywhere('canoe')
              .participant('a')
              .build();
      final ledger = AssignmentLedger(context);

      ledger.place(
        candidateOf(context, 'a', 'canoe', 'mon2', linkedPeriodId: 'mon3'),
      );

      expect(ledger.seatsTaken('canoe@mon2'), 1);
      expect(ledger.seatsTaken('canoe@mon3'), 1);
      expect(ledger.occurrences('a', 'canoe'), 1);
      expect(ledger.newPlacements.map((p) => p.scheduledActivityId), [
        'canoe@mon2',
        'canoe@mon3',
      ]);
      expect(ledger.weekActivityIds('a').toList(), ['canoe', 'canoe']);
    });

    test('place() refuses to double-book and leaves the ledger untouched', () {
      final context =
          ScenarioBuilder()
              .day('mon', periods: 3)
              .activity('swim')
              .activity('canoe', doubleSchedule: true)
              .offerEverywhere('swim')
              .offerEverywhere('canoe')
              .participant('a')
              .existing('a', ['swim@mon3'])
              .build();
      final ledger = AssignmentLedger(context);

      expect(
        () => ledger.place(candidateOf(context, 'a', 'swim', 'mon3')),
        throwsStateError,
      );
      // The second half collides: nothing of the block may be recorded.
      expect(
        () => ledger.place(
          candidateOf(context, 'a', 'canoe', 'mon2', linkedPeriodId: 'mon3'),
        ),
        throwsStateError,
      );
      expect(ledger.isBusy('a', context.periodIndex('mon2')), isFalse);
      expect(ledger.seatsTaken('canoe@mon2'), 0);
      expect(ledger.newPlacements, isEmpty);
    });

    test('isFree() looks at every period a candidate occupies', () {
      final context =
          ScenarioBuilder()
              .day('mon', periods: 3)
              .activity('swim')
              .activity('canoe', doubleSchedule: true)
              .offerEverywhere('swim')
              .offerEverywhere('canoe')
              .participant('a')
              .existing('a', ['swim@mon2'])
              .build();
      final ledger = AssignmentLedger(context);

      expect(ledger.isFree(candidateOf(context, 'a', 'swim', 'mon1')), isTrue);
      expect(ledger.isFree(candidateOf(context, 'a', 'swim', 'mon2')), isFalse);
      expect(
        ledger.isFree(
          candidateOf(context, 'a', 'canoe', 'mon1', linkedPeriodId: 'mon2'),
        ),
        isFalse,
      );
    });

    test(
      'weekActivityIds lists existing and new placements chronologically',
      () {
        final context =
            ScenarioBuilder()
                .day('mon', periods: 4)
                .activity('swim')
                .activity('art')
                .offerEverywhere('swim')
                .offerEverywhere('art')
                .participant('a')
                .existing('a', ['art@mon4', 'swim@mon1'])
                .build();
        final ledger = AssignmentLedger(context);
        ledger.place(candidateOf(context, 'a', 'art', 'mon2'));

        expect(ledger.weekActivityIds('a').toList(), ['swim', 'art', 'art']);
        expect(ledger.weekActivityIds('unknown'), isEmpty);
      },
    );

    group('occurrences of existing double-schedule blocks', () {
      int occurrences(
        List<String> held, {
        int periods = 6,
        bool twoDays = false,
      }) {
        final builder = ScenarioBuilder();
        if (twoDays) {
          builder
              .day('mon', periods: periods ~/ 2)
              .day('tue', periods: periods ~/ 2);
        } else {
          builder.day('mon', periods: periods);
        }
        final context =
            builder
                .activity('canoe', doubleSchedule: true)
                .offerEverywhere('canoe')
                .participant('a')
                .existing('a', [for (final p in held) 'canoe@$p'])
                .build();
        return AssignmentLedger(context).occurrences('a', 'canoe');
      }

      test('two adjacent periods are one block', () {
        expect(occurrences(['mon1', 'mon2']), 1);
      });

      test('back-to-back blocks are paired from the start of the chain', () {
        expect(occurrences(['mon1', 'mon2', 'mon3', 'mon4']), 2);
      });

      test('separated periods are separate occurrences', () {
        expect(occurrences(['mon1', 'mon3']), 2);
      });

      test('adjacent periods on different days are not a block', () {
        expect(occurrences(['mon3', 'tue1'], twoDays: true), 2);
      });
    });
  });
}
