
import 'package:bessie/src/algorithms/common/constraints/capacity_constraint.dart';

import '../data_models/analogs/algo_scheduled_activity.dart';
import '../data_models/assignment_context.dart';
import '../data_models/interfaces/algorithm_step.dart';
import '../data_models/pipeline_state.dart';
import '../data_models/potential_assignment.dart';
import '../evaluation/step_report.dart';

class OverfillRequests extends AlgorithmStep {
  @override
  String get stepName => 'Pass 2: Overfill for Requests';

  @override
  StepReport execute(PipelineState state) {
    int successCount = 0;
    final capacityConstraint = CapacityConstraint();

    for (final participant in state.context.participants.values) {
      final requests = _getParticipantRequests(participant.id, state.context);
      final fulfilledRequests = state.result
          .getAssignmentsForParticipant(participant.id)
          .map((a) => a.activity.id)
          .toSet();

      for (final requestedActivityId in requests) {
        if (fulfilledRequests.contains(requestedActivityId)) continue;

        final availableInstances = _findAvailableInstances(requestedActivityId, participant.id, state)
            .where(
              (sa) => capacityConstraint.isViolated(
            PotentialAssignment(
              participant: participant,
              activity: state.context.allActivities[sa.activityId]!,
              scheduledActivity: sa,
              period: state.context.targetPeriods[sa.periodId]!,
            ),
            state.context,
            state.result,
          ),
        )
            .toList();

        if (availableInstances.isNotEmpty) {
          final chosenInstance = _getLeastFilledInstance(availableInstances, state);
          final activity = state.context.allActivities[chosenInstance.activityId]!;
          final period = state.context.targetPeriods[chosenInstance.periodId]!;

          // --- MODIFICATION START ---
          if (activity.doubleSchedule) {
            final nextPeriod = state.context.getNextPeriod(period.id);
            if (nextPeriod != null &&
                state.context.isSameDay(period, nextPeriod) &&
                !state.context.isParticipantAssignedInPeriod(participant.id, nextPeriod.id)) {
              final linkedScheduledActivity =
                  state.context.getScheduledActivityInPeriod(activity.id, nextPeriod.id);

              if (linkedScheduledActivity != null) {
                final assignment = PotentialAssignment(
                    participant: participant,
                    activity: activity,
                    scheduledActivity: chosenInstance,
                    period: period,
                    linkedScheduledActivity: linkedScheduledActivity,
                    linkedPeriod: nextPeriod);
                _addSuccess(assignment, state);
                successCount++;
              }
            }
          } else {
          final assignment = PotentialAssignment(
            participant: participant,
              activity: activity,
            scheduledActivity: chosenInstance,
              period: period,
          );
            _addSuccess(assignment, state);
          successCount++;
        }
          // --- MODIFICATION END ---
        }
      }
    }

    return StepReport(
      stepName: stepName,
      summary: 'Fulfilled $successCount requests by overfilling.',
      details: {'successCount': successCount},
      duration: Duration.zero,
    );
  }

  List<String> _getParticipantRequests(String participantId, AssignmentContext context) {
    final preferences = context.participantPreferences[participantId];
    if (preferences == null) return [];
    return preferences.entries.where((e) => e.value == 1.0).map((e) => e.key).toList();
  }

  List<AlgoScheduledActivity> _findAvailableInstances(
      String activityId, String participantId, PipelineState state) {
    return state.context.allScheduledActivities.values
        .where((sa) =>
    sa.activityId == activityId &&
        !state.context.isParticipantAssignedInPeriod(participantId, sa.periodId))
        .toList();
  }

  AlgoScheduledActivity _getLeastFilledInstance(
      List<AlgoScheduledActivity> instances, PipelineState state) {
    instances.sort((a, b) {
      final countA =
          state.result.successfulAssignments.where((pa) => pa.scheduledActivity.id == a.id).length;
      final countB =
          state.result.successfulAssignments.where((pa) => pa.scheduledActivity.id == b.id).length;
      return countA.compareTo(countB);
    });
    return instances.first;
  }

  void _addSuccess(PotentialAssignment assignment, PipelineState state) {
    state.result.addSuccess(assignment);
    if (assignment.isDoubleAssignment) {
      final linkedAssignment = PotentialAssignment(
        participant: assignment.participant,
        activity: assignment.activity,
        scheduledActivity: assignment.linkedScheduledActivity!,
        period: assignment.linkedPeriod!,
      );
      state.result.addSuccess(linkedAssignment);
    }
  }
}