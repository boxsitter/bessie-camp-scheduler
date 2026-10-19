import 'dart:math';

import 'package:bessie/src/algorithms/algorithm_pipeline.dart';
import 'package:bessie/src/algorithms/assignment_engine.dart';
import 'package:bessie/src/algorithms/data_models/interfaces/algorithm_step.dart';
import 'package:bessie/src/algorithms/data_models/pipeline_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/random_scenario.dart';
import 'support/scenario_builder.dart';

/// A step that burns a known amount of wall-clock time and reports no duration
/// of its own: the pipeline must measure it.
class _SlowStep extends AlgorithmStep {
  @override
  String get stepName => 'Slow Step';

  @override
  StepOutcome execute(PipelineState state) {
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsedMilliseconds < 30) {}
    return const StepOutcome(summary: 'took a while', details: {'answer': 42});
  }
}

class _QuickStep extends AlgorithmStep {
  final List<String> log;
  _QuickStep(this.log);

  @override
  String get stepName => 'Quick Step';

  @override
  StepOutcome execute(PipelineState state) {
    log.add('quick saw ${state.context.participants.length} participants');
    return const StepOutcome(summary: 'done');
  }
}

class _ExplodingStep extends AlgorithmStep {
  @override
  String get stepName => 'Exploding Step';

  @override
  StepOutcome execute(PipelineState state) => throw StateError('boom');
}

void main() {
  group('AlgorithmPipeline', () {
    final context =
        ScenarioBuilder().day('mon', periods: 1).participant('a').build();

    test('measures each step and attaches the duration to its report', () {
      final result = AlgorithmPipeline([
        _SlowStep(),
        _QuickStep([]),
      ]).run(context);

      final slow = result.stepReports[0];
      expect(slow.stepName, 'Slow Step');
      expect(slow.summary, 'took a while');
      expect(slow.details, {'answer': 42});
      expect(
        slow.duration,
        greaterThanOrEqualTo(const Duration(milliseconds: 25)),
      );

      final quick = result.stepReports[1];
      expect(quick.stepName, 'Quick Step');
      expect(quick.duration, lessThan(slow.duration));
    });

    test('runs the steps in order over one shared state', () {
      final log = <String>[];
      AlgorithmPipeline([_QuickStep(log), _QuickStep(log)]).run(context);
      expect(log, ['quick saw 1 participants', 'quick saw 1 participants']);
    });

    test('with no steps it returns an empty result', () {
      final result = AlgorithmPipeline([]).run(context);
      expect(result.newPlacements, isEmpty);
      expect(result.stalemates, isEmpty);
      expect(result.stepReports, isEmpty);
    });

    test('lets a failing step propagate', () {
      expect(
        () => AlgorithmPipeline([_ExplodingStep()]).run(context),
        throwsStateError,
      );
    });
  });

  group('engine step reports', () {
    test('one timed report per step, in pipeline order', () {
      final context = RandomScenario.generate(11);
      final result = AssignmentEngine.run(context, random: Random(1));

      expect(result.stepReports.map((r) => r.stepName).toList(), [
        'Generate Potential Assignments',
        'Score Assignments (diplomatic)',
        'Sort Assignments',
        'Process & Finalize Assignments',
        'Resolve Stalemates',
        'Generate Evaluation Report',
      ]);
      for (final report in result.stepReports) {
        expect(report.summary, isNotEmpty);
        expect(report.duration, greaterThanOrEqualTo(Duration.zero));
        expect(report.toString(), startsWith('[${report.stepName}]'));
        expect(report.toString(), contains(report.summary));
      }
    });

    test('report details describe what each step did', () {
      final context =
          ScenarioBuilder()
              .day('mon', periods: 1)
              .activity('swim', capacity: 1)
              .offer('swim', ['mon1'])
              .participant('a')
              .participant('b')
              .build();
      final reports = {
        for (final r
            in AssignmentEngine.run(context, random: Random(0)).stepReports)
          r.stepName: r.details,
      };

      expect(reports['Generate Potential Assignments']!['count'], 2);
      expect(reports['Score Assignments (diplomatic)']!['count'], 2);
      expect(reports['Process & Finalize Assignments']!['accepted'], 1);
      expect(
        reports['Process & Finalize Assignments']!['droppedByConstraint'],
        1,
      );
      expect(reports['Resolve Stalemates']!['stalemateCount'], 1);
      expect(
        reports['Resolve Stalemates']!['stalemateStrategy'],
        'leaveUnassigned',
      );
      expect(reports['Generate Evaluation Report']!['count'], 2);
    });
  });

  group('AssignmentResult', () {
    test('is immutable', () {
      final context =
          ScenarioBuilder()
              .day('mon', periods: 1)
              .activity('swim', capacity: 1)
              .offer('swim', ['mon1'])
              .participant('a')
              .participant('b')
              .build();
      final result = AssignmentEngine.run(context, random: Random(0));

      expect(() => result.newPlacements.clear(), throwsUnsupportedError);
      expect(() => result.stalemates.clear(), throwsUnsupportedError);
      expect(() => result.stepReports.clear(), throwsUnsupportedError);
      expect(() => result.evaluationReports.clear(), throwsUnsupportedError);
      expect(() => result.satisfaction['x'] = 1.0, throwsUnsupportedError);
    });

    test('can be constructed by callers, for fakes in their own tests', () {
      final result = AssignmentResult(
        newPlacements: const [
          NewPlacement(participantId: 'a', scheduledActivityId: 's1'),
        ],
        stalemates: const [
          Stalemate(participantId: 'b', periodId: 'p', reason: 'full'),
        ],
      );
      expect(result.newPlacements.single.scheduledActivityId, 's1');
      expect(result.hasStalemate('b'), isTrue);
      expect(result.hasStalemate('a'), isFalse);
      expect(result.satisfaction, isEmpty);
      expect(result.evaluationReports, isEmpty);
      expect(result.stepReports, isEmpty);
    });

    test(
      'NewPlacement and Stalemate print readably and NewPlacement has value equality',
      () {
        const placement = NewPlacement(
          participantId: 'a',
          scheduledActivityId: 'swim@mon1',
        );
        expect(
          placement,
          const NewPlacement(
            participantId: 'a',
            scheduledActivityId: 'swim@mon1',
          ),
        );
        expect(
          placement.hashCode,
          const NewPlacement(
            participantId: 'a',
            scheduledActivityId: 'swim@mon1',
          ).hashCode,
        );
        expect(placement.toString(), 'a -> swim@mon1');
        expect(
          const Stalemate(
            participantId: 'a',
            periodId: 'p',
            reason: 'because',
          ).toString(),
          'a @ p: because',
        );
      },
    );

    test(
      'newPlacements holds ONLY what the run added, never existing assignments',
      () {
        final context =
            ScenarioBuilder()
                .day('mon', periods: 3)
                .activity('swim')
                .activity('art')
                .activity('lifeguard', assignable: false)
                .offerEverywhere('swim')
                .offer('art', ['mon3'])
                .offer('lifeguard', ['mon1'])
                .participant('a')
                .existing('a', ['lifeguard@mon1', 'art@mon3'])
                .build();
        final result = AssignmentEngine.run(context, random: Random(0));

        expect(result.placedFor('a'), ['swim@mon2']);
      },
    );
  });
}
