import 'dart:math';

import '../../data_models/interfaces/algorithm_step.dart';
import '../../data_models/pipeline_state.dart';
import '../../evaluation/step_report.dart';

/// The third step in the pipeline, responsible for sorting assignments.
///
/// This step sorts the `potentialAssignments` list in place, based on the
/// score calculated in the previous step. The sort is in descending order
/// (highest score first).
class SortAssignmentsStep extends AlgorithmStep {
  final Random _random;

  /// Creates a sorting step. An optional [Random] instance can be provided
  /// for deterministic testing.
  SortAssignmentsStep({Random? random}) : _random = random ?? Random();

  @override
  String get stepName => 'Sort Assignments';

  @override
  StepReport execute(PipelineState state) {
    // Sort the list of potential assignments.
    state.potentialAssignments.sort((a, b) {
      // Compare b to a to get descending order (highest score first).
      final scoreComparison = b.score.compareTo(a.score);

      // If scores are identical, don't just rely on the original list order.
      // Randomly place one before the other to break ties fairly.
      if (scoreComparison == 0) {
        return _random.nextBool() ? 1 : -1;
      }
      return scoreComparison;
    });

    return StepReport(
      stepName: stepName,
      summary: 'Sorted ${state.potentialAssignments.length} assignments by score.',
      details: {'count': state.potentialAssignments.length}, duration: Duration.zero,
    );
  }
}