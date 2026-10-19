/// Tunable constants that control the satisfaction evaluation.
class SatisfactionConstants {
  SatisfactionConstants._();

  /// The weight given to each factor when calculating the final index.
  /// These values should sum to 1.0.
  static const Map<SatisfactionFactor, double> satisfactionWeights = {SatisfactionFactor.preference: 0.7, SatisfactionFactor.novelty: 0.3};

  /// The preference value that is considered perfectly neutral.
  /// Values below this are "negative" experiences for the discouragement
  /// calculation.
  static const double neutralPreferencePoint = 0.5;

  /// Settings for the age-based discouragement penalty, which makes negative
  /// experiences more impactful for younger participants.
  static const DiscouragementSettings discouragementSettings = DiscouragementSettings(maxMultiplier: 2.5, minAge: 8, maxAge: 13);
}

/// The factors that make up a satisfaction index.
enum SatisfactionFactor { preference, novelty }

/// Settings for the age-based discouragement model.
class DiscouragementSettings {
  /// The maximum factor by which a negative experience is amplified, applied
  /// to participants at or below [minAge].
  final double maxMultiplier;

  /// The age at (or below) which the full [maxMultiplier] applies.
  final int minAge;

  /// The age at (or above) which the multiplier is 1.0 (no effect).
  final int maxAge;

  const DiscouragementSettings({required this.maxMultiplier, required this.minAge, required this.maxAge});
}
