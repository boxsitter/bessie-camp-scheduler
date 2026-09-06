import 'dart:math';

import 'package:bessie/src/algorithms/diplomatic_algorithm/same_day_repetition_constraint.dart';
import 'package:bessie/src/algorithms/diplomatic_algorithm/weekly_repetition_constraint.dart';

import '../common/constraints/adjacent_repetition_constraint.dart';
import '../common/constraints/capacity_constraint.dart';
import '../common/constraints/reassignment_constraint.dart';
import '../data_models/enums.dart';
import '../data_models/interfaces/Constraint.dart';
import '../data_models/interfaces/algorithm_step.dart';
import '../data_models/pipeline_state.dart';
import '../data_models/potential_assignment.dart';
import '../evaluation/step_report.dart';

class FillSchedule extends AlgorithmStep {
  final StalemateStrategy stalemateStrategy;
  final Random _random;

  FillSchedule({
    required this.stalemateStrategy,
    Random? random,
  }) : _random = random ?? Random();

  @override
  String get stepName => 'Pass 3: Fill Remaining Schedule';

  @override
  StepReport execute(PipelineState state) {
    int successCount = 0;
    int stalemateCount = 0;

    for (final period in state.context.targetPeriods.values) {
      for (final participant in state.context.participants.values) {
        if (state.context.isParticipantAssignedInPeriod(participant.id, period.id)) {
          continue;
        }

        final potentialActivities = state.context
            .getScheduledActivitiesInPeriod(period.id)
            .where((sa) =>
        state.context.participantPreferences[participant.id]?[sa.activityId] != 0.0)
            .toList()
          ..shuffle(_random);

        bool assigned = false;
        for (final scheduledActivity in potentialActivities) {
          final activity = state.context.allActivities[scheduledActivity.activityId]!;

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
                    scheduledActivity: scheduledActivity,
                    period: period,
                    linkedScheduledActivity: linkedScheduledActivity,
                    linkedPeriod: nextPeriod);
                if (!_isViolated(assignment, state)) {
                  _addSuccess(assignment, state);
                  successCount++;
                  assigned = true;
                  break;
                }
              }
            }
          } else {
          final assignment = PotentialAssignment(
            participant: participant,
              activity: activity,
            scheduledActivity: scheduledActivity,
            period: period,
          );

          if (!_isViolated(assignment, state)) {
              _addSuccess(assignment, state);
            successCount++;
            assigned = true;
            break;
          }
        }
        }

        if (!assigned) {
          stalemateCount++;
          state.result.addStalemate(participant.id, period.id, 'No valid assignment found.');
        }
      }
    }

    return StepReport(
      stepName: stepName,
      summary: 'Filled $successCount remaining slots, with $stalemateCount stalemates.',
      details: {'successCount': successCount, 'stalemateCount': stalemateCount},
      duration: Duration.zero,
    );
  }

  bool _isViolated(PotentialAssignment assignment, PipelineState state) {
    final List<Constraint> constraints = [
      CapacityConstraint(),
      ReassignmentConstraint(),
      SameDayRepetitionConstraint(),
      WeeklyRepetitionConstraint(),
      AdjacentRepetitionConstraint()
    ];
    for (final Constraint constraint in constraints) {
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