import '../assignment_context.dart';
import '../assignment_ledger.dart';
import '../potential_assignment.dart';

/// Rates a candidate assignment; this is the only thing that differs between
/// the diplomatic and the greedy strategy.
///
/// Contract, relied upon by the lazy-greedy selection:
///  * **Pure**: the score depends only on the arguments. Scoring never mutates
///    the ledger, the context or the candidate.
///  * **Non-increasing over time**: as assignments are added to the ledger, the
///    score of a given candidate may stay the same or drop, never rise.
abstract class AssignmentScorer {
  /// A short name used in step reports.
  String get name;

  /// Scores [candidate] against the *current* state of [ledger]. Higher is
  /// better.
  double score(
    PotentialAssignment candidate,
    AssignmentContext context,
    AssignmentLedger ledger,
  );
}
