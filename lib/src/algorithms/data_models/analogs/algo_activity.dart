/// A lightweight, algorithm-specific representation of an activity.
///
/// This class holds the essential details about an activity that are required
/// by the assignment algorithm, such as its capacity and assignment constraints.
class AlgoActivity {
  /// The unique identifier for the activity.
  final String id;

  /// The maximum number of participants that can be assigned to this activity
  /// in a single period.
  final int capacity;

  /// The total number of times a single participant can be assigned to this
  /// activity across all periods. A `null` value signifies no limit.
  final int? maxAssignments;

  /// A flag indicating whether this activity is part of a "double schedule,"
  /// which may have special assignment rules.
  final bool doubleSchedule;

  /// Creates an instance of [AlgoActivity].
  AlgoActivity({
    required this.id,
    required this.capacity,
    required this.maxAssignments,
    required this.doubleSchedule,
  });
}