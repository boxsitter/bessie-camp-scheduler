import '../evaluation/satisfaction_constants.dart';

/// A participant's explicit opinion about an activity.
///
/// *Neutral* is not a value of this enum: it is the absence of an entry in the
/// preferences map of the [AssignmentContext].
enum PreferenceType {
  /// The participant has explicitly requested this activity.
  request,

  /// The participant has vetoed this activity and must never be assigned to it.
  veto,
}

/// Defines how the engine handles (participant, period) slots for which no
/// valid assignment could be found by the main pass.
enum StalemateStrategy {
  /// Leave the slot empty and record a stalemate (default).
  leaveUnassigned,

  /// Throw an [AssignmentStalemateException] carrying every stalemate.
  fail,

  /// Try the participant's non-vetoed activities in random order, relaxing
  /// every constraint except capacity (and double-schedule feasibility), and
  /// record a stalemate only if that is impossible as well.
  randomize,
}

/// The scoring strategy used to rank candidate assignments.
enum AssignmentStrategy {
  /// Tiered scoring: unfulfilled requests, then novel activities, then repeats.
  diplomatic,

  /// Preference-tier scoring: golden ticket / high / flexible bonuses plus an
  /// age bonus, minus the same-day repetition penalty.
  greedy,
}

/// The numeric reading of a (possibly absent) preference, shared by scorers
/// and evaluators: request = 1.0, veto = 0.0, neutral (`null`) = 0.5.
extension PreferenceTypeValue on PreferenceType? {
  double get numericValue => switch (this) {
        PreferenceType.request => 1.0,
        PreferenceType.veto => 0.0,
        null => SatisfactionConstants.neutralPreferencePoint,
      };
}
