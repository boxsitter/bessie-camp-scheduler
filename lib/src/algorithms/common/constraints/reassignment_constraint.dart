import '../../data_models/assignment_context.dart';
import '../../data_models/assignment_result.dart';
import '../../data_models/interfaces/Constraint.dart';
import '../../data_models/potential_assignment.dart';

/// A constraint that checks if a participant has been assigned to an activity
/// more times than its reassignment cap allows within the week.
class ReassignmentConstraint implements Constraint {
  @override
  String get violationMessage =>
      'Participant has reached the maximum number of reassignments for this activity.';

  @override
  bool isViolated(PotentialAssignment assignment, AssignmentContext context, AssignmentResult result) {
    final participantId = assignment.participant.id;
    final activityId = assignment.activity.id;
    final maxAssignments = assignment.activity.maxAssignments;

    if (maxAssignments == null) return false; // Null means infinite

    // Get all assignments for this participant (both existing and new)
    final allParticipantAssignments = [
      ...context.getAssignmentsForParticipant(participantId),
      ...result.getAssignmentsForParticipant(participantId),
    ];

    final count = allParticipantAssignments
        .where((a) => a.activity.id == activityId)
        .length;

    // The potential assignment hasn't been added yet, so we check if the current
    // count is already at the maximum.
    return count >= maxAssignments;
  }
}