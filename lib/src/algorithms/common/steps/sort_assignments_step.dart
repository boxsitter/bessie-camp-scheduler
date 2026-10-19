import 'dart:math';

import '../../data_models/interfaces/algorithm_step.dart';
import '../../data_models/pipeline_state.dart';
import '../../data_models/potential_assignment.dart';

/// Puts the candidates into priority order: highest score first, ties broken
/// by a random key.
///
/// Every candidate receives ONE tiebreak key, drawn once from the injected
/// [Random] in generation order, and the list is then sorted by
/// (score descending, tiebreak ascending, generation sequence ascending). That
/// is a strict total order, so the sort is deterministic for a seeded [Random]
/// and always consistent (unlike a comparator that flips a coin per
/// comparison). Ties are still resolved fairly, because the keys are random.
class SortAssignmentsStep extends AlgorithmStep {
  final Random _random;

  /// Creates a sorting step. Pass a seeded [Random] for reproducible output.
  SortAssignmentsStep({Random? random}) : _random = random ?? Random();

  @override
  String get stepName => 'Sort Assignments';

  @override
  StepOutcome execute(PipelineState state) {
    final candidates = state.potentialAssignments;
    for (final candidate in candidates) {
      candidate.tiebreak = _random.nextDouble();
    }
    candidates.sort(PotentialAssignment.byPriority);

    return StepOutcome(
      summary:
          'Sorted ${candidates.length} assignments by score '
          '(random tiebreak keys).',
      details: {'count': candidates.length},
    );
  }
}
