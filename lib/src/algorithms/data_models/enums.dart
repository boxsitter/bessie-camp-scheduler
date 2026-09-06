enum PreferenceType {
  /// The participant has explicitly requested this activity.
  request,

  /// The participant has vetoed this activity and should not be assigned.
  veto,

  /// The participant has no strong preference.
  flexible,
}

/// Defines the possible ways to handle cases where no valid assignment can be found.
enum StalemateStrategy {
  /// Leave the participant unassigned for the period (default).
  leaveUnassigned,

  /// Throw an exception, halting the process.
  fail,

  /// Assign the participant to a random, non-vetoed, available activity.
  randomize,
}