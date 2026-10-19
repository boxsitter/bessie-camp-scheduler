import 'package:bessie/src/algorithms/assignment_engine.dart';
import 'package:bessie/src/algorithms/data_models/assignment_ledger.dart';
import 'package:bessie/src/algorithms/data_models/pipeline_state.dart';
import 'package:bessie/src/algorithms/data_models/potential_assignment.dart';

/// Builds a candidate by hand, without going through candidate generation, so
/// tests can also construct malformed ones.
///
/// For a double-schedule block pass [linkedPeriodId]; the linked scheduled
/// instance is the same activity in that period.
PotentialAssignment candidateOf(
  AssignmentContext context,
  String participantId,
  String activityId,
  String periodId, {
  String? linkedPeriodId,
  int sequence = 0,
}) {
  return PotentialAssignment(
    participant: context.participantById(participantId)!,
    activity: context.activityById(activityId)!,
    scheduledActivity: context.scheduledActivityOf(activityId, periodId)!,
    period: context.periodById(periodId)!,
    linkedScheduledActivity:
        linkedPeriodId == null ? null : context.scheduledActivityOf(activityId, linkedPeriodId)!,
    linkedPeriod: linkedPeriodId == null ? null : context.periodById(linkedPeriodId)!,
    sequence: sequence,
  );
}

/// A fresh pipeline state (and ledger) for [context].
PipelineState stateFor(AssignmentContext context) =>
    PipelineState(context: context, ledger: AssignmentLedger(context));

/// A copy of the double-schedule [block] whose second half is [linked], for
/// building deliberately malformed candidates.
PotentialAssignment withLinkedScheduledActivity(
  PotentialAssignment block,
  AlgoScheduledActivity linked,
) {
  return PotentialAssignment(
    participant: block.participant,
    activity: block.activity,
    scheduledActivity: block.scheduledActivity,
    period: block.period,
    linkedScheduledActivity: linked,
    linkedPeriod: block.linkedPeriod,
    sequence: block.sequence,
  );
}
