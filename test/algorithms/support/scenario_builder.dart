import 'package:bessie/src/algorithms/assignment_engine.dart';

/// A small fluent builder for engine scenarios.
///
/// Conventions that keep the tests readable:
///  * `day('mon', periods: 3)` creates the periods `mon1`, `mon2`, `mon3` on one
///    day; days are chronological in the order they are added.
///  * `offer('swim', ['mon1'])` creates the scheduled activity `swim@mon1`
///    (see [ScenarioBuilder.sa]).
///  * `participant('amy', age: 10, requests: ['swim'], vetoes: ['art'])`.
class ScenarioBuilder {
  /// The `now` of every scenario; ages are relative to it.
  static final DateTime defaultNow = DateTime(2025, 7, 15, 12);

  /// The id of the scheduled instance of [activityId] in [periodId].
  static String sa(String activityId, String periodId) =>
      '$activityId@$periodId';

  DateTime now = defaultNow;

  final List<AlgoParticipant> _participants = [];
  final Map<String, Map<String, PreferenceType>> _preferences = {};
  final List<AlgoPeriod> _periods = [];
  final List<AlgoActivity> _activities = [];
  final List<AlgoScheduledActivity> _scheduled = [];
  final Map<String, Set<String>> _existing = {};
  final Map<String, int> _external = {};
  Set<String>? _targets;
  int _dayCount = 0;

  /// Adds a day with [periods] chronological periods named `<dayId>1..n`.
  ScenarioBuilder day(String dayId, {required int periods}) {
    final date = DateTime(2025, 7, 14 + _dayCount);
    for (var i = 1; i <= periods; i++) {
      _periods.add(
        AlgoPeriod(
          id: '$dayId$i',
          dayId: dayId,
          start: DateTime(date.year, date.month, date.day, 8 + i),
        ),
      );
    }
    _dayCount++;
    return this;
  }

  ScenarioBuilder activity(
    String id, {
    int capacity = 10,
    int? maxAssignments,
    bool doubleSchedule = false,
    bool assignable = true,
  }) {
    _activities.add(
      AlgoActivity(
        id: id,
        capacity: capacity,
        maxAssignments: maxAssignments,
        doubleSchedule: doubleSchedule,
        assignable: assignable,
      ),
    );
    return this;
  }

  /// Offers [activityId] in each of [periodIds].
  ScenarioBuilder offer(String activityId, List<String> periodIds) {
    for (final periodId in periodIds) {
      _scheduled.add(
        AlgoScheduledActivity(
          id: sa(activityId, periodId),
          activityId: activityId,
          periodId: periodId,
        ),
      );
    }
    return this;
  }

  /// Offers [activityId] in every period created so far.
  ScenarioBuilder offerEverywhere(String activityId) =>
      offer(activityId, [for (final p in _periods) p.id]);

  ScenarioBuilder participant(
    String id, {
    int age = 12,
    List<String> requests = const [],
    List<String> vetoes = const [],
  }) {
    _participants.add(
      AlgoParticipant(
        id: id,
        birthdate: DateTime(now.year - age, now.month, now.day),
      ),
    );
    final prefs = <String, PreferenceType>{
      for (final r in requests) r: PreferenceType.request,
      for (final v in vetoes) v: PreferenceType.veto,
    };
    if (prefs.isNotEmpty) _preferences[id] = prefs;
    return this;
  }

  /// Gives [participantId] existing assignments (scheduled activity ids).
  ScenarioBuilder existing(
    String participantId,
    List<String> scheduledActivityIds,
  ) {
    (_existing[participantId] ??= {}).addAll(scheduledActivityIds);
    return this;
  }

  /// Reports [seats] seats of [scheduledActivityId] as taken by campers outside
  /// the run.
  ScenarioBuilder external(String scheduledActivityId, int seats) {
    _external[scheduledActivityId] = seats;
    return this;
  }

  /// Restricts the periods the run must fill (default: all of them).
  ScenarioBuilder targets(List<String> periodIds) {
    _targets = periodIds.toSet();
    return this;
  }

  AssignmentContext build() {
    return AssignmentContext(
      participants: _participants,
      preferences: _preferences,
      periods: _periods,
      targetPeriodIds: _targets ?? {for (final p in _periods) p.id},
      activities: _activities,
      scheduledActivities: _scheduled,
      existingAssignments: _existing,
      externalEnrollment: _external,
      now: now,
    );
  }
}

/// Reading helpers for results.
extension AssignmentResultReading on AssignmentResult {
  /// The scheduled activity ids newly placed for [participantId], in placement
  /// order.
  List<String> placedFor(String participantId) => [
    for (final p in newPlacements)
      if (p.participantId == participantId) p.scheduledActivityId,
  ];

  /// All new placements as `participant:scheduledActivity` strings, sorted, for
  /// compact whole-result comparisons.
  List<String> get placementStrings => ([
    for (final p in newPlacements)
      '${p.participantId}:${p.scheduledActivityId}',
  ]..sort());

  /// The `participantId@periodId` keys of the stalemates, sorted.
  List<String> get stalemateKeys =>
      ([for (final s in stalemates) '${s.participantId}@${s.periodId}']
        ..sort());
}

/// A copy of [context] in which everything [result] placed has become an
/// existing assignment: "what you get if you save the result and run again".
AssignmentContext contextAfter(
  AssignmentContext context,
  AssignmentResult result,
) {
  final merged = <String, Set<String>>{
    for (final entry in context.existingAssignments.entries)
      entry.key: {...entry.value},
  };
  for (final placement in result.newPlacements) {
    (merged[placement.participantId] ??= {}).add(placement.scheduledActivityId);
  }
  return AssignmentContext(
    participants: context.participants,
    preferences: context.preferences,
    periods: context.periods,
    targetPeriodIds: context.targetPeriodIds,
    activities: context.activities,
    scheduledActivities: context.scheduledActivities,
    existingAssignments: merged,
    externalEnrollment: context.externalEnrollment,
    now: context.now,
  );
}
