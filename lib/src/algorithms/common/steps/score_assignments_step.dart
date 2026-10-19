import '../../data_models/interfaces/algorithm_step.dart';
import '../../data_models/interfaces/assignment_scorer.dart';
import '../../data_models/pipeline_state.dart';

/// Gives every candidate its initial score against the state the run starts
/// from (existing assignments only).
///
/// The scorer is pure, so this step has no side effects and the result does
/// not depend on the order candidates are visited in. Scores are recomputed
/// lazily against the live state during selection.
class ScoreAssignmentsStep extends AlgorithmStep {
  final AssignmentScorer scorer;

  ScoreAssignmentsStep(this.scorer);

  @override
  String get stepName => 'Score Assignments (${scorer.name})';

  @override
  StepOutcome execute(PipelineState state) {
    for (final candidate in state.potentialAssignments) {
      candidate.score = scorer.score(candidate, state.context, state.ledger);
    }
    return StepOutcome(
      summary:
          'Scored ${state.potentialAssignments.length} assignments '
          'with the ${scorer.name} scorer.',
      details: {
        'count': state.potentialAssignments.length,
        'scorer': scorer.name,
      },
    );
  }
}
