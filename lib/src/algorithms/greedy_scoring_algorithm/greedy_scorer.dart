import '../common/scoring/scoring_terms.dart';
import '../data_models/assignment_context.dart';
import '../data_models/assignment_ledger.dart';
import '../data_models/enums.dart';
import '../data_models/interfaces/assignment_scorer.dart';
import '../data_models/potential_assignment.dart';

/// The greedy scorer: preference tiers plus an age bonus, minus the same-day
/// repetition penalty.
///
/// The preference tiers read the numeric value of the preference (request 1.0,
/// neutral 0.5, veto 0.0):
/// `>= 0.9` +100 (golden ticket), `>= 0.7` +50, `>= 0.3` +10, `>= 0.1` -20,
/// anything lower -1000. With request / veto / neutral as the only inputs that
/// is request +100, neutral +10 and veto -1000 (vetoed activities are never
/// proposed in the first place).
///
/// Unlike the diplomatic scorer it has no notion of novelty: the preference
/// bonus does not change as assignments are made, only the repetition penalty
/// does, so scores are still non-increasing over time.
class GreedyScorer implements AssignmentScorer {
  const GreedyScorer();

  // --- Preference tiers ---
  /// The score for a participant's most desired activities ("golden ticket").
  static const double goldenTicketBonus = 100.0;

  /// The score for activities a participant is highly interested in.
  static const double highInterestBonus = 50.0;

  /// The score for activities a participant is neutral or curious about.
  static const double flexibleChoiceBonus = 10.0;

  /// The penalty for activities a participant has low interest in.
  static const double lowInterestPenalty = -20.0;

  /// A penalty so severe it effectively blocks an assignment.
  static const double hardNoPenalty = -1000.0;

  // --- Age bonus ---
  /// The maximum bonus a participant can receive based on their age.
  static const double youngerParticipantMaxBonus = 20.0;

  /// The age at which participants start receiving the age bonus.
  static const int youngerParticipantMinAge = ScoringTerms.youngerParticipantMinAge;

  /// The age at which the age bonus becomes zero.
  static const int youngerParticipantMaxAge = ScoringTerms.youngerParticipantMaxAge;

  @override
  String get name => 'greedy';

  @override
  double score(PotentialAssignment candidate, AssignmentContext context, AssignmentLedger ledger) {
    final participantId = candidate.participant.id;
    final preference = context.preferenceOf(participantId, candidate.activity.id);

    return preferenceBonus(preference.numericValue) +
        ScoringTerms.ageBonus(context.ageOf(participantId), maxBonus: youngerParticipantMaxBonus) +
        ScoringTerms.sameDayRepetitionPenalty(candidate, context, ledger);
  }

  /// The bonus (or penalty) for a numeric preference value in 0..1.
  static double preferenceBonus(double preference) {
    if (preference >= 0.9) return goldenTicketBonus;
    if (preference >= 0.7) return highInterestBonus;
    if (preference >= 0.3) return flexibleChoiceBonus;
    if (preference >= 0.1) return lowInterestPenalty;
    return hardNoPenalty;
  }
}
