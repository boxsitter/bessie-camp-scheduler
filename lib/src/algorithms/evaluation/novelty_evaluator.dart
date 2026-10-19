import '../data_models/assignment_ledger.dart';

/// Evaluates the variety of a participant's schedule.
class NoveltyEvaluator {
  /// A novelty score (0.0 to 1.0) over the participant's WHOLE week (existing
  /// plus new placements, one entry per filled period).
  ///
  /// - 1.0: every assignment is a different activity (or there is only one
  ///   assignment, so there is nothing to repeat).
  /// - 0.0: the very same activity in every period.
  /// - `null`: the participant has no assignments to evaluate.
  double? calculateNoveltyPercentage({required String participantId, required AssignmentLedger ledger}) {
    final activityIds = ledger.weekActivityIds(participantId).toList();

    if (activityIds.isEmpty) return null;
    if (activityIds.length == 1) return 1.0;

    final unique = activityIds.toSet().length;
    // 0.0 when all activities are the same, 1.0 when all are different.
    final score = (unique - 1) / (activityIds.length - 1);
    return score.clamp(0.0, 1.0);
  }
}
