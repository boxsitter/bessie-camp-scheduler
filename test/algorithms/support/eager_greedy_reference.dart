import 'dart:math';

import 'package:bessie/src/algorithms/assignment_engine.dart';
import 'package:bessie/src/algorithms/common/constraints/constraint_checks.dart';
import 'package:bessie/src/algorithms/common/constraints/standard_constraints.dart';
import 'package:bessie/src/algorithms/common/steps/generate_potential_assignments_step.dart';
import 'package:bessie/src/algorithms/common/steps/score_assignments_step.dart';
import 'package:bessie/src/algorithms/common/steps/sort_assignments_step.dart';
import 'package:bessie/src/algorithms/data_models/assignment_ledger.dart';
import 'package:bessie/src/algorithms/data_models/interfaces/assignment_scorer.dart';
import 'package:bessie/src/algorithms/data_models/pipeline_state.dart';
import 'package:bessie/src/algorithms/data_models/potential_assignment.dart';

/// The textbook, obviously-correct version of the selection loop, used as an
/// oracle for the lazy-greedy implementation: every round it re-scores EVERY
/// remaining candidate against the current state, takes the best one by the
/// priority order and either accepts it or drops it for good.
///
/// It reuses the production generate / score / sort steps so that candidates
/// and random tiebreak keys are identical; only the selection loop differs.
/// O(rounds * candidates): for small scenarios only.
List<NewPlacement> eagerGreedyPlacements(
  AssignmentContext context,
  AssignmentScorer scorer,
  Random random,
) {
  final state = PipelineState(context: context, ledger: AssignmentLedger(context));
  GeneratePotentialAssignmentsStep().execute(state);
  ScoreAssignmentsStep(scorer).execute(state);
  SortAssignmentsStep(random: random).execute(state);

  final constraints = standardConstraints();
  final remaining = [...state.potentialAssignments];
  final ledger = state.ledger;

  while (true) {
    remaining.removeWhere((c) => !ledger.isFree(c));
    if (remaining.isEmpty) break;

    for (final candidate in remaining) {
      candidate.score = scorer.score(candidate, context, ledger);
    }
    PotentialAssignment best = remaining.first;
    for (final candidate in remaining) {
      if (PotentialAssignment.byPriority(candidate, best) < 0) best = candidate;
    }
    remaining.remove(best);

    if (constraints.firstViolation(best, context, ledger) != null) continue;
    ledger.place(best);
  }
  return ledger.newPlacements;
}
