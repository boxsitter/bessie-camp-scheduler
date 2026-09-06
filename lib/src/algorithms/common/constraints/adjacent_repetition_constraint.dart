import 'package:intl/intl.dart';

import '../../data_models/analogs/algo_period.dart';
import '../../data_models/assignment_context.dart';
import '../../data_models/assignment_result.dart';
import '../../data_models/interfaces/Constraint.dart';
import '../../data_models/potential_assignment.dart';

/// A constraint that prevents a participant from being assigned to the same
/// activity in an adjacent period on the same day, unless it's a double schedule.
class AdjacentRepetitionConstraint implements Constraint {
  @override
  String get violationMessage =>
      'Participant is already assigned to this activity in an adjacent period.';

  @override
  bool isViolated(PotentialAssignment assignment, AssignmentContext context, AssignmentResult result) {
    if (assignment.activity.doubleSchedule) return false;

    final participantId = assignment.participant.id;
    final activityId = assignment.activity.id;

    // Combine existing and new assignments for a full view of the schedule.
    final allAssignments = [
      ...context.getAssignmentsForParticipant(participantId),
      ...result.getAssignmentsForParticipant(participantId)
    ];

    for (final existingAssignment in allAssignments) {
      if (existingAssignment.activity.id == activityId) {
        if (_arePeriodsAdjacentOnSameDay(
          assignment.period,
          existingAssignment.period,
          context.weeklyPeriodsSorted,
        )) {
          return true; // Violation found
        }
      }
    }

    return false;
  }

  bool _arePeriodsAdjacentOnSameDay(AlgoPeriod periodA, AlgoPeriod periodB, List<AlgoPeriod> weeklyPeriodsSorted) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final dayA = formatter.format(periodA.start);
    final dayB = formatter.format(periodB.start);

    if (dayA != dayB) return false;

    final indexA = weeklyPeriodsSorted.indexWhere((p) => p.id == periodA.id);
    final indexB = weeklyPeriodsSorted.indexWhere((p) => p.id == periodB.id);

    if (indexA == -1 || indexB == -1) return false;

    return (indexA - indexB).abs() == 1;
  }
}