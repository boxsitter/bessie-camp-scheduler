/// Represents a specific instance of an activity scheduled in a particular period.
///
/// This links an [AlgoActivity] to an [AlgoPeriod], creating a concrete event
/// to which participants can be assigned.
class AlgoScheduledActivity {
  /// A unique identifier for this specific scheduled instance of an activity.
  final String id;

  /// The ID of the [AlgoActivity] being scheduled.
  final String activityId;

  /// The ID of the [AlgoPeriod] in which this activity is scheduled.
  final String periodId;

  /// Creates an instance of [AlgoScheduledActivity].
  AlgoScheduledActivity({
    required this.id,
    required this.activityId,
    required this.periodId,
  });
}