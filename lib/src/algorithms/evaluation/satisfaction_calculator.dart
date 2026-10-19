import 'dart:math';

import '../data_models/assignment_context.dart';
import '../data_models/assignment_ledger.dart';
import '../data_models/enums.dart';
import '../data_models/stalemate_log.dart';
import 'satisfaction_constants.dart';

/// Evaluates how satisfied a participant should be with their week.
///
/// The index is `0.7 * preference + 0.3 * novelty` (see
/// [SatisfactionConstants]), evaluated over the participant's WHOLE week:
/// existing plus new placements, one entry per filled period (a double block
/// counts once per period).
class SatisfactionCalculator {
  /// The satisfaction index (0.0 - 1.0) of a participant's week, or `null` if
  /// the participant has any stalemate (an incomplete schedule cannot be
  /// scored) or no assignments at all.
  ///
  /// Ages come from `context.now`; the system clock is never read.
  double? calculate({
    required String participantId,
    required AssignmentContext context,
    required AssignmentLedger ledger,
    required StalemateLog stalemates,
  }) {
    if (stalemates.hasStalemate(participantId)) return null;

    if (context.participantById(participantId) == null) {
      throw ArgumentError.value(
          participantId, 'participantId', 'is not part of the context');
    }

    final activityIds = ledger.weekActivityIds(participantId).toList();
    if (activityIds.isEmpty) return null;

    final multiplier = calculateDiscouragementMultiplier(
      age: context.ageOf(participantId),
      settings: SatisfactionConstants.discouragementSettings,
    );
    final preferenceScore =
        calculatePreferenceScore(participantId, activityIds, context, multiplier);
    final noveltyScore = calculateNoveltyScore(activityIds);

    final weights = SatisfactionConstants.satisfactionWeights;
    final index = preferenceScore * weights[SatisfactionFactor.preference]! +
        noveltyScore * weights[SatisfactionFactor.novelty]!;

    // Clamp to absorb floating point inaccuracies.
    return index.clamp(0.0, 1.0);
  }

  /// The preference score in 0..1 for the given placements (one activity id per
  /// period), adjusted for age-based discouragement and normalised against the
  /// best and worst outcome possible for that many placements.
  double calculatePreferenceScore(
    String participantId,
    List<String> activityIds,
    AssignmentContext context,
    double discouragementMultiplier,
  ) {
    const neutral = SatisfactionConstants.neutralPreferencePoint;

    var totalAdjustedImpact = 0.0;
    for (final activityId in activityIds) {
      final preference = context.preferenceOf(participantId, activityId).numericValue;
      final rawImpact = preference - neutral;
      totalAdjustedImpact +=
          rawImpact < 0 ? rawImpact * discouragementMultiplier : rawImpact;
    }

    final maxPossibleImpact = activityIds.length * (1.0 - neutral);
    final minPossibleImpact =
        activityIds.length * (0.0 - neutral) * discouragementMultiplier;

    // Nothing to normalise against (only possible without placements).
    if (maxPossibleImpact == minPossibleImpact) return 0.5;

    return (totalAdjustedImpact - minPossibleImpact) /
        (maxPossibleImpact - minPossibleImpact);
  }

  /// Unique activities divided by placements, in 0..1.
  double calculateNoveltyScore(List<String> activityIds) =>
      activityIds.toSet().length / activityIds.length;

  /// The factor by which negative experiences are amplified for a participant
  /// of the given [age]: [DiscouragementSettings.maxMultiplier] at or below
  /// `minAge`, falling linearly to 1.0 (no effect) at `maxAge`.
  double calculateDiscouragementMultiplier({
    required int age,
    required DiscouragementSettings settings,
  }) {
    if (age <= settings.minAge) return settings.maxMultiplier;
    if (age >= settings.maxAge) return 1.0;

    final range = (settings.maxAge - settings.minAge).toDouble();
    final falloff = (age - settings.minAge) / range;
    final multiplier =
        settings.maxMultiplier - falloff * (settings.maxMultiplier - 1.0);
    return max(1.0, multiplier);
  }
}
