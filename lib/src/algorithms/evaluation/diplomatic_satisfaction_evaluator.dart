import '../data_models/assignment_context.dart';
import '../data_models/assignment_result.dart';

/// A tool to evaluate if a participant's schedule meets their explicit requests and avoids their vetoes.
class DiplomaticSatisfactionEvaluator {
  /// Checks if a participant's schedule is satisfactory based on two core diplomatic criteria:
  /// 1. They are not assigned to any vetoed activities.
  /// 2. They are assigned to every requested activity at least once.
  ///
  /// Returns `true` if both conditions are met, `false` otherwise.
  bool isSatisfied({
    required String participantId,
    required AssignmentContext context,
    required AssignmentResult result,
  }) {
    // Retrieve the participant's preferences and assignments.
    final preferences = context.participantPreferences[participantId];
    final assignments = result.getAssignmentsForParticipant(participantId);

    // If there are no preferences, we can't evaluate satisfaction.
    if (preferences == null) {
      return false;
    }

    // --- Condition 1: Check for Vetoed Activities ---
    // Iterate through all of the participant's assignments for the week.
    for (final assignment in assignments) {
      final activityId = assignment.activity.id;
      // If the preference for an assigned activity is a veto (0.0), the schedule is not satisfactory.
      if (preferences[activityId] == 0.0) {
        return false; // Vetoed activity found.
      }
    }

    // --- Condition 2: Check for Fulfilled Requests ---
    // Filter the preferences to get a list of all requested activity IDs.
    final requestedActivities = preferences.entries
        .where((entry) => entry.value == 1.0)
        .map((entry) => entry.key)
        .toSet();

    // If the participant has no requests, this condition is trivially met.
    if (requestedActivities.isEmpty) {
      return true;
    }

    // Get a set of all unique activity IDs the participant has been assigned.
    final assignedActivityIds = assignments.map((a) => a.activity.id).toSet();

    // Check if every requested activity is present in the set of assigned activities.
    // The `.difference()` method returns a set of elements in `requestedActivities`
    // that are not in `assignedActivityIds`. If this set is empty, all requests were fulfilled.
    return assignedActivityIds.containsAll(requestedActivities);
  }
}