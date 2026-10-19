import 'dart:math';

import 'package:bessie/src/algorithms/assignment_engine.dart';
import 'package:bessie/src/algorithms/data_models/assignment_ledger.dart';
import 'package:bessie/src/algorithms/data_models/stalemate_log.dart';
import 'package:bessie/src/algorithms/evaluation/diplomatic_satisfaction_evaluator.dart';
import 'package:bessie/src/algorithms/evaluation/novelty_evaluator.dart';
import 'package:bessie/src/algorithms/evaluation/satisfaction_calculator.dart';
import 'package:bessie/src/algorithms/evaluation/satisfaction_constants.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/scenario_builder.dart';

final calculator = SatisfactionCalculator();

/// A six-period day with every activity offered in every period, a single
/// participant 'kid' of [age], and [existing] scheduled activity ids.
AssignmentContext weekOf({
  int age = 14,
  List<String> requests = const [],
  List<String> vetoes = const [],
  required List<String> existing,
  DateTime? now,
}) {
  final builder = ScenarioBuilder();
  if (now != null) builder.now = now;
  builder
      .day('mon', periods: 6)
      .activity('art')
      .activity('chess')
      .activity('swim')
      .activity('canoe', doubleSchedule: true)
      .offerEverywhere('art')
      .offerEverywhere('chess')
      .offerEverywhere('swim')
      .offerEverywhere('canoe')
      .participant('kid', age: age, requests: requests, vetoes: vetoes)
      .existing('kid', existing);
  return builder.build();
}

double? satisfactionOf(AssignmentContext context, {StalemateLog? stalemates}) {
  return calculator.calculate(
    participantId: 'kid',
    context: context,
    ledger: AssignmentLedger(context),
    stalemates: stalemates ?? StalemateLog(),
  );
}

void main() {
  group('SatisfactionCalculator: known numbers', () {
    test('request + neutral, age 14: 0.7 * 0.75 + 0.3 * 1.0 = 0.825', () {
      // impacts +0.5 and 0; best possible +1.0, worst -1.0 (multiplier 1.0):
      // preference = (0.5 + 1.0) / 2.0 = 0.75; novelty = 2 unique / 2 = 1.0.
      final context =
          weekOf(requests: ['swim'], existing: ['swim@mon1', 'art@mon2']);
      expect(satisfactionOf(context), closeTo(0.825, 1e-12));
    });

    test('a single vetoed placement at age 6 scores 0 on preference: 0.3', () {
      // impact -0.5 * 2.5 = -1.25 = the worst possible; novelty 1/1.
      final context = weekOf(age: 6, vetoes: ['art'], existing: ['art@mon1']);
      expect(satisfactionOf(context), closeTo(0.3, 1e-12));
    });

    test('age 10 amplifies a veto by 1.9', () {
      // impacts: 0, 0, -0.5 * 1.9 = -0.95; max = 1.5, min = 3 * -0.5 * 1.9 = -2.85;
      // preference = (-0.95 + 2.85) / (1.5 + 2.85) = 1.9 / 4.35; novelty = 3/3.
      final context = weekOf(
        age: 10,
        vetoes: ['swim'],
        existing: ['art@mon1', 'chess@mon2', 'swim@mon3'],
      );
      expect(satisfactionOf(context), closeTo(0.7 * (1.9 / 4.35) + 0.3, 1e-12));
    });

    test('the same activity in every period halves novelty: all requests, age 14 -> 0.8', () {
      // preference = 1.0 (all +0.5), novelty = 1 unique / 3 placements.
      final context = weekOf(
        requests: ['swim'],
        existing: ['swim@mon1', 'swim@mon3', 'swim@mon5'],
      );
      expect(satisfactionOf(context), closeTo(0.7 * 1.0 + 0.3 * (1 / 3), 1e-12));
    });

    test('all neutral and all different, age 14 -> 0.7 * 0.5 + 0.3 * 1.0 = 0.65', () {
      final context = weekOf(existing: ['art@mon1', 'chess@mon2', 'swim@mon3']);
      expect(satisfactionOf(context), closeTo(0.65, 1e-12));
    });

    test('a double block counts once per period: [canoe, canoe, art] -> novelty 2/3', () {
      final context = weekOf(existing: ['canoe@mon1', 'canoe@mon2', 'art@mon3']);
      expect(satisfactionOf(context), closeTo(0.7 * 0.5 + 0.3 * (2 / 3), 1e-12));
    });

    test('is clamped into 0..1', () {
      for (final age in [5, 9, 13]) {
        final value = satisfactionOf(
            weekOf(age: age, vetoes: ['art'], existing: ['art@mon1', 'art@mon3']))!;
        expect(value, inInclusiveRange(0.0, 1.0));
      }
    });

    test('returns null when the participant has any stalemate', () {
      final context = weekOf(existing: ['art@mon1']);
      final log = StalemateLog()
        ..add(const Stalemate(participantId: 'kid', periodId: 'mon2', reason: 'full'));
      expect(satisfactionOf(context, stalemates: log), isNull);
      expect(satisfactionOf(context), isNotNull);
    });

    test('returns null when the participant has no assignments at all', () {
      expect(satisfactionOf(weekOf(existing: [])), isNull);
    });

    test('rejects a participant that is not in the context', () {
      final context = weekOf(existing: ['art@mon1']);
      expect(
        () => calculator.calculate(
          participantId: 'ghost',
          context: context,
          ledger: AssignmentLedger(context),
          stalemates: StalemateLog(),
        ),
        throwsArgumentError,
      );
    });

    test('uses the context clock, never DateTime.now() (regression)', () {
      // Born 1990-01-01; "now" is mid-2000, so the child is 10 (multiplier 1.9).
      // impacts: veto -0.95 and neutral 0; max 1.0, min -1.9.
      // preference = (-0.95 + 1.9) / 2.9; with the wall clock (age 30+, 1.0) it
      // would be 0.25 instead.
      final context = ScenarioBuilder()
          .day('mon', periods: 2)
          .activity('art')
          .activity('chess')
          .offerEverywhere('art')
          .offerEverywhere('chess')
          .participant('kid', vetoes: ['art'])
          .existing('kid', ['art@mon1', 'chess@mon2'])
          .build();
      final old = AssignmentContext(
        participants: [AlgoParticipant(id: 'kid', birthdate: DateTime(1990))],
        preferences: context.preferences,
        periods: context.periods,
        targetPeriodIds: const {},
        activities: context.activities,
        scheduledActivities: context.scheduledActivities,
        existingAssignments: context.existingAssignments,
        now: DateTime(2000, 6, 1),
      );
      final expected = 0.7 * (0.95 / 2.9) + 0.3;
      expect(satisfactionOf(old), closeTo(expected, 1e-12));
      expect(expected, isNot(closeTo(0.7 * 0.25 + 0.3, 1e-3)));
    });
  });

  group('discouragement multiplier', () {
    test('is 2.5 up to age 8, falls linearly and is 1.0 from age 13', () {
      final expected = {
        3: 2.5, 8: 2.5, 9: 2.2, 10: 1.9, 11: 1.6, 12: 1.3, 13: 1.0, 20: 1.0,
      };
      expected.forEach((age, multiplier) {
        expect(
          calculator.calculateDiscouragementMultiplier(
              age: age, settings: SatisfactionConstants.discouragementSettings),
          closeTo(multiplier, 1e-12),
          reason: 'age $age',
        );
      });
    });

    test('keeps the original constants', () {
      expect(SatisfactionConstants.satisfactionWeights[SatisfactionFactor.preference], 0.7);
      expect(SatisfactionConstants.satisfactionWeights[SatisfactionFactor.novelty], 0.3);
      expect(SatisfactionConstants.neutralPreferencePoint, 0.5);
      expect(SatisfactionConstants.discouragementSettings.maxMultiplier, 2.5);
      expect(SatisfactionConstants.discouragementSettings.minAge, 8);
      expect(SatisfactionConstants.discouragementSettings.maxAge, 13);
    });
  });

  group('engine satisfaction', () {
    test('is evaluated over the whole week: existing plus new placements', () {
      // amy holds art@mon1 already; the run adds swim@mon2 (her request).
      // Week = [art, swim]: preference (0.5 + 1) / 2 = 0.75, novelty 1.0.
      final context = ScenarioBuilder()
          .day('mon', periods: 2)
          .activity('art')
          .activity('swim')
          .offer('art', ['mon1'])
          .offer('swim', ['mon2'])
          .participant('amy', age: 14, requests: ['swim'])
          .existing('amy', ['art@mon1'])
          .targets(['mon2'])
          .build();
      final result = AssignmentEngine.run(context, random: Random(0));

      expect(result.placedFor('amy'), ['swim@mon2']);
      expect(result.satisfaction['amy'], closeTo(0.825, 1e-12));
    });

    test('omits participants with a stalemate', () {
      final context = ScenarioBuilder()
          .day('mon', periods: 1)
          .activity('swim', capacity: 1)
          .offer('swim', ['mon1'])
          .participant('lucky')
          .participant('unlucky')
          .build();
      final result = AssignmentEngine.run(context, random: Random(0));

      final placed = result.newPlacements.single.participantId;
      final stuck = placed == 'lucky' ? 'unlucky' : 'lucky';
      expect(result.satisfaction.keys.toList(), [placed]);
      expect(result.satisfaction.containsKey(stuck), isFalse);
      expect(result.hasStalemate(stuck), isTrue);
    });

    test('omits participants with no assignments at all', () {
      // Nothing to fill and nothing held: no stalemate, but nothing to score.
      final context = ScenarioBuilder()
          .day('mon', periods: 1)
          .activity('swim')
          .offer('swim', ['mon1'])
          .participant('idle')
          .targets([])
          .build();
      final result = AssignmentEngine.run(context, random: Random(0));

      expect(result.newPlacements, isEmpty);
      expect(result.stalemates, isEmpty);
      expect(result.satisfaction, isEmpty);
    });

    test('is identical for identical input, run after run', () {
      // One period per day, so there is no adjacency and nobody gets stuck.
      final context = ScenarioBuilder()
          .day('mon', periods: 1)
          .day('tue', periods: 1)
          .day('wed', periods: 1)
          .activity('art')
          .activity('chess')
          .activity('swim')
          .offerEverywhere('art')
          .offerEverywhere('chess')
          .offerEverywhere('swim')
          .participant('amy', age: 9, requests: ['swim'], vetoes: ['art'])
          .build();
      final a = AssignmentEngine.run(context, random: Random(3));
      final b = AssignmentEngine.run(context, random: Random(3));

      expect(a.stalemates, isEmpty);
      expect(a.satisfaction['amy'], isNotNull);
      expect(a.satisfaction, b.satisfaction);
    });
  });

  group('NoveltyEvaluator', () {
    final evaluator = NoveltyEvaluator();

    double? noveltyOf(List<String> existing) {
      final context = weekOf(existing: existing);
      return evaluator.calculateNoveltyPercentage(
          participantId: 'kid', ledger: AssignmentLedger(context));
    }

    test('is 0.0 for the same activity everywhere and 1.0 when all differ', () {
      expect(noveltyOf(['swim@mon1', 'swim@mon3', 'swim@mon5']), 0.0);
      expect(noveltyOf(['art@mon1', 'chess@mon2', 'swim@mon3']), 1.0);
    });

    test('is (unique - 1) / (placements - 1) in between', () {
      expect(noveltyOf(['art@mon1', 'chess@mon2', 'art@mon3']), closeTo(0.5, 1e-12));
      expect(noveltyOf(['art@mon1', 'chess@mon2', 'swim@mon3', 'art@mon4']),
          closeTo(2 / 3, 1e-12));
    });

    test('is 1.0 for a single placement and null for none', () {
      expect(noveltyOf(['art@mon1']), 1.0);
      expect(noveltyOf([]), isNull);
    });
  });

  group('DiplomaticSatisfactionEvaluator', () {
    final evaluator = DiplomaticSatisfactionEvaluator();

    bool satisfied(AssignmentContext context) => evaluator.isSatisfied(
        participantId: 'kid', context: context, ledger: AssignmentLedger(context));

    test('requires every request and no veto over the whole week', () {
      expect(satisfied(weekOf(requests: ['swim'], existing: ['swim@mon1', 'art@mon2'])), isTrue);
      expect(satisfied(weekOf(requests: ['swim'], existing: ['art@mon2'])), isFalse);
      expect(satisfied(weekOf(vetoes: ['art'], existing: ['art@mon2'])), isFalse);
      expect(
          satisfied(weekOf(
              requests: ['swim'], vetoes: ['art'], existing: ['swim@mon1', 'chess@mon2'])),
          isTrue);
    });

    test('a participant without preferences is trivially satisfied', () {
      expect(satisfied(weekOf(existing: ['art@mon1'])), isTrue);
      expect(satisfied(weekOf(existing: [])), isTrue);
    });
  });

  group('ParticipantEvaluationReport', () {
    test('formats a CSV row and header', () {
      const report = ParticipantEvaluationReport(
          participantId: 'amy', preferencesSatisfied: true, noveltyScore: 0.5);
      expect(report.toCsvRow(), ['amy', 'true', '0.500']);
      expect(
        const ParticipantEvaluationReport(
                participantId: 'bob', preferencesSatisfied: false, noveltyScore: null)
            .toCsvRow(),
        ['bob', 'false', 'N/A'],
      );
      expect(ParticipantEvaluationReport.getCsvHeader(),
          ['Participant ID', 'Preferences Satisfied', 'Novelty Index']);
    });

    test('the engine produces one report per participant, over the whole week', () {
      final context = ScenarioBuilder()
          .day('mon', periods: 2)
          .activity('art')
          .activity('swim')
          .offer('art', ['mon1'])
          .offer('swim', ['mon2'])
          .participant('amy', requests: ['swim'])
          .participant('bob', requests: ['art'], vetoes: ['swim'])
          .existing('amy', ['art@mon1'])
          .existing('bob', ['art@mon1'])
          .targets(['mon2'])
          .build();
      final result = AssignmentEngine.run(context, random: Random(0));
      final reports = {for (final r in result.evaluationReports) r.participantId: r};

      expect(reports.keys, ['amy', 'bob']);
      // amy: existing art + new swim -> request fulfilled, 2 unique of 2.
      expect(reports['amy']!.preferencesSatisfied, isTrue);
      expect(reports['amy']!.noveltyScore, 1.0);
      // bob: art (existing) fulfils his request; swim is vetoed, so mon2 stays
      // empty and his week is just [art].
      expect(reports['bob']!.preferencesSatisfied, isTrue);
      expect(reports['bob']!.noveltyScore, 1.0);
      expect(result.stalemateKeys, ['bob@mon2']);
    });
  });
}
