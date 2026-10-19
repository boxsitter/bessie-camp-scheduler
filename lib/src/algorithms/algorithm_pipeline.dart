import 'data_models/assignment_context.dart';
import 'data_models/assignment_ledger.dart';
import 'data_models/assignment_result.dart';
import 'data_models/interfaces/algorithm_step.dart';
import 'data_models/pipeline_state.dart';
import 'evaluation/step_report.dart';

/// Runs a list of [AlgorithmStep]s over a [PipelineState] and assembles the
/// immutable [AssignmentResult].
///
/// The pipeline owns timing: it measures each step and attaches the duration
/// to the step's report, so steps only describe what they did.
class AlgorithmPipeline {
  final List<AlgorithmStep> steps;

  AlgorithmPipeline(this.steps);

  AssignmentResult run(AssignmentContext context) {
    final state = PipelineState(
      context: context,
      ledger: AssignmentLedger(context),
    );
    final reports = <StepReport>[];
    final stopwatch = Stopwatch();

    for (final step in steps) {
      stopwatch
        ..reset()
        ..start();
      final outcome = step.execute(state);
      stopwatch.stop();

      reports.add(
        StepReport(
          stepName: step.stepName,
          summary: outcome.summary,
          details: outcome.details,
          duration: stopwatch.elapsed,
        ),
      );
    }

    return AssignmentResult(
      newPlacements: state.ledger.newPlacements,
      satisfaction: state.satisfaction,
      stalemates: state.stalemates.entries,
      evaluationReports: state.evaluationReports,
      stepReports: reports,
    );
  }
}
