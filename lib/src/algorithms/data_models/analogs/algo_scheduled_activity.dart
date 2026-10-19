/// A specific instance of an activity offered in a particular period: the
/// concrete event participants are placed into.
class AlgoScheduledActivity {
  /// The unique identifier of this scheduled instance.
  final String id;

  /// The activity being offered.
  final String activityId;

  /// The period in which it is offered.
  final String periodId;

  const AlgoScheduledActivity({
    required this.id,
    required this.activityId,
    required this.periodId,
  });

  @override
  String toString() => 'AlgoScheduledActivity($id)';
}
