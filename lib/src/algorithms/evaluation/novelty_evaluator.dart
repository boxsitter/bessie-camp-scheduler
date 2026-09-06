import '../data_models/assignment_result.dart';

/// A tool to evaluate the novelty or variety of a participant's schedule.
class NoveltyEvaluator {
  /// Calculates a novelty score (0.0 to 1.0) based on the variety of activities
  /// in a participant's schedule.
  ///
  /// - A score of 1.0 means every assigned activity is unique.
  /// - A score of 0.0 means the participant was assigned the exact same
  ///   activity for every period.
  /// - Returns null if the participant has no assignments to evaluate.
  double? calculateNoveltyPercentage({
    required String participantId,
    required AssignmentResult result,
  }) {
    // Get all successful assignments for the specified participant.
    final assignments = result.getAssignmentsForParticipant(participantId).toList();

    // Cannot calculate novelty for an empty or single-item schedule.
    if (assignments.length <= 1) {
      return 1.0;
    }

    // Create a set of unique activity IDs from the participant's assignments.
    // A 'Set' automatically handles uniqueness.
    final uniqueActivityIds = assignments.map((a) => a.activity.id).toSet();

    // If there is only one unique activity, novelty is 0.0 as per the requirements.
    if (uniqueActivityIds.length == 1) {
      return 0.0;
    }

    // This normalization formula ensures that the score is 0.0 when all activities are the same
    // and 1.0 when all activities are different.
    final double score = (uniqueActivityIds.length - 1) / (assignments.length - 1);

    // Clamp the result between 0.0 and 1.0 to handle any floating point inaccuracies.
    return score.clamp(0.0, 1.0);
  }
}