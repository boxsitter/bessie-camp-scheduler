import 'dart:math';

import '../../data_models/analogs/algo_participant.dart';
import '../../data_models/analogs/algo_period.dart';
import '../../data_models/assignment_result.dart';
import '../../data_models/assignment_stalemate_exception.dart';
import '../../data_models/enums.dart';
import '../../data_models/interfaces/algorithm_step.dart';
import '../../data_models/interfaces/constraint.dart';
import '../../data_models/pipeline_state.dart';
import '../../data_models/potential_assignment.dart';
import '../constraints/constraint_checks.dart';

typedef _Slot = ({AlgoParticipant participant, AlgoPeriod period});

/// Deals with every (participant, period) slot of the target periods that the
/// main pass left empty, according to the [StalemateStrategy]:
///
///  * `leaveUnassigned`: records a [Stalemate] for each slot.
///  * `fail`: records them and throws an [AssignmentStalemateException] that
///    carries all of them.
///  * `randomize`: for each empty slot (in random order) tries the participant's
///    non-vetoed, assignable scheduled activities in random order, with every
///    constraint relaxed except [relaxedConstraints] (capacity and
///    double-schedule feasibility by default), and still never double-books
///    the participant. Only a slot where nothing fits is recorded as a
///    stalemate.
class ResolveStalematesStep extends AlgorithmStep {
  final StalemateStrategy strategy;

  /// The full set of hard rules; used to explain why a slot stayed empty.
  final List<Constraint> constraints;

  /// The rules that survive the `randomize` fallback.
  final List<Constraint> relaxedConstraints;

  final Random _random;

  ResolveStalematesStep({required this.strategy, required this.constraints, required this.relaxedConstraints, Random? random})
    : _random = random ?? Random();

  @override
  String get stepName => 'Resolve Stalemates';

  @override
  StepOutcome execute(PipelineState state) {
    final unfilled = _unfilledSlots(state);
    final strategyName = strategy.name;
    if (unfilled.isEmpty) {
      return StepOutcome(
        summary: 'Every slot was filled; no stalemates.',
        details: {'stalemateStrategy': strategyName, 'randomizedPlacements': 0, 'stalemateCount': 0},
      );
    }

    final candidatesBySlot = _indexCandidates(state);

    var randomizedPlacements = 0;
    if (strategy == StalemateStrategy.randomize) {
      randomizedPlacements = _randomize(state, unfilled, candidatesBySlot);
    }

    final remaining = strategy == StalemateStrategy.randomize ? _unfilledSlots(state) : unfilled;
    final enforced = strategy == StalemateStrategy.randomize ? relaxedConstraints : constraints;
    for (final slot in remaining) {
      final reason = _explain(slot, state, candidatesBySlot, enforced);
      state.stalemates.add(
        Stalemate(
          participantId: slot.participant.id,
          periodId: slot.period.id,
          reason: strategy == StalemateStrategy.randomize ? 'Even with relaxed constraints nothing could be placed. $reason' : reason,
        ),
      );
    }

    if (strategy == StalemateStrategy.fail && state.stalemates.isNotEmpty) {
      throw AssignmentStalemateException(state.stalemates.entries);
    }

    return StepOutcome(
      summary:
          strategy == StalemateStrategy.randomize
              ? 'Randomize fallback made $randomizedPlacements placements; '
                  '${state.stalemates.length} stalemates remain.'
              : 'Recorded ${state.stalemates.length} stalemates.',
      details: {'stalemateStrategy': strategyName, 'randomizedPlacements': randomizedPlacements, 'stalemateCount': state.stalemates.length},
    );
  }

  /// The empty slots, participants in the supplied order, periods
  /// chronologically.
  List<_Slot> _unfilledSlots(PipelineState state) {
    final context = state.context;
    return [
      for (final participant in context.participants)
        for (final period in context.targetPeriods)
          if (!state.ledger.isBusy(participant.id, context.periodIndex(period.id))) (participant: participant, period: period),
    ];
  }

  /// participantId -> periodId -> the candidates that START in that period, for
  /// slots that are still empty.
  Map<String, Map<String, List<PotentialAssignment>>> _indexCandidates(PipelineState state) {
    final index = <String, Map<String, List<PotentialAssignment>>>{};
    for (final candidate in state.potentialAssignments) {
      final participantId = candidate.participant.id;
      if (state.ledger.isBusy(participantId, state.context.periodIndex(candidate.period.id))) {
        continue;
      }
      ((index[participantId] ??= {})[candidate.period.id] ??= []).add(candidate);
    }
    return index;
  }

  /// The randomize fallback. Returns the number of placements made.
  int _randomize(PipelineState state, List<_Slot> unfilled, Map<String, Map<String, List<PotentialAssignment>>> candidatesBySlot) {
    final context = state.context;
    final ledger = state.ledger;
    final before = ledger.newPlacements.length;

    final order = [...unfilled]..shuffle(_random);
    for (final slot in order) {
      final participantId = slot.participant.id;
      // A double block placed for an earlier slot may have covered this one.
      if (ledger.isBusy(participantId, context.periodIndex(slot.period.id))) {
        continue;
      }
      final options = [...?candidatesBySlot[participantId]?[slot.period.id]]..shuffle(_random);
      for (final option in options) {
        if (!ledger.isFree(option)) continue;
        if (relaxedConstraints.firstViolation(option, context, ledger) != null) {
          continue;
        }
        ledger.place(option);
        break;
      }
    }
    return ledger.newPlacements.length - before;
  }

  /// Explains why an empty slot stayed empty, activity by activity.
  String _explain(
    _Slot slot,
    PipelineState state,
    Map<String, Map<String, List<PotentialAssignment>>> candidatesBySlot,
    List<Constraint> enforced,
  ) {
    final context = state.context;
    final ledger = state.ledger;
    final participantId = slot.participant.id;

    final scheduledHere = [
      for (final scheduled in context.scheduledActivitiesIn(slot.period.id))
        if (context.activityById(scheduled.activityId)!.assignable) scheduled,
    ];
    if (scheduledHere.isEmpty) {
      return 'No assignable activity is scheduled in this period.';
    }

    final candidateByScheduledId = {
      for (final candidate in candidatesBySlot[participantId]?[slot.period.id] ?? const <PotentialAssignment>[])
        candidate.scheduledActivity.id: candidate,
    };

    final parts = <String>[];
    final vetoed = <String>[];
    for (final scheduled in scheduledHere) {
      final activityId = scheduled.activityId;
      if (context.preferenceOf(participantId, activityId) == PreferenceType.veto) {
        vetoed.add(activityId);
        continue;
      }
      final candidate = candidateByScheduledId[scheduled.id];
      if (candidate == null) {
        parts.add(
          'Activity $activityId is a double-schedule activity that cannot '
          'be completed (the next period is on another day, does not offer it, '
          'or the participant is busy then)',
        );
        continue;
      }
      final violations = enforced.violations(candidate, context, ledger);
      if (violations.isNotEmpty) {
        parts.add('Activity $activityId violated: [${violations.join(', ')}]');
      } else if (!ledger.isFree(candidate)) {
        parts.add('Activity $activityId: the participant is busy in the linked period');
      } else {
        parts.add('Activity $activityId was not chosen');
      }
    }
    if (vetoed.isNotEmpty) {
      parts.insert(0, 'Vetoed by the participant: ${vetoed.join(', ')}');
    }
    return 'All options were ruled out. ${parts.join('; ')}';
  }
}
