import 'package:bessie/src/algorithms/assignment_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Asserts everything that must hold for ANY engine result, whatever the
/// scenario, strategy or seed.
///
/// With [enforceStandardConstraints] false (the `randomize` fallback relaxes
/// them on purpose) the assignment cap and adjacent-repetition checks are
/// skipped; everything else, capacity included, is always enforced.
///
/// Every message starts with [label] so a failing seed is easy to find.
void expectEngineInvariants(
  AssignmentContext context,
  AssignmentResult result, {
  bool enforceStandardConstraints = true,
  String label = '',
}) {
  String why(String message) => '$label $message';

  // What every participant holds: periodId -> scheduled activity ids.
  final held = <String, Map<String, List<String>>>{
    for (final p in context.participants) p.id: {},
  };
  for (final entry in context.existingAssignments.entries) {
    final book = held[entry.key];
    if (book == null) continue;
    for (final saId in entry.value) {
      final scheduled = context.scheduledActivityById(saId);
      if (scheduled != null) (book[scheduled.periodId] ??= []).add(saId);
    }
  }
  final existingKeys = {
    for (final entry in context.existingAssignments.entries)
      for (final saId in entry.value) '${entry.key}|$saId',
  };

  // --- the new placements themselves ---
  final newKeys = <String>{};
  final newByParticipantActivity =
      <String, List<int>>{}; // 'pid|activityId' -> period indexes
  for (final placement in result.newPlacements) {
    final key = '${placement.participantId}|${placement.scheduledActivityId}';
    expect(newKeys.add(key), isTrue, reason: why('duplicate placement $key'));
    expect(
      existingKeys.contains(key),
      isFalse,
      reason: why('placement $key repeats an existing assignment'),
    );

    final scheduled = context.scheduledActivityById(
      placement.scheduledActivityId,
    );
    expect(
      scheduled,
      isNotNull,
      reason: why('unknown scheduled activity in $key'),
    );
    final activity = context.activityById(scheduled!.activityId)!;
    expect(
      activity.assignable,
      isTrue,
      reason: why('hidden activity ${activity.id} was placed'),
    );
    expect(
      context.preferenceOf(placement.participantId, activity.id),
      isNot(PreferenceType.veto),
      reason: why('vetoed activity ${activity.id} was placed ($key)'),
    );

    (held[placement.participantId]![scheduled.periodId] ??= []).add(
      scheduled.id,
    );
    (newByParticipantActivity['${placement.participantId}|${activity.id}'] ??=
            [])
        .add(context.periodIndex(scheduled.periodId));
  }

  // --- 1. nobody is in two places at once ---
  held.forEach((participantId, byPeriod) {
    byPeriod.forEach((periodId, saIds) {
      expect(
        saIds.length,
        1,
        reason: why('$participantId holds $saIds in period $periodId'),
      );
    });
  });

  // --- 2. capacity, external enrollment included ---
  final seats = <String, int>{
    for (final entry in context.externalEnrollment.entries)
      entry.key: entry.value,
  };
  for (final byPeriod in held.values) {
    for (final saIds in byPeriod.values) {
      for (final saId in saIds) {
        seats[saId] = (seats[saId] ?? 0) + 1;
      }
    }
  }
  for (final scheduled in context.scheduledActivities) {
    final capacity = context.activityById(scheduled.activityId)!.capacity;
    expect(
      seats[scheduled.id] ?? 0,
      lessThanOrEqualTo(capacity),
      reason: why('${scheduled.id} is over capacity'),
    );
  }

  // --- 3. every double placement is a contiguous same-day pair ---
  newByParticipantActivity.forEach((key, indexes) {
    final activityId = key.split('|')[1];
    if (!context.activityById(activityId)!.doubleSchedule) return;
    indexes.sort();
    expect(
      indexes.length.isEven,
      isTrue,
      reason: why('$key has an unpaired double half: $indexes'),
    );
    for (var i = 0; i < indexes.length; i += 2) {
      expect(
        indexes[i + 1],
        indexes[i] + 1,
        reason: why('$key double block is not contiguous: $indexes'),
      );
      expect(
        context.periods[indexes[i]].dayId,
        context.periods[indexes[i + 1]].dayId,
        reason: why('$key double block spans two days'),
      );
    }
  });

  // --- 4. caps and adjacent repetition (not under the randomize fallback) ---
  if (enforceStandardConstraints) {
    newByParticipantActivity.forEach((key, newIndexes) {
      final participantId = key.split('|')[0];
      final activity = context.activityById(key.split('|')[1])!;
      final allIndexes = <int>[
        for (final entry in held[participantId]!.entries)
          for (final saId in entry.value)
            if (context.scheduledActivityById(saId)!.activityId == activity.id)
              context.periodIndex(entry.key),
      ]..sort();

      final cap = activity.maxAssignments;
      if (cap != null) {
        var occurrences = 0;
        for (var i = 0; i < allIndexes.length; i++) {
          occurrences++;
          if (activity.doubleSchedule &&
              i + 1 < allIndexes.length &&
              allIndexes[i + 1] == allIndexes[i] + 1) {
            i++;
          }
        }
        expect(
          occurrences,
          lessThanOrEqualTo(cap),
          reason: why('$key exceeds maxAssignments $cap ($allIndexes)'),
        );
      }

      if (!activity.doubleSchedule) {
        for (final index in newIndexes) {
          for (final other in allIndexes) {
            final adjacent =
                (other - index).abs() == 1 &&
                context.periods[other].dayId == context.periods[index].dayId;
            expect(
              adjacent,
              isFalse,
              reason: why('$key repeats in adjacent periods $index and $other'),
            );
          }
        }
      }
    });
  }

  // --- 5. stalemates are exactly the target slots that stayed empty ---
  final expectedStalemates = <String>[
    for (final participant in context.participants)
      for (final period in context.targetPeriods)
        if (!held[participant.id]!.containsKey(period.id))
          '${participant.id}@${period.id}',
  ]..sort();
  final actualStalemates = [
    for (final s in result.stalemates) '${s.participantId}@${s.periodId}',
  ]..sort();
  expect(
    actualStalemates,
    expectedStalemates,
    reason: why('stalemates do not match the empty target slots'),
  );
  for (final stalemate in result.stalemates) {
    expect(
      stalemate.reason,
      isNotEmpty,
      reason: why('stalemate without a reason'),
    );
  }

  // --- 6. evaluation output ---
  expect(
    result.evaluationReports.map((r) => r.participantId).toList(),
    context.participants.map((p) => p.id).toList(),
    reason: why('one evaluation report per participant, in order'),
  );
  for (final participant in context.participants) {
    final satisfaction = result.satisfaction[participant.id];
    final hasAssignments = held[participant.id]!.isNotEmpty;
    if (result.hasStalemate(participant.id) || !hasAssignments) {
      expect(
        satisfaction,
        isNull,
        reason: why('${participant.id} must have no satisfaction'),
      );
    } else {
      expect(
        satisfaction,
        isNotNull,
        reason: why('${participant.id} must have a satisfaction'),
      );
      expect(satisfaction, inInclusiveRange(0.0, 1.0));
    }
  }
}
