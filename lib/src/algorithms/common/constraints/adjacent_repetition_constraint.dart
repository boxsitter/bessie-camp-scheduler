import '../../data_models/assignment_context.dart';
import '../../data_models/assignment_ledger.dart';
import '../../data_models/interfaces/constraint.dart';
import '../../data_models/potential_assignment.dart';

/// A participant may not be given the same activity in two back-to-back
/// periods of the same day, unless it is a double-schedule activity (whose
/// blocks are back-to-back by definition).
///
/// O(number of periods in which the participant holds this activity).
class AdjacentRepetitionConstraint implements Constraint {
  @override
  String get violationMessage =>
      'Participant is already assigned to this activity in an adjacent period.';

  @override
  bool isViolated(
    PotentialAssignment assignment,
    AssignmentContext context,
    AssignmentLedger ledger,
  ) {
    if (assignment.activity.doubleSchedule) return false;

    final index = context.periodIndex(assignment.period.id);
    final dayId = assignment.period.dayId;
    final held = ledger.periodIndicesOf(
      assignment.participant.id,
      assignment.activity.id,
    );

    for (final heldIndex in held) {
      if ((heldIndex - index).abs() == 1 &&
          context.periods[heldIndex].dayId == dayId) {
        return true;
      }
    }
    return false;
  }
}
