import 'dart:math';

import 'package:bessie/src/algorithms/assignment_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/invariants.dart';
import 'support/scenario_builder.dart';

/// One period, one swim seat, [people] participants: everyone but one is stuck.
AssignmentContext oneSeat({int people = 2}) {
  final builder = ScenarioBuilder().day('mon', periods: 1).activity('swim', capacity: 1).offer('swim', ['mon1']);
  for (var i = 0; i < people; i++) {
    builder.participant('p$i');
  }
  return builder.build();
}

AssignmentResult run(AssignmentContext context, StalemateStrategy strategy, {int seed = 0}) =>
    AssignmentEngine.run(context, stalemateStrategy: strategy, random: Random(seed));

void main() {
  group('StalemateStrategy.leaveUnassigned', () {
    test('records a stalemate with a reason for every slot it could not fill', () {
      final context = oneSeat(people: 3);
      final result = run(context, StalemateStrategy.leaveUnassigned);

      expect(result.newPlacements, hasLength(1));
      expect(result.stalemates, hasLength(2));
      final placed = result.newPlacements.single.participantId;
      for (final stalemate in result.stalemates) {
        expect(stalemate.participantId, isNot(placed));
        expect(stalemate.periodId, 'mon1');
        expect(stalemate.reason, contains('swim'));
        expect(stalemate.reason, contains('full capacity'));
      }
      expectEngineInvariants(context, result);
    });

    test('is the default', () {
      final context = oneSeat();
      final byDefault = AssignmentEngine.run(context, random: Random(1));
      final explicit = run(context, StalemateStrategy.leaveUnassigned, seed: 1);
      expect(byDefault.placementStrings, explicit.placementStrings);
      expect(byDefault.stalemateKeys, explicit.stalemateKeys);
    });

    test('never throws and never places anything beyond the main pass', () {
      final context = oneSeat(people: 5);
      expect(() => run(context, StalemateStrategy.leaveUnassigned), returnsNormally);
      expect(run(context, StalemateStrategy.leaveUnassigned).newPlacements, hasLength(1));
    });

    test('hasStalemate is true exactly for the participants with a stalemate', () {
      final result = run(oneSeat(), StalemateStrategy.leaveUnassigned);
      final placed = result.newPlacements.single.participantId;
      final stuck = placed == 'p0' ? 'p1' : 'p0';

      expect(result.hasStalemate(stuck), isTrue);
      expect(result.hasStalemate(placed), isFalse);
      expect(result.hasStalemate('nobody'), isFalse);
    });

    test('a participant with a stalemate gets no satisfaction index (regression)', () {
      // The old code looked up stalemates by participantId although the keys
      // were "participantId-periodId", so this rule never fired.
      final context = oneSeat();
      final result = run(context, StalemateStrategy.leaveUnassigned);
      final placed = result.newPlacements.single.participantId;
      final stuck = placed == 'p0' ? 'p1' : 'p0';

      expect(result.satisfaction.keys, [placed]);
      expect(result.satisfaction.containsKey(stuck), isFalse);
    });
  });

  group('StalemateStrategy.fail', () {
    test('throws a typed AssignmentStalemateException carrying every stalemate', () {
      final context = oneSeat(people: 3);
      expect(
        () => run(context, StalemateStrategy.fail),
        throwsA(
          isA<AssignmentStalemateException>()
              .having((e) => e.stalemates, 'stalemates', hasLength(2))
              .having((e) => e, 'is an Exception', isA<Exception>()),
        ),
      );
    });

    test('lists participant, period and reason in a readable message', () {
      late AssignmentStalemateException error;
      try {
        run(oneSeat(), StalemateStrategy.fail);
        fail('expected an AssignmentStalemateException');
      } on AssignmentStalemateException catch (e) {
        error = e;
      }

      final stuck = error.stalemates.single;
      final text = error.toString();
      expect(text, contains('AssignmentStalemateException'));
      expect(text, contains('1 slot(s)'));
      expect(text, contains(stuck.participantId));
      expect(text, contains('mon1'));
      expect(text, contains('full capacity'));
      expect(text, contains(stuck.toString()));
    });

    test('the stalemate list cannot be modified by the catcher', () {
      try {
        run(oneSeat(), StalemateStrategy.fail);
        fail('expected an AssignmentStalemateException');
      } on AssignmentStalemateException catch (e) {
        expect(() => e.stalemates.clear(), throwsUnsupportedError);
      }
    });

    test('returns normally when everybody is placed', () {
      final context = oneSeat(people: 1);
      final result = run(context, StalemateStrategy.fail);
      expect(result.stalemates, isEmpty);
      expect(result.newPlacements, hasLength(1));
    });

    test('is not a bare Exception: catching the type works, catching by message is unnecessary', () {
      Object? caught;
      try {
        run(oneSeat(), StalemateStrategy.fail);
      } catch (e) {
        caught = e;
      }
      expect(caught.runtimeType, AssignmentStalemateException);
    });
  });

  group('StalemateStrategy.randomize', () {
    test('relaxes the assignment cap: a second swim is better than an empty period', () {
      final context =
          ScenarioBuilder()
              .day('mon', periods: 3)
              .activity('swim', maxAssignments: 1)
              .offer('swim', ['mon1', 'mon3'])
              .participant('a')
              .targets(['mon1', 'mon3'])
              .build();

      final left = run(context, StalemateStrategy.leaveUnassigned);
      expect(left.newPlacements, hasLength(1));
      expect(left.stalemates, hasLength(1));

      final randomized = run(context, StalemateStrategy.randomize);
      expect(randomized.placedFor('a'), unorderedEquals(['swim@mon1', 'swim@mon3']));
      expect(randomized.stalemates, isEmpty);
      expectEngineInvariants(context, randomized, enforceStandardConstraints: false);
    });

    test('relaxes adjacent repetition', () {
      final context = ScenarioBuilder().day('mon', periods: 2).activity('swim').offerEverywhere('swim').participant('a').build();

      expect(run(context, StalemateStrategy.leaveUnassigned).stalemates, hasLength(1));
      final randomized = run(context, StalemateStrategy.randomize);
      expect(randomized.placedFor('a'), unorderedEquals(['swim@mon1', 'swim@mon2']));
      expect(randomized.stalemates, isEmpty);
    });

    test('still respects capacity, and says so', () {
      final context = oneSeat(people: 3);
      final result = run(context, StalemateStrategy.randomize);

      expect(result.newPlacements, hasLength(1));
      expect(result.stalemates, hasLength(2));
      for (final stalemate in result.stalemates) {
        expect(stalemate.reason, contains('relaxed constraints'));
        expect(stalemate.reason, contains('full capacity'));
      }
      expectEngineInvariants(context, result, enforceStandardConstraints: false);
    });

    test('still counts seats taken by campers outside the run', () {
      final context =
          ScenarioBuilder()
              .day('mon', periods: 1)
              .activity('swim', capacity: 2)
              .offer('swim', ['mon1'])
              .external('swim@mon1', 2)
              .participant('a')
              .build();
      final result = run(context, StalemateStrategy.randomize);
      expect(result.newPlacements, isEmpty);
      expect(result.stalemateKeys, ['a@mon1']);
    });

    test('never places a vetoed activity, even as a last resort', () {
      final context =
          ScenarioBuilder().day('mon', periods: 1).activity('swim').offer('swim', ['mon1']).participant('a', vetoes: ['swim']).build();
      final result = run(context, StalemateStrategy.randomize);

      expect(result.newPlacements, isEmpty);
      expect(result.stalemates.single.reason, contains('Vetoed by the participant: swim'));
    });

    test('never places a hidden activity', () {
      final context =
          ScenarioBuilder()
              .day('mon', periods: 1)
              .activity('staffMeeting', assignable: false)
              .offer('staffMeeting', ['mon1'])
              .participant('a')
              .build();
      final result = run(context, StalemateStrategy.randomize);

      expect(result.newPlacements, isEmpty);
      expect(result.stalemates.single.reason, contains('No assignable activity'));
    });

    test('can place a whole double block, and fills both slots with it', () {
      // The participant is already at the cap for canoe (one block at mon3+mon4),
      // so the main pass cannot give another; the fallback relaxes the cap.
      final context =
          ScenarioBuilder()
              .day('mon', periods: 4)
              .activity('canoe', doubleSchedule: true, maxAssignments: 1)
              .offerEverywhere('canoe')
              .participant('a')
              .existing('a', ['canoe@mon3', 'canoe@mon4'])
              .targets(['mon1', 'mon2'])
              .build();

      final left = run(context, StalemateStrategy.leaveUnassigned);
      expect(left.stalemateKeys, ['a@mon1', 'a@mon2']);

      final randomized = run(context, StalemateStrategy.randomize);
      expect(randomized.placedFor('a'), ['canoe@mon1', 'canoe@mon2']);
      expect(randomized.stalemates, isEmpty);
      expectEngineInvariants(context, randomized, enforceStandardConstraints: false);
    });

    test('cannot place a double activity that has no valid second period', () {
      final context =
          ScenarioBuilder()
              .day('mon', periods: 3)
              .activity('canoe', doubleSchedule: true)
              .offer('canoe', ['mon3']) // last period of the day: no second half
              .participant('a')
              .targets(['mon3'])
              .build();
      final result = run(context, StalemateStrategy.randomize);

      expect(result.newPlacements, isEmpty);
      expect(result.stalemates.single.reason, contains('double-schedule'));
    });

    test('picks among the options at random, reproducibly for a seed', () {
      // Every option is blocked in the main pass (cap reached), so the fallback
      // chooses among art / chess / swim by chance.
      AssignmentContext context() =>
          ScenarioBuilder()
              .day('mon', periods: 4)
              .activity('art', maxAssignments: 1)
              .activity('chess', maxAssignments: 1)
              .activity('swim', maxAssignments: 1)
              .offerEverywhere('art')
              .offerEverywhere('chess')
              .offerEverywhere('swim')
              .participant('a')
              .existing('a', ['art@mon1', 'chess@mon2', 'swim@mon3'])
              .targets(['mon4'])
              .build();

      final chosen = <String>{};
      for (var seed = 0; seed < 40; seed++) {
        final result = run(context(), StalemateStrategy.randomize, seed: seed);
        expect(result.newPlacements, hasLength(1));
        chosen.add(result.newPlacements.single.scheduledActivityId);

        final again = run(context(), StalemateStrategy.randomize, seed: seed);
        expect(again.newPlacements, result.newPlacements, reason: 'seed $seed');
      }
      expect(chosen, {'art@mon4', 'chess@mon4', 'swim@mon4'});
    });

    test('hands out contested seats in a random order, not in participant order', () {
      // Both participants are at their cap for swim (and next to a swim they
      // hold), so both are stuck in the main pass; swim@mon2 has ONE seat and
      // the fallback must give it to either of them by chance.
      final winners = <String>{};
      for (var seed = 0; seed < 40; seed++) {
        final context =
            ScenarioBuilder()
                .day('mon', periods: 3)
                .activity('swim', capacity: 1, maxAssignments: 1)
                .offerEverywhere('swim')
                .participant('first')
                .participant('second')
                .existing('first', ['swim@mon1'])
                .existing('second', ['swim@mon3'])
                .targets(['mon2'])
                .build();

        expect(run(context, StalemateStrategy.leaveUnassigned, seed: seed).newPlacements, isEmpty);
        final result = run(context, StalemateStrategy.randomize, seed: seed);
        expect(result.newPlacements, hasLength(1));
        expect(result.stalemates, hasLength(1));
        winners.add(result.newPlacements.single.participantId);
      }
      expect(winners, {'first', 'second'});
    });

    test('never throws', () {
      expect(() => run(oneSeat(people: 4), StalemateStrategy.randomize), returnsNormally);
    });

    test('fills nothing extra when the main pass already filled everything', () {
      final context = oneSeat(people: 1);
      final result = run(context, StalemateStrategy.randomize);
      expect(result.newPlacements, hasLength(1));
      expect(result.stalemates, isEmpty);
    });
  });

  group('stalemate reasons', () {
    test('say when no assignable activity is scheduled at all', () {
      final context = ScenarioBuilder().day('mon', periods: 1).participant('a').build();
      final result = run(context, StalemateStrategy.leaveUnassigned);
      expect(result.stalemates.single.reason, 'No assignable activity is scheduled in this period.');
    });

    test('name vetoed activities', () {
      final context =
          ScenarioBuilder().day('mon', periods: 1).activity('swim').offer('swim', ['mon1']).participant('a', vetoes: ['swim']).build();
      final reason = run(context, StalemateStrategy.leaveUnassigned).stalemates.single.reason;
      expect(reason, contains('Vetoed by the participant: swim'));
    });

    test('explain a reached assignment cap', () {
      final context =
          ScenarioBuilder()
              .day('mon', periods: 3)
              .activity('swim', maxAssignments: 1)
              .offer('swim', ['mon1', 'mon3'])
              .participant('a')
              .targets(['mon1', 'mon3'])
              .build();
      final reason = run(context, StalemateStrategy.leaveUnassigned).stalemates.single.reason;
      expect(reason, contains('maximum number of assignments'));
    });

    test('explain a double activity that cannot be completed', () {
      final context =
          ScenarioBuilder()
              .day('mon', periods: 1)
              .activity('canoe', doubleSchedule: true)
              .offer('canoe', ['mon1'])
              .participant('a')
              .build();
      final reason = run(context, StalemateStrategy.leaveUnassigned).stalemates.single.reason;
      expect(reason, contains('double-schedule activity that cannot be completed'));
    });

    test('are only produced for target periods', () {
      final context = ScenarioBuilder().day('mon', periods: 2).participant('a').targets(['mon2']).build();
      expect(run(context, StalemateStrategy.leaveUnassigned).stalemateKeys, ['a@mon2']);
    });

    test('are not produced for periods in which the participant is already busy', () {
      final context =
          ScenarioBuilder()
              .day('mon', periods: 2)
              .activity('staffMeeting', assignable: false)
              .offer('staffMeeting', ['mon1'])
              .participant('a')
              .existing('a', ['staffMeeting@mon1'])
              .build();
      expect(run(context, StalemateStrategy.leaveUnassigned).stalemateKeys, ['a@mon2']);
    });
  });
}
