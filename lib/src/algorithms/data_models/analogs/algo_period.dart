/// A lightweight, engine-specific representation of a time slot.
class AlgoPeriod {
  /// The unique identifier of the period.
  final String id;

  /// Identifies the calendar day the period belongs to. Two periods are on the
  /// same day if and only if their [dayId]s are equal (the engine never
  /// formats or compares dates for this).
  final String dayId;

  /// When the period starts. Periods are ordered chronologically by this value.
  final DateTime start;

  const AlgoPeriod({required this.id, required this.dayId, required this.start});

  @override
  String toString() => 'AlgoPeriod($id)';
}
