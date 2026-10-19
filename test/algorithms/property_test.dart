import 'dart:math';

import 'package:bessie/src/algorithms/assignment_engine.dart';
import 'package:bessie/src/algorithms/diplomatic_algorithm/diplomatic_scorer.dart';
import 'package:bessie/src/algorithms/greedy_scoring_algorithm/greedy_scorer.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/eager_greedy_reference.dart';
import 'support/invariants.dart';
import 'support/random_scenario.dart';
import 'support/scenario_builder.dart';

const _seeds = 300;

void main() {
  group('invariants hold for random scenarios', () {
    for (final strategy in AssignmentStrategy.values) {
      for (final stalemateStrategy in [
        StalemateStrategy.leaveUnassigned,
        StalemateStrategy.randomize,
      ]) {
        test('${strategy.name} / ${stalemateStrategy.name}: $_seeds seeds', () {
          var placements = 0;
          var stalemates = 0;
          for (var seed = 0; seed < _seeds; seed++) {
            final context = RandomScenario.generate(seed);
            final result = AssignmentEngine.run(
              context,
              strategy: strategy,
              stalemateStrategy: stalemateStrategy,
              random: Random(seed),
            );
            expectEngineInvariants(
              context,
              result,
              enforceStandardConstraints:
                  stalemateStrategy != StalemateStrategy.randomize,
              label: 'seed $seed:',
            );
            placements += result.newPlacements.length;
            stalemates += result.stalemates.length;
          }
          // The generator must actually exercise both outcomes, otherwise the
          // invariants above would be vacuous.
          expect(placements, greaterThan(_seeds));
          expect(stalemates, greaterThan(0));
        });
      }
    }
  });

  group('the lazy-greedy loop equals the eager greedy oracle', () {
    final scorers = {
      AssignmentStrategy.diplomatic: const DiplomaticScorer(),
      AssignmentStrategy.greedy: const GreedyScorer(),
    };
    for (final strategy in AssignmentStrategy.values) {
      test('${strategy.name}: identical placements, in identical order', () {
        for (var seed = 0; seed < _seeds; seed++) {
          final context = RandomScenario.generate(seed);
          final lazy = AssignmentEngine.run(context,
              strategy: strategy, random: Random(seed));
          final eager = eagerGreedyPlacements(context, scorers[strategy]!, Random(seed));
          expect(lazy.newPlacements, eager, reason: 'seed $seed');
        }
      });
    }
  });

  group('running again on the result as existing assignments', () {
    for (final stalemateStrategy in [
      StalemateStrategy.leaveUnassigned,
      StalemateStrategy.randomize,
    ]) {
      test('adds nothing and keeps every invariant (${stalemateStrategy.name})', () {
        for (var seed = 0; seed < _seeds; seed++) {
          final context = RandomScenario.generate(seed);
          final first = AssignmentEngine.run(context,
              stalemateStrategy: stalemateStrategy, random: Random(seed));

          final again = contextAfter(context, first);
          final second = AssignmentEngine.run(again,
              stalemateStrategy: stalemateStrategy, random: Random(seed + 1));

          expect(second.newPlacements, isEmpty, reason: 'seed $seed');
          expect(second.stalemateKeys, first.stalemateKeys, reason: 'seed $seed');
          expectEngineInvariants(again, second,
              enforceStandardConstraints:
                  stalemateStrategy != StalemateStrategy.randomize,
              label: 'seed $seed (second run):');
        }
      });
    }
  });

  group('same seed, same output', () {
    test('every strategy combination is reproducible', () {
      for (var seed = 0; seed < 60; seed++) {
        final context = RandomScenario.generate(seed);
        for (final strategy in AssignmentStrategy.values) {
          for (final stalemateStrategy in [
            StalemateStrategy.leaveUnassigned,
            StalemateStrategy.randomize,
          ]) {
            AssignmentResult run() => AssignmentEngine.run(context,
                strategy: strategy,
                stalemateStrategy: stalemateStrategy,
                random: Random(seed));
            final a = run();
            final b = run();
            expect(a.newPlacements, b.newPlacements, reason: 'seed $seed');
            expect(a.satisfaction, b.satisfaction, reason: 'seed $seed');
            expect(a.stalemateKeys, b.stalemateKeys, reason: 'seed $seed');
          }
        }
      }
    });
  });

  group('StalemateStrategy.fail', () {
    test('throws exactly when leaveUnassigned would record a stalemate', () {
      var threw = 0;
      var returned = 0;
      for (var seed = 0; seed < _seeds; seed++) {
        final context = RandomScenario.generate(seed);
        final left = AssignmentEngine.run(context, random: Random(seed));
        try {
          final result = AssignmentEngine.run(context,
              stalemateStrategy: StalemateStrategy.fail, random: Random(seed));
          expect(left.stalemates, isEmpty, reason: 'seed $seed');
          expect(result.newPlacements, left.newPlacements);
          returned++;
        } on AssignmentStalemateException catch (e) {
          final keys = [for (final s in e.stalemates) '${s.participantId}@${s.periodId}']
            ..sort();
          expect(keys, left.stalemateKeys, reason: 'seed $seed');
          threw++;
        }
      }
      expect(threw, greaterThan(0));
      expect(returned, greaterThan(0));
    });
  });
}
