import 'package:intl/intl.dart';

import 'analogs/algo_activity.dart';
import 'analogs/algo_participant.dart';
import 'analogs/algo_period.dart';
import 'analogs/algo_scheduled_activity.dart';
import 'potential_assignment.dart';

/// Holds all the data required for a single run of the assignment algorithm.
///
/// This class acts as a central data provider for the algorithm, decoupling it
/// from external data sources and making it highly testable. It pre-computes
/// certain lookups to ensure efficient data access during the run.
class AssignmentContext {
  /// The participants to be assigned.
  final Map<String, AlgoParticipant> participants;

  /// A map of participant IDs to their activity preferences, where the value
  /// is a map of activity IDs to a preference score.
  final Map<String, Map<String, double?>> participantPreferences;

  /// The specific periods that the algorithm should attempt to fill.
  final Map<String, AlgoPeriod> targetPeriods;

  /// All available activities for the algorithm.
  final Map<String, AlgoActivity> allActivities;

  /// All instances of activities scheduled for the week.
  final Map<String, AlgoScheduledActivity> allScheduledActivities;

  /// All assignments that existed before this algorithm run, mapping a
  /// participant ID to a list of their assigned scheduled activity IDs.
  final Map<String, List<String>> existingAssignments;

  /// A chronologically sorted list of all periods for the week, used for
  /// sequential checks.
  final List<AlgoPeriod> weeklyPeriodsSorted;

  // Caches for faster lookups.
  final Map<String, AlgoPeriod> _allPeriodsById;
  final Map<String, List<AlgoScheduledActivity>> _scheduledActivitiesByPeriodId;

  // --- NEW ---
  // A complete, unfiltered map of every scheduled activity ID to its period ID.
  // This is used ONLY for the isParticipantAssignedInPeriod check.
  final Map<String, String> _allScheduledActivityToPeriodMap;


  /// Creates an instance of the assignment context.
  ///
  /// This constructor initializes all the necessary data and builds lookup
  /// caches to speed up the algorithm's execution.
  AssignmentContext({
    required this.participants,
    required this.participantPreferences,
    required this.targetPeriods,
    required this.allActivities,
    required this.allScheduledActivities, // This remains the filtered (non-hidden) map
    required this.existingAssignments, // This should be the unfiltered list of IDs
    required this.weeklyPeriodsSorted,
    // --- ADDED PARAMETER ---
    required Map<String, String> allScheduledActivityToPeriodMap,
  })  : _allPeriodsById = {for (var p in weeklyPeriodsSorted) p.id: p},
        _scheduledActivitiesByPeriodId = _groupActivitiesByPeriod(allScheduledActivities.values),
        // --- INITIALIZE NEW MAP ---
        _allScheduledActivityToPeriodMap = allScheduledActivityToPeriodMap;

  /// Groups scheduled activities by their period ID for efficient lookup.
  static Map<String, List<AlgoScheduledActivity>> _groupActivitiesByPeriod(
      Iterable<AlgoScheduledActivity> activities) {
    final map = <String, List<AlgoScheduledActivity>>{};
    for (final activity in activities) {
      (map[activity.periodId] ??= []).add(activity);
    }
    return map;
  }

  /// Checks if a participant already has an assignment in a specific period.
  /// This check is now robust and includes hidden activities.
  bool isParticipantAssignedInPeriod(String participantId, String periodId) {
    final assignedIds = existingAssignments[participantId];
    if (assignedIds == null) return false;

    for (final scheduledActivityId in assignedIds) {
      // Use the new, complete map to check if the assignment falls in the target period.
      if (_allScheduledActivityToPeriodMap[scheduledActivityId] == periodId) {
        return true;
      }
    }
    return false;
  }

  /// Checks if two periods occur on the same calendar day.
  ///
  /// [periodA] The first period to compare.
  /// [periodB] The second period to compare.
  ///
  /// Returns `true` if they are on the same day, `false` otherwise.
  bool isSameDay(AlgoPeriod periodA, AlgoPeriod periodB) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    return formatter.format(periodA.start) == formatter.format(periodB.start);
  }

  /// Retrieves all of a participant's existing assignments.
  List<PotentialAssignment> getAssignmentsForParticipant(String participantId) {
    final assignments = <PotentialAssignment>[];
        final participant = participants[participantId];
    if (participant == null) return assignments;

    final scheduledIds = existingAssignments[participantId] ?? [];
    for (final scheduledId in scheduledIds) {
      final scheduled = allScheduledActivities[scheduledId];
      if (scheduled == null) continue;

      final activity = allActivities[scheduled.activityId];
      final period = _allPeriodsById[scheduled.periodId];

      if (activity != null && period != null) {
          assignments.add(PotentialAssignment(
            participant: participant,
          scheduledActivity: scheduled,
            activity: activity,
          period: period,
          ));
        }
      }
    return assignments;
  }

  /// Gets the next chronological period in the week relative to the given one.
  /// Returns `null` if the given period is the last one.
  AlgoPeriod? getNextPeriod(String currentPeriodId) {
    final index = weeklyPeriodsSorted.indexWhere((p) => p.id == currentPeriodId);
    if (index == -1 || index + 1 >= weeklyPeriodsSorted.length) {
      return null;
    }
    return weeklyPeriodsSorted[index + 1];
  }

  /// Retrieves a specific scheduled activity occurring in a specific period.
  /// Returns `null` if no such activity is found.
  AlgoScheduledActivity? getScheduledActivityInPeriod(String activityId, String periodId) {
    final activitiesInPeriod = _scheduledActivitiesByPeriodId[periodId] ?? [];
    for (final scheduled in activitiesInPeriod) {
          if(scheduled.activityId == activityId) {
              return scheduled;
      }
    }
    return null;
  }

  /// Retrieves all scheduled activities occurring in a specific period.
  Iterable<AlgoScheduledActivity> getScheduledActivitiesInPeriod(String periodId) {
    return _scheduledActivitiesByPeriodId[periodId] ?? [];
}
}