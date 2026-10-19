import '../common/scoring/scoring_terms.dart';
import '../data_models/assignment_context.dart';
import '../data_models/assignment_ledger.dart';
import '../data_models/enums.dart';
import '../data_models/interfaces/assignment_scorer.dart';
import '../data_models/potential_assignment.dart';

/// The diplomatic scorer: a tiered priority system.
///
///  1. **Tier 1**: a request the participant has not received yet (1000).
///  2. **Tier 2**: an activity the participant has not been assigned yet this
///     run/week (500).
///  3. **Tier 3**: a repeat (10).
///
/// then the same-day repetition penalty and an age bonus (effectively
/// disabled: its maximum is 0.0).
///
/// "Has been assigned" is read from the ledger, so existing assignments of the
/// week count. The score is a pure function of the candidate and the ledger:
/// every candidate for the same (participant, activity) is judged by the same
/// rules, whichever period it is in. Scores only ever decrease as assignments
/// are made (a fulfilled request drops from 1000, a no-longer-novel activity
/// from 500, penalties grow).
class DiplomaticScorer implements AssignmentScorer {
  const DiplomaticScorer();

  // --- TIER SCORES ---
  /// The highest score, for an activity a camper has requested but not yet
  /// received.
  static const double unfulfilledRequestScore = 1000.0;

  /// A high score for a new, non-requested activity.
  static const double novelActivityScore = 500.0;

  /// The base score for an activity the participant already holds.
  static const double repeatedActivityScore = 10.0;

  // --- TIE-BREAKER BONUSES ---
  /// The maximum bonus a younger camper can receive to break ties within a
  /// tier. Kept at 0.0: the age bonus is effectively disabled.
  static const double youngerParticipantMaxBonus = 0.0;

  /// The age at which the bonus starts to apply.
  static const int youngerParticipantMinAge = ScoringTerms.youngerParticipantMinAge;

  /// The age at which the bonus becomes zero.
  static const int youngerParticipantMaxAge = ScoringTerms.youngerParticipantMaxAge;

  // --- REPETITION PENALTY ---
  /// The base penalty for repeating an activity on the same day.
  static const double baseRepetitionPenalty = ScoringTerms.baseRepetitionPenalty;

  /// How quickly the repetition penalty fades with each period of separation.
  static const double repetitionPenaltyDecayFactor =
      ScoringTerms.repetitionPenaltyDecayFactor;

  @override
  String get name => 'diplomatic';

  @override
  double score(
    PotentialAssignment candidate,
    AssignmentContext context,
    AssignmentLedger ledger,
  ) {
    final participantId = candidate.participant.id;
    final activityId = candidate.activity.id;

    final alreadyHolds = ledger.holds(participantId, activityId);
    final isRequest =
        context.preferenceOf(participantId, activityId) == PreferenceType.request;

    final double baseScore;
    if (!alreadyHolds && isRequest) {
      baseScore = unfulfilledRequestScore; // Tier 1
    } else if (!alreadyHolds) {
      baseScore = novelActivityScore; // Tier 2
    } else {
      baseScore = repeatedActivityScore; // Tier 3
    }

    final ageBonus = ScoringTerms.ageBonus(
      context.ageOf(participantId),
      maxBonus: youngerParticipantMaxBonus,
    );
    final repetitionPenalty =
        ScoringTerms.sameDayRepetitionPenalty(candidate, context, ledger);

    return baseScore + ageBonus + repetitionPenalty;
  }
}
