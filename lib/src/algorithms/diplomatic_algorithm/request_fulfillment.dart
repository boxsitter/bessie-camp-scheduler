import 'dart:math';

import 'package:bessie/src/algorithms/common/constraints/capacity_constraint.dart';

import '../data_models/analogs/algo_scheduled_activity.dart';
import '../data_models/assignment_context.dart';
import '../data_models/interfaces/algorithm_step.dart';
import '../data_models/pipeline_state.dart';
import '../data_models/potential_assignment.dart';
import '../evaluation/step_report.dart';

class RequestFulfillment extends AlgorithmStep {
  final Random _random;

  RequestFulfillment({Random? random}) : _random = random ?? Random();

  @override
  String get stepName => 'Pass 1: Fulfill Requests';

  @override
  StepReport execute(PipelineState state) {
    final participants = state.context.participants.values.toList()..shuffle(_random);
    int successCount = 0;
    int stalemateCount = 0;

    for (final participant in participants) {
      final requests = _getParticipantRequests(participant.id, state.context);

      for (final requestedActivityId in requests) {
        final availableScheduledActivities =
        _findAvailableInstances(requestedActivityId, participant.id, state);

        if (availableScheduledActivities.isNotEmpty) {
          final chosenScheduledActivity =
          availableScheduledActivities[_random.nextInt(availableScheduledActivities.length)];
          final activity = state.context.allActivities[chosenScheduledActivity.activityId]!;
          final period = state.context.targetPeriods[chosenScheduledActivity.periodId]!;

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
            scheduledActivity: chosenScheduledActivity,
            period: period,
                  linkedScheduledActivity: linkedScheduledActivity,
                  linkedPeriod: nextPeriod,
          );
                if (!_isViolated(assignment, state)) {
                  _addSuccess(assignment, state);
                  successCount++;
                } else {
                  stalemateCount++;
                  state.result.addStalemate(participant.id, period.id,
                      'Could not fulfill request due to constraint violation.');
                }
              } else {
                stalemateCount++;
                state.result.addStalemate(participant.id, period.id,
                    'Could not find a linked activity for a double schedule request.');
              }
            } else {
              stalemateCount++;
              state.result.addStalemate(
                  participant.id, period.id, 'Could not find a valid next period for a double schedule request.');
            }
          } else {
            final assignment = PotentialAssignment(
              participant: participant,
              activity: activity,
              scheduledActivity: chosenScheduledActivity,
              period: period,
            );

          if (!_isViolated(assignment, state)) {
                  _addSuccess(assignment, state);
            successCount++;
            } else {
              stalemateCount++;
              state.result.addStalemate(
                  participant.id, period.id, 'Could not fulfill request due to constraint violation.');
          }
        }
        } else {
          stalemateCount++;
          // It's not a true stalemate for a specific period yet, so we add a more general note.
          // A better approach might be a separate list for unfulfilled requests.
          state.result.addStalemate(
              participant.id, 'N/A', 'Request for activity $requestedActivityId could not be met.');
        }
      }
    }

    return StepReport(
      stepName: stepName,
      summary: 'Fulfilled $successCount initial requests with $stalemateCount stalemates.',
      details: {'successCount': successCount, 'stalemateCount': stalemateCount},
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

  bool _isViolated(PotentialAssignment assignment, PipelineState state) {
    final constraints = [CapacityConstraint()];
    for (final constraint in constraints) {
      if (constraint.isViolated(assignment, state.context, state.result)) {
        return true;
      }
    }
    return false;
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