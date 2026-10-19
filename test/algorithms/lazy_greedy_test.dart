import 'dart:math';

import 'package:bessie/src/algorithms/assignment_engine.dart';
import 'package:bessie/src/algorithms/diplomatic_algorithm/diplomatic_scorer.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/eager_greedy_reference.dart';
import 'support/scenario_builder.dart';

/// The activity id of a placed scheduled activity id (`swim@mon1` -> `swim`).
String activityOf(String scheduledActivityId) => scheduledActivityId.split('@').first;

String periodOf(String scheduledActivityId) => scheduledActivityId.split('@').last;

void main() {
  group('lazy-greedy selection', () {
    test('a request is fulfilled in the period where capacity allows, even when an '
        'earlier period is full', () {
      // swim@mon1 is full (taken by campers outside the run); swim@mon2 is free.
      // The original scorer gave the request tier only to the first-generated
      // candidate (mon1), scored mon2 as a mere repeat and so lost the request.
      final context = ScenarioBuilder()
          .day('mon', periods: 2)
          .activity('swim', capacity: 1)
          .activity('art', capacity: 10)
          .offerEverywhere('swim')
          .offerEverywhere('art')
          .external('swim@mon1', 1)
          .participant('amy', requests: ['swim'])
          .build();

      for (var seed = 0; seed < 20; seed++) {
        final result = AssignmentEngine.run(context, random: Random(seed));
        expect(result.placedFor('amy'), containsAll(['swim@mon2', 'art@mon1']),
            reason: 'seed $seed');
        expect(result.stalemates, isEmpty);
      }
    });

    test('a request is fulfilled in whichever period still has room, not the earliest', () {
      // Five periods, only the LAST has a free swim seat. All earlier ones are full.
      final builder = ScenarioBuilder()
          .day('mon', periods: 5)
          .activity('swim', capacity: 1)
          .activity('art', capacity: 10)
          .offerEverywhere('swim')
          .offerEverywhere('art')
          .participant('amy', requests: ['swim']);
      for (final p in ['mon1', 'mon2', 'mon3', 'mon4']) {
        builder.external('swim@$p', 1);
      }
      final result = AssignmentEngine.run(builder.build(), random: Random(0));
      expect(result.placedFor('amy'), contains('swim@mon5'));
    });

    test('requests outrank novelty, which outranks repeats (placement order)', () {
      // One participant, unlimited seats: the greedy order is observable in the
      // order of placements. Request first, then each novel activity, then repeats.
      final context = ScenarioBuilder()
          .day('mon', periods: 6)
          .activity('swim')
          .activity('art')
          .activity('chess')
          .offerEverywhere('swim')
          .offerEverywhere('art')
          .offerEverywhere('chess')
          .participant('amy', requests: ['swim'])
          .build();

      for (var seed = 0; seed < 30; seed++) {
        final placed = AssignmentEngine.run(context, random: Random(seed))
            .newPlacements
            .map((p) => activityOf(p.scheduledActivityId))
            .toList();

        expect(placed, hasLength(6), reason: 'seed $seed');
        expect(placed.first, 'swim', reason: 'the request goes first (seed $seed)');
        expect(placed.take(3).toSet(), {'swim', 'art', 'chess'},
            reason: 'novelty before any repeat (seed $seed)');
      }
    });

    test('for a contested seat a request beats a merely novel candidate', () {
      final context = ScenarioBuilder()
          .day('mon', periods: 1)
          .activity('swim', capacity: 1)
          .activity('art', capacity: 10)
          .offer('swim', ['mon1'])
          .offer('art', ['mon1'])
          .participant('neutral')
          .participant('hopeful', requests: ['swim'])
          .build();

      for (var seed = 0; seed < 20; seed++) {
        final result = AssignmentEngine.run(context, random: Random(seed));
        expect(result.placedFor('hopeful'), ['swim@mon1'], reason: 'seed $seed');
        expect(result.placedFor('neutral'), ['art@mon1'], reason: 'seed $seed');
      }
    });

    test('for a contested seat a novel candidate beats a repeat', () {
      // chess@mon1 has ONE seat and is the only thing on offer in mon1.
      // 'veteran' already did chess (mon3), 'newbie' never did: novelty wins the
      // seat, and the veteran is left with a stalemate.
      final context = ScenarioBuilder()
          .day('mon', periods: 3)
          .activity('chess', capacity: 1)
          .offer('chess', ['mon1', 'mon3'])
          .participant('veteran')
          .participant('newbie')
          .existing('veteran', ['chess@mon3'])
          .targets(['mon1'])
          .build();

      for (var seed = 0; seed < 20; seed++) {
        final result = AssignmentEngine.run(context, random: Random(seed));
        expect(result.placedFor('newbie'), ['chess@mon1'], reason: 'seed $seed');
        expect(result.placedFor('veteran'), isEmpty, reason: 'seed $seed');
        expect(result.stalemateKeys, ['veteran@mon1'], reason: 'seed $seed');
      }
    });

    test('an unreceived request beats everything for the same participant', () {
      // Before anything else, amy is placed in the swim her request is about,
      // even though art would be "novel" too.
      final context = ScenarioBuilder()
          .day('mon', periods: 1)
          .activity('swim')
          .activity('art')
          .offer('swim', ['mon1'])
          .offer('art', ['mon1'])
          .participant('amy', requests: ['swim'])
          .build();
      final result = AssignmentEngine.run(context, random: Random(1));
      expect(result.placedFor('amy'), ['swim@mon1']);
    });

    test('is exactly the eager greedy: a worked example', () {
      final context = ScenarioBuilder()
          .day('mon', periods: 3)
          .activity('swim', capacity: 2)
          .activity('art', capacity: 2)
          .activity('chess', capacity: 2)
          .offerEverywhere('swim')
          .offerEverywhere('art')
          .offerEverywhere('chess')
          .participant('a', requests: ['swim'])
          .participant('b', requests: ['swim', 'chess'])
          .participant('c', requests: ['art'], vetoes: ['chess'])
          .build();

      final lazy = AssignmentEngine.run(context, random: Random(11));
      final eager = eagerGreedyPlacements(context, const DiplomaticScorer(), Random(11));
      expect(lazy.newPlacements, eager);

      // Every request is in the 1000 tier and never contested beyond capacity,
      // so all of them are fulfilled.
      expect(lazy.placedFor('a').map(activityOf), contains('swim'));
      expect(lazy.placedFor('b').map(activityOf), containsAll(['swim', 'chess']));
      expect(lazy.placedFor('c').map(activityOf), contains('art'));
      expect(lazy.placedFor('c').map(activityOf), isNot(contains('chess')));
    });

    test('re-scores stale entries instead of trusting the initial scores', () {
      // Everyone requests swim in every period: all 1000 at the start, and after
      // each acceptance the remaining candidates of that participant are stale.
      final builder = ScenarioBuilder()
          .day('mon', periods: 4)
          .activity('swim', capacity: 10)
          .activity('art', capacity: 10)
          .offerEverywhere('swim')
          .offerEverywhere('art');
      for (var i = 0; i < 5; i++) {
        builder.participant('p$i', requests: ['swim']);
      }
      final result = AssignmentEngine.run(builder.build(), random: Random(2));
      final process = result.stepReports.firstWhere((r) => r.stepName.startsWith('Process'));

      expect(process.details['rescored'], greaterThan(0));
      // Everybody got their request exactly once as the first thing, then novelty.
      for (var i = 0; i < 5; i++) {
        final activities = result.placedFor('p$i').map(activityOf).toList();
        expect(activities.first, 'swim');
        expect(activities.take(2).toSet(), {'swim', 'art'});
      }
    });

    test('drops candidates that violate constraints and never retries them', () {
      // One seat in swim, three participants who all want it: one accepted, the
      // other two are dropped on capacity for good.
      final context = ScenarioBuilder()
          .day('mon', periods: 1)
          .activity('swim', capacity: 1)
          .offer('swim', ['mon1'])
          .participant('a')
          .participant('b')
          .participant('c')
          .build();
      final result = AssignmentEngine.run(context, random: Random(0));
      final process = result.stepReports.firstWhere((r) => r.stepName.startsWith('Process'));

      expect(result.newPlacements, hasLength(1));
      expect(process.details['droppedByConstraint'], 2);
      expect(process.details['accepted'], 1);
    });

    test('skips candidates whose participant became busy in the meantime', () {
      // Double 'canoe' blocks mon1+mon2 and mon2+mon3 overlap: once one is
      // accepted the other is skipped (busy), not constraint-dropped.
      final context = ScenarioBuilder()
          .day('mon', periods: 3)
          .activity('canoe', doubleSchedule: true)
          .offerEverywhere('canoe')
          .participant('a')
          .build();
      final result = AssignmentEngine.run(context, random: Random(0));
      final process = result.stepReports.firstWhere((r) => r.stepName.startsWith('Process'));

      expect(result.newPlacements, hasLength(2));
      expect(process.details['skippedBusy'], 1);
      // The remaining period is a stalemate: a double activity cannot fill one period.
      expect(result.stalemates, hasLength(1));
    });

    test('never fills a period twice for the same participant', () {
      final context = ScenarioBuilder()
          .day('mon', periods: 2)
          .activity('swim')
          .activity('art')
          .offerEverywhere('swim')
          .offerEverywhere('art')
          .participant('a')
          .build();
      final result = AssignmentEngine.run(context, random: Random(4));
      final periods = result.placedFor('a').map(periodOf).toList();
      expect(periods.toSet(), hasLength(periods.length));
      expect(periods, hasLength(2));
    });
  });
}
