import '../assignment_context.dart';
import '../assignment_result.dart';
import '../potential_assignment.dart';

/// Defines the contract for a constraint that an assignment must satisfy.
///
/// Constraints are hard rules that cannot be broken.
abstract class Constraint {
  /// A user-friendly message describing why the constraint would be violated.
  String get violationMessage;

  /// Returns `true` if the proposed [assignment] violates this constraint.
  ///
  /// The check can use the initial [context] and the live [result] of the
  /// current algorithm run.
  bool isViolated(PotentialAssignment assignment, AssignmentContext context, AssignmentResult result);
}
