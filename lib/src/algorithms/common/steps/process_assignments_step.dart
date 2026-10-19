import 'package:collection/collection.dart';

import '../../data_models/interfaces/algorithm_step.dart';
import '../constraints/constraint_checks.dart';
import '../../data_models/interfaces/assignment_scorer.dart';
import '../../data_models/interfaces/constraint.dart';
import '../../data_models/pipeline_state.dart';
import '../../data_models/potential_assignment.dart';

/// The main selection pass: a lazy-greedy loop over a priority queue.
///
/// Candidates sit in a priority queue ordered by (score desc, tiebreak asc,
/// sequence asc). Repeatedly:
///
///  1. pop the best candidate;
///  2. skip it for good if the participant is already busy in any period it
///     occupies;
///  3. recompute its score against the CURRENT ledger;
///  4. if, with that fresh score, it no longer beats the next candidate in
///     the queue, put it back with the fresh score and continue;
///  5. otherwise evaluate every hard constraint, for BOTH halves of a
///     double-schedule block, and either accept it (it is recorded in the
///     ledger) or drop it for good.
///
/// Because scores never rise as assignments are made (see [AssignmentScorer])
/// a stale queue entry is always an upper bound of the true score, so the
/// candidate accepted in step 5 is exactly the one an eager "re-score
/// everything every round" greedy would pick, at a tiny fraction of the work.
/// Constraint violations are monotone too, so a dropped candidate can never
/// become acceptable later.
///
/// Stalemates are NOT handled here; see `ResolveStalematesStep`.
class ProcessAssignmentsStep extends AlgorithmStep {
  final List<Constraint> constraints;
  final AssignmentScorer scorer;

  ProcessAssignmentsStep({required this.constraints, required this.scorer});

  @override
  String get stepName => 'Process & Finalize Assignments';

  @override
  StepOutcome execute(PipelineState state) {
    final context = state.context;
    final ledger = state.ledger;

    final queue = HeapPriorityQueue<PotentialAssignment>(PotentialAssignment.byPriority)
      ..addAll(state.potentialAssignments);

    var accepted = 0;
    var placements = 0;
    var skippedBusy = 0;
    var droppedByConstraint = 0;
    var rescored = 0;

    while (queue.isNotEmpty) {
      final candidate = queue.removeFirst();

      // The participant got something else in the meantime: this candidate is
      // gone for good.
      if (!ledger.isFree(candidate)) {
        skippedBusy++;
        continue;
      }

      final fresh = scorer.score(candidate, context, ledger);
      assert(
        fresh <= candidate.score + 1e-9,
        'A scorer must never raise a score as assignments are made '
        '(${candidate.score} -> $fresh for $candidate).',
      );
      candidate.score = fresh;

      if (queue.isNotEmpty &&
          PotentialAssignment.byPriority(candidate, queue.first) > 0) {
        queue.add(candidate);
        rescored++;
        continue;
      }

      if (constraints.firstViolation(candidate, context, ledger) != null) {
        droppedByConstraint++;
        continue;
      }

      ledger.place(candidate);
      accepted++;
      placements += candidate.isDoubleAssignment ? 2 : 1;
    }

    return StepOutcome(
      summary: 'Accepted $accepted assignments ($placements placements); '
          'dropped $droppedByConstraint on constraints and $skippedBusy '
          'because the participant was already busy.',
      details: {
        'accepted': accepted,
        'placements': placements,
        'droppedByConstraint': droppedByConstraint,
        'skippedBusy': skippedBusy,
        'rescored': rescored,
      },
    );
  }
}
