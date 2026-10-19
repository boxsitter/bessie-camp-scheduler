import '../../data_models/assignment_context.dart';
import '../../data_models/assignment_ledger.dart';
import '../../data_models/interfaces/constraint.dart';
import '../../data_models/potential_assignment.dart';

/// A participant may hold an activity at most `maxAssignments` times in the
/// week.
///
/// A double-schedule block is ONE occurrence, not two. Existing assignments
/// are counted once (the ledger is the only record). O(1).
class ReassignmentConstraint implements Constraint {
  @override
  String get violationMessage =>
      'Participant has reached the maximum number of assignments for this activity.';

  @override
  bool isViolated(
    PotentialAssignment assignment,
    AssignmentContext context,
    AssignmentLedger ledger,
  ) {
    final maxAssignments = assignment.activity.maxAssignments;
    if (maxAssignments == null) return false; // Null means unlimited.

    final count = ledger.occurrences(
      assignment.participant.id,
      assignment.activity.id,
    );
    // The candidate has not been placed yet, so it violates the cap exactly
    // when the participant is already at it.
    return count >= maxAssignments;
  }
}
