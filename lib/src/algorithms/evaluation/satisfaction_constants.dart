/// Defines tunable constants that control the behavior of the satisfaction evaluation.
class SatisfactionConstants {
  /// Defines the weight given to each factor when calculating the final index.
  /// These values should sum to 1.0.
  static const Map<SatisfactionFactor, double> satisfactionWeights = {
    SatisfactionFactor.preference: 0.7,
    SatisfactionFactor.novelty: 0.3,
  };

  /// The preference value that is considered perfectly neutral.
  /// Values below this are considered "negative" experiences for the discouragement calculation.
  static const double neutralPreferencePoint = 0.5;

  /// Defines the settings for the age-based discouragement penalty.
  /// This makes negative experiences more impactful for younger participants.
  static final DiscouragementSettings discouragementSettings = DiscouragementSettings(
    maxMultiplier: 2.5,
    minAge: 8,
    maxAge: 13,
  );
}

/// An enum to represent the factors of satisfaction.
enum SatisfactionFactor {
  preference,
  novelty,
}

/// A data class to hold settings for the age-based discouragement model.
class DiscouragementSettings {
  /// The maximum factor by which a negative experience is amplified.
  /// Used for the youngest participants in the age range.
  final double maxMultiplier;

  /// The age at which the discouragement effect begins.
  final int minAge;

  /// The age at which the discouragement effect ends (multiplier becomes 1.0).
  final int maxAge;

  DiscouragementSettings({
    required this.maxMultiplier,
    required this.minAge,
    required this.maxAge,
  });
}