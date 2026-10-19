/// A lightweight, engine-specific representation of an activity.
class AlgoActivity {
  /// The unique identifier of the activity.
  final String id;

  /// The number of seats available in *each scheduled instance* of this
  /// activity (that is, per period in which it is offered).
  final int capacity;

  /// The number of times one participant may be assigned to this activity in
  /// the whole week. A double-schedule block counts as ONE occurrence.
  /// `null` means unlimited.
  final int? maxAssignments;

  /// Whether the activity occupies two consecutive periods on the same day.
  final bool doubleSchedule;

  /// `false` marks a hidden activity: it keeps participants busy and holds
  /// seats when it appears in existing assignments, but the engine never
  /// proposes it as a new assignment.
  final bool assignable;

  const AlgoActivity({
    required this.id,
    required this.capacity,
    this.maxAssignments,
    this.doubleSchedule = false,
    this.assignable = true,
  });

  @override
  String toString() => 'AlgoActivity($id)';
}
