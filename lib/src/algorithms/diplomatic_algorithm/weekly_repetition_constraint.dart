import '../data_models/assignment_context.dart';
import '../data_models/assignment_result.dart';
import '../data_models/interfaces/Constraint.dart';
import '../data_models/potential_assignment.dart';

class WeeklyRepetitionConstraint implements Constraint {
  @override
  String get violationMessage =>
      'Participant has reached the maximum of 2 assignments for this activity this week.';

  @override
  bool isViolated(PotentialAssignment assignment, AssignmentContext context, AssignmentResult result) {
    final participantId = assignment.participant.id;
    final activityId = assignment.activity.id;

    final allAssignments = [
      ...context.getAssignmentsForParticipant(participantId),
      ...result.getAssignmentsForParticipant(participantId)
    ];

    final count = allAssignments.where((a) => a.activity.id == activityId).length;

    return count >= 2;
  }
}