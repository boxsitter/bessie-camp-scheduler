import '../../data_models/assignment_context.dart';
import '../../data_models/assignment_result.dart';
import '../../data_models/interfaces/Constraint.dart';
import '../../data_models/potential_assignment.dart';

/// A constraint that checks if an activity has exceeded its capacity.
class CapacityConstraint implements Constraint {
  @override
  String get violationMessage => 'Activity is at full capacity.';

  @override
  bool isViolated(PotentialAssignment assignment, AssignmentContext context, AssignmentResult result) {
    final capacity = assignment.activity.capacity;

    // Count how many participants are already assigned to this specific scheduled activity instance.
    final currentEnrollment = result.successfulAssignments
        .where((a) => a.scheduledActivity.id == assignment.scheduledActivity.id)
        .length;

    return currentEnrollment >= capacity;
  }
}