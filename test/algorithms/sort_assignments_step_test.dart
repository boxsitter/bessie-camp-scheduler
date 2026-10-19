import 'dart:math';

import 'package:bessie/src/algorithms/assignment_engine.dart';
import 'package:bessie/src/algorithms/common/steps/generate_potential_assignments_step.dart';
import 'package:bessie/src/algorithms/common/steps/score_assignments_step.dart';
import 'package:bessie/src/algorithms/common/steps/sort_assignments_step.dart';
import 'package:bessie/src/algorithms/data_models/pipeline_state.dart';
import 'package:bessie/src/algorithms/data_models/potential_assignment.dart';
import 'package:bessie/src/algorithms/diplomatic_algorithm/diplomatic_scorer.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/candidates.dart';
import 'support/scenario_builder.dart';

/// 4 participants x 3 periods of the same neutral activity: 12 candidates that
/// all have the same score, so ordering is decided purely by the tiebreak.
PipelineState tiedState() {
  final context = ScenarioBuilder()
      .day('mon', periods: 3)
      .activity('swim', capacity: 20)
      .offerEverywhere('swim')
      .participant('a')
      .participant('b')
      .participant('c')
      .participant('d')
      .build();
  final state = stateFor(context);
  GeneratePotentialAssignmentsStep().execute(state);
  ScoreAssignmentsStep(const DiplomaticScorer()).execute(state);
  return state;
}

String orderOf(PipelineState state) => [
      for (final c in state.potentialAssignments) '${c.participant.id}${c.period.id}',
    ].join(',');

/// A [Random] that counts how it is used.
class CountingRandom implements Random {
  final Random _inner;
  int doubles = 0;
  int other = 0;

  CountingRandom(int seed) : _inner = Random(seed);

  @override
  double nextDouble() {
    doubles++;
    return _inner.nextDouble();
  }

  @override
  int nextInt(int max) {
    other++;
    return _inner.nextInt(max);
  }

  @override
  bool nextBool() {
    other++;
    return _inner.nextBool();
  }
}

void main() {
  group('SortAssignmentsStep', () {
    test('orders by score descending, then by the random tiebreak ascending', () {
      final state = tiedState();
      // Give a few candidates distinct, higher scores.
      state.potentialAssignments[3].score = 900;
      state.potentialAssignments[7].score = 700;
      SortAssignmentsStep(random: Random(1)).execute(state);

      final sorted = state.potentialAssignments;
      expect(sorted[0].score, 900);
      expect(sorted[1].score, 700);
      for (var i = 1; i < sorted.length; i++) {
        final a = sorted[i - 1];
        final b = sorted[i];
        expect(a.score, greaterThanOrEqualTo(b.score));
        if (a.score == b.score) {
          expect(a.tiebreak, lessThan(b.tiebreak), reason: 'tie between #${i - 1} and #$i');
        }
      }
    });

    test('is deterministic for a seeded Random', () {
      final first = tiedState();
      final second = tiedState();
      SortAssignmentsStep(random: Random(42)).execute(first);
      SortAssignmentsStep(random: Random(42)).execute(second);

      expect(orderOf(first), orderOf(second));
    });

    test('different seeds order tied candidates differently', () {
      final orders = <String>{};
      for (var seed = 0; seed < 10; seed++) {
        final state = tiedState();
        SortAssignmentsStep(random: Random(seed)).execute(state);
        orders.add(orderOf(state));
      }
      expect(orders.length, greaterThan(5));
    });

    test('draws exactly ONE key per candidate, not one per comparison', () {
      final state = tiedState();
      final random = CountingRandom(3);
      SortAssignmentsStep(random: random).execute(state);

      expect(random.doubles, 12);
      expect(random.other, 0);
    });

    test('yields the same order whatever order the candidates arrive in', () {
      // With the keys fixed, (score, tiebreak, sequence) is a strict total
      // order, so sorting any permutation gives the same result. A comparator
      // that flips a coin on ties would not.
      final base = tiedState();
      SortAssignmentsStep(random: Random(5)).execute(base);
      final expected = orderOf(base);

      for (var seed = 0; seed < 20; seed++) {
        final shuffled = [...base.potentialAssignments]..shuffle(Random(seed));
        shuffled.sort(PotentialAssignment.byPriority);
        expect(
          shuffled.map((c) => '${c.participant.id}${c.period.id}').join(','),
          expected,
          reason: 'permutation $seed',
        );
      }
    });

    test('byPriority is antisymmetric and never reports a tie between distinct candidates', () {
      final state = tiedState();
      SortAssignmentsStep(random: Random(9)).execute(state);
      final candidates = state.potentialAssignments;

      for (final a in candidates) {
        for (final b in candidates) {
          final ab = PotentialAssignment.byPriority(a, b);
          final ba = PotentialAssignment.byPriority(b, a);
          if (identical(a, b)) {
            expect(ab, 0);
          } else {
            expect(ab.sign, -ba.sign);
            expect(ab, isNot(0));
          }
        }
      }
    });

    test('falls back to generation order if two keys are identical', () {
      final state = tiedState();
      for (final c in state.potentialAssignments) {
        c.tiebreak = 0.5;
      }
      state.potentialAssignments.shuffle(Random(2));
      state.potentialAssignments.sort(PotentialAssignment.byPriority);

      expect([for (final c in state.potentialAssignments) c.sequence],
          List.generate(12, (i) => i));
    });

    test('ties are broken fairly: a contested seat does not always go to the first in line', () {
      // Ten identical participants, one seat, nothing else to choose from.
      final winners = <String>{};
      for (var seed = 0; seed < 60; seed++) {
        final builder = ScenarioBuilder()
            .day('mon', periods: 1)
            .activity('swim', capacity: 1)
            .offer('swim', ['mon1']);
        for (var i = 0; i < 10; i++) {
          builder.participant('p$i');
        }
        final result = AssignmentEngine.run(builder.build(), random: Random(seed));
        expect(result.newPlacements, hasLength(1));
        winners.add(result.newPlacements.single.participantId);
      }
      expect(winners.length, greaterThanOrEqualTo(6));
    });
  });
}
