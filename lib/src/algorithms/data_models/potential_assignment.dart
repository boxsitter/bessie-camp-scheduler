import 'analogs/algo_activity.dart';
import 'analogs/algo_participant.dart';
import 'analogs/algo_period.dart';
import 'analogs/algo_scheduled_activity.dart';

/// A candidate pairing of a participant with an activity: the unit the
/// pipeline scores, ranks and finally accepts or rejects.
///
/// A single-period candidate has only the primary fields. A double-schedule
/// candidate is ONE object representing the whole two-period block: the
/// `linked*` fields describe its second half, and it is accepted or rejected
/// as a unit.
class PotentialAssignment {
  final AlgoParticipant participant;
  final AlgoActivity activity;

  /// The scheduled instance for the *first* period.
  final AlgoScheduledActivity scheduledActivity;

  /// The *first* period.
  final AlgoPeriod period;

  /// The scheduled instance for the *second* period of a double block, or
  /// `null` for a single-period candidate.
  final AlgoScheduledActivity? linkedScheduledActivity;

  /// The *second* period of a double block, or `null`.
  final AlgoPeriod? linkedPeriod;

  /// The position of this candidate in generation order. It is the final,
  /// deterministic tiebreaker of the priority order.
  final int sequence;

  /// The latest score computed by the scorer. Scores only ever decrease as
  /// assignments are made, which is what makes the lazy-greedy selection exact.
  double score = 0.0;

  /// A random key drawn once per candidate by the sort step; breaks score ties
  /// (lower wins).
  double tiebreak = 0.0;

  PotentialAssignment({
    required this.participant,
    required this.activity,
    required this.scheduledActivity,
    required this.period,
    this.linkedScheduledActivity,
    this.linkedPeriod,
    this.sequence = 0,
  }) : assert((linkedScheduledActivity == null) == (linkedPeriod == null),
            'A double block needs both linked fields, or neither.');

  /// Whether this represents a two-period block.
  bool get isDoubleAssignment => linkedScheduledActivity != null;

  /// The scheduled instances this candidate would occupy: one, or two for a
  /// double block (primary first).
  List<AlgoScheduledActivity> get scheduledActivities => [
        scheduledActivity,
        if (linkedScheduledActivity != null) linkedScheduledActivity!,
      ];

  /// The periods this candidate would occupy: one, or two for a double block
  /// (primary first).
  List<AlgoPeriod> get periods => [
        period,
        if (linkedPeriod != null) linkedPeriod!,
      ];

  /// The priority order of the greedy selection: higher score first, then the
  /// lower random [tiebreak], then generation [sequence]. A strict total order.
  static int byPriority(PotentialAssignment a, PotentialAssignment b) {
    if (a.score > b.score) return -1;
    if (a.score < b.score) return 1;
    final byTiebreak = a.tiebreak.compareTo(b.tiebreak);
    if (byTiebreak != 0) return byTiebreak;
    return a.sequence.compareTo(b.sequence);
  }

  @override
  String toString() =>
      'PotentialAssignment(${participant.id} -> ${scheduledActivity.id}'
      '${linkedScheduledActivity != null ? ' + ${linkedScheduledActivity!.id}' : ''}'
      ', score: $score)';
}
