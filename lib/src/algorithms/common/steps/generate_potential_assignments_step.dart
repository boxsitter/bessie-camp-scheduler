import '../../data_models/enums.dart';
import '../../data_models/interfaces/algorithm_step.dart';
import '../../data_models/pipeline_state.dart';
import '../../data_models/potential_assignment.dart';

/// The first step: generates every candidate assignment.
///
/// For each participant and each target period in which the participant is
/// still free, a candidate is produced for every *assignable* scheduled
/// activity of that period, except:
///  * activities the participant has vetoed;
///  * hidden (non-assignable) activities, which only ever appear in existing
///    assignments;
///  * double-schedule activities that cannot be completed: the next
///    chronological period must be on the same day, offer the same activity,
///    and the participant must be free in it too.
///
/// A double-schedule activity yields ONE candidate that represents the whole
/// two-period block (the second period does not have to be a target period).
///
/// Generation order is deterministic: participants in the supplied order,
/// target periods chronologically, scheduled activities in the supplied order.
class GeneratePotentialAssignmentsStep extends AlgorithmStep {
  @override
  String get stepName => 'Generate Potential Assignments';

  @override
  StepOutcome execute(PipelineState state) {
    final context = state.context;
    final ledger = state.ledger;
    final candidates = <PotentialAssignment>[];
    var vetoed = 0;
    var unfinishableDoubles = 0;

    for (final participant in context.participants) {
      for (final period in context.targetPeriods) {
        final periodIndex = context.periodIndex(period.id);
        if (ledger.isBusy(participant.id, periodIndex)) continue;

        for (final scheduled in context.scheduledActivitiesIn(period.id)) {
          final activity = context.activityById(scheduled.activityId)!;
          if (!activity.assignable) continue;

          if (context.preferenceOf(participant.id, activity.id) ==
              PreferenceType.veto) {
            vetoed++;
            continue;
          }

          if (!activity.doubleSchedule) {
            candidates.add(PotentialAssignment(
              participant: participant,
              activity: activity,
              scheduledActivity: scheduled,
              period: period,
              sequence: candidates.length,
            ));
            continue;
          }

          final next = context.nextPeriod(period.id);
          final linked = next == null || !context.isSameDay(period, next)
              ? null
              : context.scheduledActivityOf(activity.id, next.id);
          if (next == null ||
              linked == null ||
              ledger.isBusy(participant.id, context.periodIndex(next.id))) {
            unfinishableDoubles++;
            continue;
          }
          candidates.add(PotentialAssignment(
            participant: participant,
            activity: activity,
            scheduledActivity: scheduled,
            period: period,
            linkedScheduledActivity: linked,
            linkedPeriod: next,
            sequence: candidates.length,
          ));
        }
      }
    }
    state.potentialAssignments = candidates;

    return StepOutcome(
      summary: 'Generated ${candidates.length} potential assignments '
          '(vetoes and hidden activities excluded, doubles merged).',
      details: {
        'count': candidates.length,
        'skippedVetoed': vetoed,
        'skippedUnfinishableDoubles': unfinishableDoubles,
      },
    );
  }
}
