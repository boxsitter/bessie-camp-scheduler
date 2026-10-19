import 'dart:math';

import 'package:bessie/src/algorithms/assignment_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/invariants.dart';
import 'support/random_scenario.dart';
import 'support/scenario_builder.dart';

AssignmentResult greedy(AssignmentContext context, {int seed = 0}) => AssignmentEngine.run(
      context,
      strategy: AssignmentStrategy.greedy,
      random: Random(seed),
    );

AssignmentResult diplomatic(AssignmentContext context, {int seed = 0}) =>
    AssignmentEngine.run(context, random: Random(seed));

void main() {
  group('the greedy strategy is wired up', () {
    test('runs through the same pipeline and produces the same kind of result', () {
      final context = RandomScenario.generate(3);
      final result = greedy(context);

      expect(result.stepReports.map((r) => r.stepName).toList(), [
        'Generate Potential Assignments',
        'Score Assignments (greedy)',
        'Sort Assignments',
        'Process & Finalize Assignments',
        'Resolve Stalemates',
        'Generate Evaluation Report',
      ]);
      expect(result.evaluationReports, hasLength(context.participants.length));
      expectEngineInvariants(context, result);
    });

    test('diplomatic is the default strategy', () {
      final context = RandomScenario.generate(5);
      final byDefault = AssignmentEngine.run(context, random: Random(1));
      expect(byDefault.stepReports[1].stepName, 'Score Assignments (diplomatic)');
      expect(byDefault.placementStrings,
          diplomatic(context, seed: 1).placementStrings);
    });

    test('honours the stalemate strategy', () {
      final context = ScenarioBuilder()
          .day('mon', periods: 1)
          .activity('swim', capacity: 1)
          .offer('swim', ['mon1'])
          .participant('a')
          .participant('b')
          .build();
      expect(
        () => AssignmentEngine.run(context,
            strategy: AssignmentStrategy.greedy,
            stalemateStrategy: StalemateStrategy.fail,
            random: Random(0)),
        throwsA(isA<AssignmentStalemateException>()),
      );
      final left = greedy(context);
      expect(left.stalemates, hasLength(1));
    });
  });

  group('greedy versus diplomatic', () {
    test('greedy repeats a request, diplomatic prefers something new', () {
      // Two days with one period each, so there is no same-day penalty and no
      // adjacency. amy requests swim; art is the neutral alternative.
      final context = ScenarioBuilder()
          .day('mon', periods: 1)
          .day('tue', periods: 1)
          .activity('swim')
          .activity('art')
          .offerEverywhere('swim')
          .offerEverywhere('art')
          .participant('amy', age: 14, requests: ['swim'])
          .build();

      for (var seed = 0; seed < 10; seed++) {
        // Diplomatic: request (1000), then novelty (500) beats a repeat (10).
        final d = diplomatic(context, seed: seed).placedFor('amy').map((s) => s.split('@').first);
        expect(d.toSet(), {'swim', 'art'}, reason: 'diplomatic, seed $seed');

        // Greedy: request +100 beats neutral +10 every time.
        final g = greedy(context, seed: seed).placedFor('amy').map((s) => s.split('@').first);
        expect(g.toList(), ['swim', 'swim'], reason: 'greedy, seed $seed');
      }
    });

    test('greedy keeps repeats of its favourite apart and never goes back-to-back', () {
      // One day, swim requested, art the only alternative. Greedy loves swim
      // (+100 against +10) but never puts it in adjacent periods. It has no
      // backtracking, so the last gap may be left as a stalemate.
      final context = ScenarioBuilder()
          .day('mon', periods: 4)
          .activity('swim')
          .activity('art')
          .offerEverywhere('swim')
          .offerEverywhere('art')
          .participant('amy', age: 14, requests: ['swim'])
          .build();
      for (var seed = 0; seed < 20; seed++) {
        final result = greedy(context, seed: seed);
        final swims = [
          for (final s in result.placedFor('amy'))
            if (s.startsWith('swim')) int.parse(s.split('mon').last),
        ]..sort();

        expect(swims.length, greaterThanOrEqualTo(2), reason: 'seed $seed');
        for (var i = 1; i < swims.length; i++) {
          expect(swims[i] - swims[i - 1], greaterThan(1), reason: 'seed $seed');
        }
        // Greedy takes swim before anything else: more swims than a diplomatic run.
        expect(result.placedFor('amy').length, greaterThanOrEqualTo(3), reason: 'seed $seed');
      }
    });

    test('a request wins a contested seat over a neutral camper', () {
      final context = ScenarioBuilder()
          .day('mon', periods: 1)
          .activity('swim', capacity: 1)
          .activity('art', capacity: 5)
          .offer('swim', ['mon1'])
          .offer('art', ['mon1'])
          .participant('neutral', age: 14)
          .participant('hopeful', age: 14, requests: ['swim'])
          .build();
      for (var seed = 0; seed < 10; seed++) {
        expect(greedy(context, seed: seed).placedFor('hopeful'), ['swim@mon1']);
      }
    });

    test('the age bonus lets the younger camper win a contested seat', () {
      // Two neutral campers, one seat. Greedy: +20 for age <= 8 decides it.
      // Diplomatic has its age bonus disabled, so it is down to the tiebreak.
      final context = ScenarioBuilder()
          .day('mon', periods: 1)
          .activity('swim', capacity: 1)
          .offer('swim', ['mon1'])
          .participant('teen', age: 14)
          .participant('little', age: 7)
          .build();

      final greedyWinners = <String>{};
      final diplomaticWinners = <String>{};
      for (var seed = 0; seed < 30; seed++) {
        greedyWinners.add(greedy(context, seed: seed).newPlacements.single.participantId);
        diplomaticWinners
            .add(diplomatic(context, seed: seed).newPlacements.single.participantId);
      }
      expect(greedyWinners, {'little'});
      expect(diplomaticWinners, {'little', 'teen'});
    });

    test('never places a vetoed activity', () {
      for (var seed = 0; seed < 100; seed++) {
        final context = RandomScenario.generate(seed);
        final result = greedy(context, seed: seed);
        for (final placement in result.newPlacements) {
          final scheduled = context.scheduledActivityById(placement.scheduledActivityId)!;
          expect(context.preferenceOf(placement.participantId, scheduled.activityId),
              isNot(PreferenceType.veto),
              reason: 'seed $seed');
        }
      }
    });
  });
}
