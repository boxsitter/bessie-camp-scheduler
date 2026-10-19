import 'dart:math';

import '../../data_models/enums.dart';
import '../../data_models/interfaces/algorithm_step.dart';
import '../../data_models/interfaces/assignment_scorer.dart';
import '../constraints/standard_constraints.dart';
import 'generate_evaluation_report.dart';
import 'generate_potential_assignments_step.dart';
import 'process_assignments_step.dart';
import 'resolve_stalemates_step.dart';
import 'score_assignments_step.dart';
import 'sort_assignments_step.dart';

/// The pipeline shared by every strategy. Strategies differ only in the
/// [scorer] they plug in:
///
/// generate candidates -> score -> sort -> lazy-greedy selection ->
/// resolve stalemates -> evaluate.
///
/// The same [random] drives the tiebreak keys and the `randomize` fallback, so
/// a seeded one makes the whole run reproducible.
List<AlgorithmStep> buildStandardSteps({
  required AssignmentScorer scorer,
  required StalemateStrategy stalemateStrategy,
  required Random random,
}) {
  return [
    GeneratePotentialAssignmentsStep(),
    ScoreAssignmentsStep(scorer),
    SortAssignmentsStep(random: random),
    ProcessAssignmentsStep(constraints: standardConstraints(), scorer: scorer),
    ResolveStalematesStep(
      strategy: stalemateStrategy,
      constraints: standardConstraints(),
      relaxedConstraints: essentialConstraints(),
      random: random,
    ),
    GenerateEvaluationReportStep(),
  ];
}
