import '../../data_models/assignment_context.dart';
import '../../data_models/assignment_ledger.dart';
import '../../data_models/interfaces/constraint.dart';
import '../../data_models/potential_assignment.dart';

/// Every scheduled instance the assignment occupies must still have a free
/// seat.
///
/// The ledger counts external enrollment, existing assignments and new
/// placements, and a double-schedule block is checked in BOTH of its periods.
/// O(1).
class CapacityConstraint implements Constraint {
  @override
  String get violationMessage => 'Activity is at full capacity.';

  @override
  bool isViolated(
    PotentialAssignment assignment,
    AssignmentContext context,
    AssignmentLedger ledger,
  ) {
    final capacity = assignment.activity.capacity;
    for (final scheduled in assignment.scheduledActivities) {
      if (ledger.seatsTaken(scheduled.id) >= capacity) return true;
    }
    return false;
  }
}
