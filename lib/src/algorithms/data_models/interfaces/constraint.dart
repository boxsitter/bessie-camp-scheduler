import '../assignment_context.dart';
import '../assignment_ledger.dart';
import '../potential_assignment.dart';

/// A hard rule an assignment must satisfy. Constraints are composable: the
/// pipeline simply evaluates a list of them.
///
/// A candidate may be a double-schedule block. Constraints receive the block
/// as a whole and are responsible for every period it occupies (see
/// `PotentialAssignment.scheduledActivities` and `periods`).
///
/// Violations must be **monotone**: once a candidate violates a constraint, it
/// keeps violating it as more assignments are made (capacity never frees up,
/// occurrence counts never shrink). The lazy-greedy selection relies on this to
/// drop a rejected candidate for good.
abstract class Constraint {
  /// A user-friendly message describing why the constraint would be violated.
  String get violationMessage;

  /// Returns `true` if placing [assignment] on top of the current [ledger]
  /// would violate this constraint.
  bool isViolated(PotentialAssignment assignment, AssignmentContext context, AssignmentLedger ledger);
}
