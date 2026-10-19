import 'dart:math';

import '../../data_models/assignment_context.dart';
import '../../data_models/assignment_ledger.dart';
import '../../data_models/potential_assignment.dart';

/// The building blocks shared by every scorer. All of them are pure functions
/// of their arguments.
class ScoringTerms {
  ScoringTerms._();

  /// The base penalty for repeating an activity on the same day.
  static const double baseRepetitionPenalty = -50.0;

  /// How quickly the repetition penalty fades with each period of separation.
  static const double repetitionPenaltyDecayFactor = 0.6;

  /// The age at (or below) which the full age bonus applies.
  static const int youngerParticipantMinAge = 8;

  /// The age at (or above) which the age bonus is zero.
  static const int youngerParticipantMaxAge = 13;

  /// A linear age bonus: [maxBonus] at or below [minAge], falling linearly to
  /// zero at [maxAge].
  static double ageBonus(
    int age, {
    required double maxBonus,
    int minAge = youngerParticipantMinAge,
    int maxAge = youngerParticipantMaxAge,
  }) {
    if (age <= minAge) return maxBonus;
    if (age >= maxAge) return 0.0;
    final position = (age - minAge) / (maxAge - minAge);
    return max(0.0, maxBonus * (1 - position));
  }

  /// The same-day repetition penalty for [candidate] given what the ledger
  /// already holds (existing assignments and earlier placements alike).
  ///
  /// Every other assignment of the same activity on the same day contributes
  /// `-50 * 0.6^distance`, where distance is the number of periods strictly
  /// between the two assignments. For a double block the distance is measured
  /// to its nearest period. The result only ever becomes more negative as
  /// assignments are added.
  static double sameDayRepetitionPenalty(
    PotentialAssignment candidate,
    AssignmentContext context,
    AssignmentLedger ledger,
  ) {
    final held = ledger.periodIndicesOf(
      candidate.participant.id,
      candidate.activity.id,
    );
    if (held.isEmpty) return 0.0;

    final dayId = candidate.period.dayId;
    final firstIndex = context.periodIndex(candidate.period.id);
    final linked = candidate.linkedPeriod;
    final secondIndex =
        linked == null ? firstIndex : context.periodIndex(linked.id);

    var penalty = 0.0;
    for (final heldIndex in held) {
      if (context.periods[heldIndex].dayId != dayId) continue;
      final gap = min(
        (heldIndex - firstIndex).abs(),
        (heldIndex - secondIndex).abs(),
      );
      final distance = max(0, gap - 1);
      penalty +=
          baseRepetitionPenalty * pow(repetitionPenaltyDecayFactor, distance);
    }
    return penalty;
  }
}
