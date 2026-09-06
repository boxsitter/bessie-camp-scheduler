/// A lightweight, algorithm-specific representation of a time period.
///
/// This class defines a specific time slot during which activities are scheduled.
class AlgoPeriod {
  /// The unique identifier for the period.
  final String id;

  /// The start date and time of the period.
  final DateTime start;

  /// Creates an instance of [AlgoPeriod].
  AlgoPeriod({
    required this.id,
    required this.start,
  });
}
