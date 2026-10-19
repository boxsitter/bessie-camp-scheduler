import 'analogs/algo_activity.dart';
import 'analogs/algo_participant.dart';
import 'analogs/algo_period.dart';
import 'analogs/algo_scheduled_activity.dart';
import 'enums.dart';

/// Everything the engine needs for one run, plus the lookups derived from it.
///
/// The context is immutable: the collections passed in are copied, periods are
/// sorted chronologically and all indexes are built once, up front. It is a
/// pure data holder and never reads the system clock; ages are computed
/// against [now].
///
/// Input conventions:
///  * Ids must be unique within their kind, and every id in [targetPeriodIds]
///    must name a period; otherwise the constructor throws an [ArgumentError].
///  * Dangling references elsewhere are ignored rather than rejected: a
///    scheduled activity pointing at an unknown activity or period is dropped,
///    and existing assignments naming an unknown scheduled activity or a
///    participant that is not part of the run are skipped (seats held by people
///    outside the run must be reported through [externalEnrollment]).
class AssignmentContext {
  /// The participants to be assigned, in the caller's order.
  final List<AlgoParticipant> participants;

  /// participantId -> activityId -> preference. Neutral is the absence of an
  /// entry.
  final Map<String, Map<String, PreferenceType>> preferences;

  /// Every period of the session, sorted chronologically (by start, then id).
  final List<AlgoPeriod> periods;

  /// The ids of the periods this run must fill.
  final Set<String> targetPeriodIds;

  /// All activities.
  final List<AlgoActivity> activities;

  /// All scheduled activities, including non-assignable (hidden) ones.
  final List<AlgoScheduledActivity> scheduledActivities;

  /// participantId -> ids of the scheduled activities the participant already
  /// holds (any period, hidden ones included).
  final Map<String, Set<String>> existingAssignments;

  /// scheduledActivityId -> seats already taken by campers who are NOT part of
  /// [participants].
  final Map<String, int> externalEnrollment;

  /// The instant used to compute ages.
  final DateTime now;

  late final Map<String, AlgoParticipant> _participantById;
  late final Map<String, AlgoActivity> _activityById;
  late final Map<String, AlgoPeriod> _periodById;
  late final Map<String, int> _periodIndexById;
  late final Map<String, AlgoScheduledActivity> _scheduledById;
  late final Map<String, List<AlgoScheduledActivity>> _scheduledByPeriod;
  late final Map<String, Map<String, AlgoScheduledActivity>>
  _scheduledByPeriodAndActivity;
  late final Map<String, int> _ageById;
  late final List<AlgoPeriod> _targetPeriods;

  AssignmentContext({
    required List<AlgoParticipant> participants,
    required Map<String, Map<String, PreferenceType>> preferences,
    required List<AlgoPeriod> periods,
    required Set<String> targetPeriodIds,
    required List<AlgoActivity> activities,
    required List<AlgoScheduledActivity> scheduledActivities,
    required Map<String, Set<String>> existingAssignments,
    Map<String, int> externalEnrollment = const {},
    required this.now,
  }) : participants = List.unmodifiable(participants),
       preferences = Map.unmodifiable({
         for (final entry in preferences.entries)
           entry.key: Map<String, PreferenceType>.unmodifiable(entry.value),
       }),
       periods = List.unmodifiable(_sortChronologically(periods)),
       targetPeriodIds = Set.unmodifiable(targetPeriodIds),
       activities = List.unmodifiable(activities),
       scheduledActivities = List.unmodifiable(scheduledActivities),
       existingAssignments = Map.unmodifiable({
         for (final entry in existingAssignments.entries)
           entry.key: Set<String>.unmodifiable(entry.value),
       }),
       externalEnrollment = Map.unmodifiable(externalEnrollment) {
    _participantById = _indexById(
      this.participants,
      (p) => p.id,
      'participant',
    );
    _activityById = _indexById(this.activities, (a) => a.id, 'activity');
    _periodById = _indexById(this.periods, (p) => p.id, 'period');
    _periodIndexById = {
      for (var i = 0; i < this.periods.length; i++) this.periods[i].id: i,
    };

    final scheduledById = _indexById(
      this.scheduledActivities,
      (s) => s.id,
      'scheduled activity',
    );
    _scheduledById = {
      for (final entry in scheduledById.entries)
        if (_activityById.containsKey(entry.value.activityId) &&
            _periodById.containsKey(entry.value.periodId))
          entry.key: entry.value,
    };

    _scheduledByPeriod = {};
    _scheduledByPeriodAndActivity = {};
    for (final scheduled in this.scheduledActivities) {
      if (!_scheduledById.containsKey(scheduled.id)) continue;
      (_scheduledByPeriod[scheduled.periodId] ??= []).add(scheduled);
      (_scheduledByPeriodAndActivity[scheduled.periodId] ??= {}).putIfAbsent(
        scheduled.activityId,
        () => scheduled,
      );
    }

    for (final periodId in this.targetPeriodIds) {
      if (!_periodById.containsKey(periodId)) {
        throw ArgumentError.value(
          periodId,
          'targetPeriodIds',
          'is not one of the context periods',
        );
      }
    }
    _targetPeriods = List.unmodifiable([
      for (final p in this.periods)
        if (this.targetPeriodIds.contains(p.id)) p,
    ]);

    _ageById = {for (final p in this.participants) p.id: p.ageOn(now)};
  }

  /// The target periods, sorted chronologically.
  List<AlgoPeriod> get targetPeriods => _targetPeriods;

  AlgoParticipant? participantById(String id) => _participantById[id];

  AlgoActivity? activityById(String id) => _activityById[id];

  AlgoPeriod? periodById(String id) => _periodById[id];

  /// The scheduled activity with this id, or `null` if it is unknown or refers
  /// to an unknown activity or period.
  AlgoScheduledActivity? scheduledActivityById(String id) => _scheduledById[id];

  /// The position of the period in the chronologically sorted [periods].
  ///
  /// Throws an [ArgumentError] for an unknown id.
  int periodIndex(String periodId) {
    final index = _periodIndexById[periodId];
    if (index == null) {
      throw ArgumentError.value(periodId, 'periodId', 'Unknown period');
    }
    return index;
  }

  /// The next chronological period after [periodId], or `null` for the last.
  AlgoPeriod? nextPeriod(String periodId) {
    final next = periodIndex(periodId) + 1;
    return next < periods.length ? periods[next] : null;
  }

  /// All scheduled activities (hidden ones included) offered in [periodId], in
  /// the order they were supplied.
  List<AlgoScheduledActivity> scheduledActivitiesIn(String periodId) =>
      _scheduledByPeriod[periodId] ?? const [];

  /// The scheduled instance of [activityId] in [periodId], if it is offered
  /// there.
  AlgoScheduledActivity? scheduledActivityOf(
    String activityId,
    String periodId,
  ) => _scheduledByPeriodAndActivity[periodId]?[activityId];

  /// What [participantId] thinks of [activityId]; `null` means neutral.
  PreferenceType? preferenceOf(String participantId, String activityId) =>
      preferences[participantId]?[activityId];

  /// The participant's age in whole years on [now].
  int ageOf(String participantId) => _ageById[participantId] ?? 0;

  /// Whether two periods fall on the same day.
  bool isSameDay(AlgoPeriod a, AlgoPeriod b) => a.dayId == b.dayId;

  static List<AlgoPeriod> _sortChronologically(List<AlgoPeriod> periods) {
    return [...periods]..sort((a, b) {
      final byStart = a.start.compareTo(b.start);
      return byStart != 0 ? byStart : a.id.compareTo(b.id);
    });
  }

  static Map<String, T> _indexById<T>(
    Iterable<T> items,
    String Function(T) idOf,
    String what,
  ) {
    final index = <String, T>{};
    for (final item in items) {
      final id = idOf(item);
      if (index.containsKey(id)) {
        throw ArgumentError('Duplicate $what id "$id".');
      }
      index[id] = item;
    }
    return index;
  }
}
