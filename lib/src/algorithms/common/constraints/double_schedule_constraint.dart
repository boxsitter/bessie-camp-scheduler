import '../../data_models/assignment_context.dart';
import '../../data_models/assignment_ledger.dart';
import '../../data_models/interfaces/constraint.dart';
import '../../data_models/potential_assignment.dart';

/// A double-schedule activity must be placed as a well-formed two-period block:
/// the second period is the NEXT chronological period, it is on the same day
/// and it offers the same activity.
///
/// Non-double activities are never affected. The candidate generator only
/// emits well-formed blocks; this constraint is the independent safety net
/// (and the one that keeps the `randomize` fallback honest).
class DoubleScheduleConstraint implements Constraint {
  @override
  String get violationMessage => 'Cannot fulfill double-schedule activity. The subsequent period is unavailable or unscheduled.';

  @override
  bool isViolated(PotentialAssignment assignment, AssignmentContext context, AssignmentLedger ledger) {
    if (!assignment.activity.doubleSchedule) return false;

    // A double activity placed as a single period is malformed.
    final linkedPeriod = assignment.linkedPeriod;
    final linkedScheduled = assignment.linkedScheduledActivity;
    if (linkedPeriod == null || linkedScheduled == null) return true;

    final nextPeriod = context.nextPeriod(assignment.period.id);

    // The block must continue into the next chronological period...
    if (nextPeriod == null || nextPeriod.id != linkedPeriod.id) return true;

    // ...on the same day...
    if (!context.isSameDay(assignment.period, nextPeriod)) return true;

    // ...where the same activity is offered.
    final expected = context.scheduledActivityOf(assignment.activity.id, nextPeriod.id);
    return expected == null || expected.id != linkedScheduled.id;
  }
}
