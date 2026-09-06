

import '../../data_models/analogs/algo_period.dart';
import '../../data_models/analogs/algo_scheduled_activity.dart';
import '../../data_models/interfaces/algorithm_step.dart';
import '../../data_models/pipeline_state.dart';
import '../../data_models/potential_assignment.dart';
import '../../evaluation/step_report.dart';

/// The first step in the assignment pipeline, updated to handle double-periods.
///
/// This step generates a list of possible assignments. It now intelligently
/// identifies and links double-period activities, creating a single
/// `PotentialAssignment` to represent the two-period block. It also filters
/// out any assignments that have been explicitly vetoed by the participant.
class GeneratePotentialAssignmentsStep extends AlgorithmStep {
  @override
  String get stepName => 'Generate Potential Assignments';

  @override
  StepReport execute(PipelineState state) {
    final List <PotentialAssignment> potentialAssignments = [];

    for (final participant in state.context.participants.values) {
      for (final period in state.context.targetPeriods.values) {
        if (state.context.isParticipantAssignedInPeriod(participant.id, period.id)) {
          continue;
        }

        for (final scheduledActivity in state.context.getScheduledActivitiesInPeriod(period.id)) {
          final activity = state.context.allActivities[scheduledActivity.activityId];
          if (activity == null) continue;

          // --- VETO CHECK ---
          // Skip this potential assignment if the participant has vetoed the activity.
          final preference = state.context.participantPreferences[participant.id]?[activity.id];
          if (preference == 0.0) {
            continue;
          }

          if (activity.doubleSchedule) {
            final AlgoPeriod? nextPeriod = state.context.getNextPeriod(period.id);

            // --- DOUBLE SCHEDULE CHECKS ---
            if (nextPeriod != null &&
                state.context.isSameDay(period, nextPeriod) &&
                !state.context.isParticipantAssignedInPeriod(participant.id, nextPeriod.id)) { // <-- ADDED CHECK
              final AlgoScheduledActivity? linkedScheduled = state.context.getScheduledActivityInPeriod(activity.id, nextPeriod.id);

              if (linkedScheduled != null) {
                potentialAssignments.add(PotentialAssignment(
                  participant: participant,
                  activity: activity,
                  scheduledActivity: scheduledActivity,
                  period: period,
                  linkedScheduledActivity: linkedScheduled,
                  linkedPeriod: nextPeriod,
                ));
              }
            }
          } else {
            potentialAssignments.add(PotentialAssignment(
              participant: participant,
              scheduledActivity: scheduledActivity,
              activity: activity,
              period: period,
            ));
          }
        }
      }
    }
    state.potentialAssignments = potentialAssignments;

    return StepReport(
      stepName: stepName,
      summary: 'Generated ${potentialAssignments.length} potential assignments (merged doubles, filtered vetoes).',
      details: {'count': potentialAssignments.length},
      duration: Duration.zero,
    );
  }
}
