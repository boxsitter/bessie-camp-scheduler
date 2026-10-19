import '../../data_models/assignment_context.dart';
import '../../data_models/assignment_ledger.dart';
import '../../data_models/interfaces/constraint.dart';
import '../../data_models/potential_assignment.dart';

/// Evaluating a whole set of constraints against one candidate.
extension ConstraintChecks on Iterable<Constraint> {
  /// The violation message of the first constraint [candidate] breaks, or
  /// `null` if it breaks none.
  String? firstViolation(PotentialAssignment candidate, AssignmentContext context, AssignmentLedger ledger) {
    for (final constraint in this) {
      if (constraint.isViolated(candidate, context, ledger)) {
        return constraint.violationMessage;
      }
    }
    return null;
  }

  /// The violation messages of every constraint [candidate] breaks.
  List<String> violations(PotentialAssignment candidate, AssignmentContext context, AssignmentLedger ledger) {
    return [
      for (final constraint in this)
        if (constraint.isViolated(candidate, context, ledger)) constraint.violationMessage,
    ];
  }
}
