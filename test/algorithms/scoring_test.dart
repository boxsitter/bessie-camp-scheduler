import 'dart:math';

import 'package:bessie/src/algorithms/assignment_engine.dart';
import 'package:bessie/src/algorithms/common/scoring/scoring_terms.dart';
import 'package:bessie/src/algorithms/common/steps/generate_potential_assignments_step.dart';
import 'package:bessie/src/algorithms/data_models/assignment_ledger.dart';
import 'package:bessie/src/algorithms/data_models/interfaces/assignment_scorer.dart';
import 'package:bessie/src/algorithms/diplomatic_algorithm/diplomatic_scorer.dart';
import 'package:bessie/src/algorithms/greedy_scoring_algorithm/greedy_scorer.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/candidates.dart';
import 'support/random_scenario.dart';
import 'support/scenario_builder.dart';

const diplomatic = DiplomaticScorer();
const greedy = GreedyScorer();

/// mon (3 periods) and tue (2 periods), swim + art offered everywhere.
/// amy (12) requests swim; bob (12) has no preferences.
AssignmentContext scenario() => ScenarioBuilder()
    .day('mon', periods: 3)
    .day('tue', periods: 2)
    .activity('swim')
    .activity('art')
    .offerEverywhere('swim')
    .offerEverywhere('art')
    .participant('amy', age: 12, requests: ['swim'])
    .participant('bob', age: 12)
    .build();

double scoreOf(AssignmentScorer scorer, AssignmentContext context, AssignmentLedger ledger,
    String participant, String activity, String period) {
  return scorer.score(candidateOf(context, participant, activity, period), context, ledger);
}

void main() {
  group('DiplomaticScorer tiers', () {
    test('an unreceived request is worth 1000, a novel activity 500', () {
      final context = scenario();
      final ledger = AssignmentLedger(context);

      expect(scoreOf(diplomatic, context, ledger, 'amy', 'swim', 'mon1'), 1000.0);
      expect(scoreOf(diplomatic, context, ledger, 'amy', 'art', 'mon1'), 500.0);
      expect(scoreOf(diplomatic, context, ledger, 'bob', 'swim', 'mon1'), 500.0);
    });

    test('a repeat is worth 10 (plus penalties) once the activity is held', () {
      final context = scenario();
      final ledger = AssignmentLedger(context);
      ledger.place(candidateOf(context, 'amy', 'swim', 'mon1'));

      // Another day: no same-day penalty, and the request is no longer "unreceived".
      expect(scoreOf(diplomatic, context, ledger, 'amy', 'swim', 'tue1'), 10.0);
      // Other activities are unaffected.
      expect(scoreOf(diplomatic, context, ledger, 'amy', 'art', 'tue1'), 500.0);
    });

    test('existing assignments count as already received', () {
      final context = ScenarioBuilder()
          .day('mon', periods: 1)
          .day('tue', periods: 1)
          .activity('swim')
          .activity('art')
          .offerEverywhere('swim')
          .offerEverywhere('art')
          .participant('amy', requests: ['swim'])
          .existing('amy', ['swim@mon1'])
          .build();
      final ledger = AssignmentLedger(context);

      expect(scoreOf(diplomatic, context, ledger, 'amy', 'swim', 'tue1'), 10.0);
      expect(scoreOf(diplomatic, context, ledger, 'amy', 'art', 'tue1'), 500.0);
    });

    test('every period of the same (participant, activity) gets the same tier', () {
      // The original scorer marked state while scoring, so only the first
      // candidate got the request tier and the others were scored as repeats.
      final context = scenario();
      final ledger = AssignmentLedger(context);

      for (final period in ['mon1', 'mon2', 'mon3', 'tue1', 'tue2']) {
        expect(scoreOf(diplomatic, context, ledger, 'amy', 'swim', period), 1000.0,
            reason: 'swim in $period');
        expect(scoreOf(diplomatic, context, ledger, 'amy', 'art', period), 500.0,
            reason: 'art in $period');
      }
    });

    test('keeps its constants, with the age bonus effectively disabled', () {
      expect(DiplomaticScorer.unfulfilledRequestScore, 1000.0);
      expect(DiplomaticScorer.novelActivityScore, 500.0);
      expect(DiplomaticScorer.repeatedActivityScore, 10.0);
      expect(DiplomaticScorer.baseRepetitionPenalty, -50.0);
      expect(DiplomaticScorer.repetitionPenaltyDecayFactor, 0.6);
      expect(DiplomaticScorer.youngerParticipantMaxBonus, 0.0);

      for (final age in [5, 8, 10, 12, 13, 17]) {
        final context = ScenarioBuilder()
            .day('mon', periods: 1)
            .activity('art')
            .offerEverywhere('art')
            .participant('kid', age: age)
            .build();
        expect(scoreOf(diplomatic, context, AssignmentLedger(context), 'kid', 'art', 'mon1'),
            500.0,
            reason: 'age $age');
      }
    });
  });

  group('scoring is pure', () {
    test('scoring never changes the ledger, whatever the order or repetition', () {
      final context = RandomScenario.generate(7);
      final state = stateFor(context);
      GeneratePotentialAssignmentsStep().execute(state);
      final candidates = state.potentialAssignments;
      expect(candidates, isNotEmpty);

      for (final scorer in [diplomatic, greedy]) {
        final forward = [for (final c in candidates) scorer.score(c, context, state.ledger)];
        final backward = [
          for (final c in candidates.reversed) scorer.score(c, context, state.ledger),
        ].reversed.toList();
        final again = [for (final c in candidates) scorer.score(c, context, state.ledger)];

        expect(backward, forward, reason: '${scorer.name}: order must not matter');
        expect(again, forward, reason: '${scorer.name}: repeating must not matter');
      }
      expect(state.ledger.newPlacements, isEmpty);
    });
  });

  group('same-day repetition penalty', () {
    AssignmentContext fiveInARow() => ScenarioBuilder()
        .day('mon', periods: 5)
        .day('tue', periods: 1)
        .activity('swim')
        .activity('canoe', doubleSchedule: true)
        .offerEverywhere('swim')
        .offerEverywhere('canoe')
        .participant('amy')
        .build();

    double penalty(AssignmentContext context, AssignmentLedger ledger, String period,
        {String activity = 'swim', String? linked}) {
      return ScoringTerms.sameDayRepetitionPenalty(
        candidateOf(context, 'amy', activity, period, linkedPeriodId: linked),
        context,
        ledger,
      );
    }

    test('is -50 * 0.6^distance, distance = periods strictly between', () {
      final context = fiveInARow();
      final ledger = AssignmentLedger(context)
        ..place(candidateOf(context, 'amy', 'swim', 'mon1'));

      expect(penalty(context, ledger, 'mon2'), closeTo(-50.0, 1e-9)); // distance 0
      expect(penalty(context, ledger, 'mon3'), closeTo(-30.0, 1e-9)); // distance 1
      expect(penalty(context, ledger, 'mon4'), closeTo(-18.0, 1e-9)); // distance 2
      expect(penalty(context, ledger, 'mon5'), closeTo(-10.8, 1e-9)); // distance 3
    });

    test('does not apply on another day, to another activity, or without holdings', () {
      final context = fiveInARow();
      final empty = AssignmentLedger(context);
      expect(penalty(context, empty, 'mon3'), 0.0);

      final ledger = AssignmentLedger(context)
        ..place(candidateOf(context, 'amy', 'swim', 'mon5'));
      expect(penalty(context, ledger, 'tue1'), 0.0); // adjacent in time, other day
      expect(penalty(context, ledger, 'mon4', activity: 'canoe', linked: 'mon5'), 0.0);
    });

    test('adds up one term per other assignment of the activity that day', () {
      final context = fiveInARow();
      final ledger = AssignmentLedger(context)
        ..place(candidateOf(context, 'amy', 'swim', 'mon1'))
        ..place(candidateOf(context, 'amy', 'swim', 'mon5'));

      expect(penalty(context, ledger, 'mon3'), closeTo(-60.0, 1e-9));
    });

    test('counts existing assignments too', () {
      final context = ScenarioBuilder()
          .day('mon', periods: 3)
          .activity('swim')
          .offerEverywhere('swim')
          .participant('amy')
          .existing('amy', ['swim@mon1'])
          .build();
      expect(penalty(context, AssignmentLedger(context), 'mon3'), closeTo(-30.0, 1e-9));
    });

    test('measures a double block from its nearest period', () {
      final context = fiveInARow();
      final ledger = AssignmentLedger(context)
        ..place(candidateOf(context, 'amy', 'canoe', 'mon1', linkedPeriodId: 'mon2'));

      // Held: mon1+mon2. A block at mon4+mon5 is nearest to mon2 (distance 1).
      expect(penalty(context, ledger, 'mon4', activity: 'canoe', linked: 'mon5'),
          closeTo(-50 * 0.6 - 50 * 0.6 * 0.6, 1e-9)); // vs mon2: -30, vs mon1: -18
      // A block at mon3+mon4 touches mon2 (distance 0) and is 1 from mon1.
      expect(penalty(context, ledger, 'mon3', activity: 'canoe', linked: 'mon4'),
          closeTo(-50.0 - 30.0, 1e-9));
    });

    test('measures a double block from its nearest period when the held periods come after it',
        () {
      // Held: mon4+mon5. Here the block's SECOND period is the nearer one, so
      // measuring from the first period only would give a smaller penalty.
      final context = fiveInARow();
      final ledger = AssignmentLedger(context)
        ..place(candidateOf(context, 'amy', 'canoe', 'mon4', linkedPeriodId: 'mon5'));

      // Block mon1+mon2: vs mon4 the nearest is mon2 (distance 1, -30); vs mon5
      // it is mon2 too (distance 2, -18).
      expect(penalty(context, ledger, 'mon1', activity: 'canoe', linked: 'mon2'),
          closeTo(-30.0 - 18.0, 1e-9));
      // Block mon2+mon3 touches mon4 (distance 0, -50); vs mon5 distance 1 (-30).
      expect(penalty(context, ledger, 'mon2', activity: 'canoe', linked: 'mon3'),
          closeTo(-50.0 - 30.0, 1e-9));
    });
  });

  group('GreedyScorer', () {
    test('uses the preference tiers: request +100, neutral +10, veto -1000', () {
      final context = ScenarioBuilder()
          .day('mon', periods: 1)
          .activity('swim')
          .activity('art')
          .activity('chess')
          .offerEverywhere('swim')
          .offerEverywhere('art')
          .offerEverywhere('chess')
          .participant('amy', age: 14, requests: ['swim'], vetoes: ['chess'])
          .build();
      final ledger = AssignmentLedger(context);

      expect(scoreOf(greedy, context, ledger, 'amy', 'swim', 'mon1'), 100.0);
      expect(scoreOf(greedy, context, ledger, 'amy', 'art', 'mon1'), 10.0);
      expect(scoreOf(greedy, context, ledger, 'amy', 'chess', 'mon1'), -1000.0);
    });

    test('maps every numeric preference to its documented tier', () {
      final expected = {
        1.0: 100.0, 0.95: 100.0, 0.9: 100.0,
        0.89: 50.0, 0.7: 50.0,
        0.69: 10.0, 0.5: 10.0, 0.3: 10.0,
        0.29: -20.0, 0.1: -20.0,
        0.09: -1000.0, 0.0: -1000.0,
      };
      expected.forEach((preference, bonus) {
        expect(GreedyScorer.preferenceBonus(preference), bonus, reason: 'preference $preference');
      });
    });

    test('adds an age bonus: 20 up to age 8, falling linearly to 0 at 13', () {
      final bonus = {6: 20.0, 8: 20.0, 9: 16.0, 10: 12.0, 11: 8.0, 12: 4.0, 13: 0.0, 17: 0.0};
      bonus.forEach((age, expectedBonus) {
        final context = ScenarioBuilder()
            .day('mon', periods: 1)
            .activity('art')
            .offerEverywhere('art')
            .participant('kid', age: age)
            .build();
        expect(scoreOf(greedy, context, AssignmentLedger(context), 'kid', 'art', 'mon1'),
            closeTo(10.0 + expectedBonus, 1e-9),
            reason: 'age $age');
      });
    });

    test('subtracts the same repetition penalty as the diplomatic scorer', () {
      final context = ScenarioBuilder()
          .day('mon', periods: 3)
          .activity('swim')
          .offerEverywhere('swim')
          .participant('amy', age: 14, requests: ['swim'])
          .build();
      final ledger = AssignmentLedger(context)
        ..place(candidateOf(context, 'amy', 'swim', 'mon1'));

      // No novelty tier: the request is still worth +100, minus 50 * 0.6.
      expect(scoreOf(greedy, context, ledger, 'amy', 'swim', 'mon3'), closeTo(70.0, 1e-9));
    });
  });

  group('ScoringTerms.ageBonus', () {
    test('is flat below minAge, linear in between and zero from maxAge', () {
      double bonus(int age) => ScoringTerms.ageBonus(age, maxBonus: 20.0);
      expect(bonus(0), 20.0);
      expect(bonus(8), 20.0);
      expect(bonus(10), closeTo(12.0, 1e-9));
      expect(bonus(12), closeTo(4.0, 1e-9));
      expect(bonus(13), 0.0);
      expect(bonus(40), 0.0);
      expect(ScoringTerms.ageBonus(10, maxBonus: 0.0), 0.0);
    });
  });

  group('the scorer contract: scores never rise as assignments are made', () {
    for (final scorer in [diplomatic, greedy]) {
      test('${scorer.name}: 60 random scenarios, random placements', () {
        for (var seed = 0; seed < 60; seed++) {
          final context = RandomScenario.generate(seed);
          final state = stateFor(context);
          GeneratePotentialAssignmentsStep().execute(state);
          final candidates = state.potentialAssignments;
          final rnd = Random(seed);
          final previous = [for (final c in candidates) scorer.score(c, context, state.ledger)];

          for (var round = 0; round < 25; round++) {
            final free = [for (final c in candidates) if (state.ledger.isFree(c)) c];
            if (free.isEmpty) break;
            state.ledger.place(free[rnd.nextInt(free.length)]);

            for (var i = 0; i < candidates.length; i++) {
              final fresh = scorer.score(candidates[i], context, state.ledger);
              expect(fresh, lessThanOrEqualTo(previous[i] + 1e-9),
                  reason: 'seed $seed round $round: ${candidates[i]}');
              previous[i] = fresh;
            }
          }
        }
      });
    }
  });
}
