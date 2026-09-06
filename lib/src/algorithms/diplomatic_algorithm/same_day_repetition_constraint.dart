import 'package:intl/intl.dart';

import '../data_models/assignment_context.dart';
import '../data_models/assignment_result.dart';
import '../data_models/interfaces/Constraint.dart';
import '../data_models/potential_assignment.dart';

class SameDayRepetitionConstraint implements Constraint {
  @override
  String get violationMessage => 'Participant is already assigned to this activity today.';

  @override
  bool isViolated(PotentialAssignment assignment, AssignmentContext context, AssignmentResult result) {
    final participantId = assignment.participant.id;
    final activityId = assignment.activity.id;

    final allAssignments = [
      ...context.getAssignmentsForParticipant(participantId),
      ...result.getAssignmentsForParticipant(participantId)
    ];

    final assignmentDay = DateFormat('yyyy-MM-dd').format(assignment.period.start);

    return allAssignments.any((existing) =>
    existing.activity.id == activityId &&
        DateFormat('yyyy-MM-dd').format(existing.period.start) == assignmentDay);
  }
}