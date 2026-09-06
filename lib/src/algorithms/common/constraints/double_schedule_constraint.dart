import 'package:intl/intl.dart';

import '../../data_models/assignment_context.dart';
import '../../data_models/assignment_result.dart';
import '../../data_models/interfaces/Constraint.dart';
import '../../data_models/potential_assignment.dart';

/// A constraint to handle the "double schedule" rule.
class DoubleScheduleConstraint implements Constraint {
  @override
  String get violationMessage =>
      'Cannot fulfill double-schedule activity. The subsequent period is unavailable or unscheduled.';

  @override
  bool isViolated(PotentialAssignment assignment, AssignmentContext context, AssignmentResult result) {
    if (!assignment.activity.doubleSchedule) return false;

    final nextPeriod = context.getNextPeriod(assignment.period.id);

    // Violation if there's no next period at all.
    if (nextPeriod == null) return true;

    // Violation if the next period is on a different day.
    final formatter = DateFormat('yyyy-MM-dd');
    if (formatter.format(assignment.period.start) !=
        formatter.format(nextPeriod.start)) {
      return true;
    }

    // Violation if the same activity is not scheduled in the next period.
    final linkedScheduledActivity =
    context.getScheduledActivityInPeriod(assignment.activity.id, nextPeriod.id);
    if (linkedScheduledActivity == null) {
      return true;
    }

    // All checks passed, no violation.
    return false;
  }
}