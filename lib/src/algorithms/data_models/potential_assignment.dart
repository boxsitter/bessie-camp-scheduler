import 'analogs/algo_activity.dart';
import 'analogs/algo_participant.dart';
import 'analogs/algo_period.dart';
import 'analogs/algo_scheduled_activity.dart';

/// Represents a potential pairing of a participant with an activity.
///
/// This object is the core data structure that flows through the pipeline.
/// It can represent a single-period assignment or a double-period assignment
/// by using the optional `linked` fields.
class PotentialAssignment {
  final AlgoParticipant participant;
  final AlgoActivity activity;

  /// The scheduled activity instance for the *first* period.
  final AlgoScheduledActivity scheduledActivity;

  /// The *first* period of the assignment.
  final AlgoPeriod period;

  /// The scheduled activity instance for the *second* period, if this is a
  /// double-period assignment. Otherwise, this is null.
  final AlgoScheduledActivity? linkedScheduledActivity;

  /// The *second* period of the assignment, if this is a double-period
  /// assignment. Otherwise, this is null.
  final AlgoPeriod? linkedPeriod;

  /// The calculated score, populated during the Score step.
  double score = 0.0;

  PotentialAssignment({
    required this.participant,
    required this.activity,
    required this.scheduledActivity,
    required this.period,
    this.linkedScheduledActivity,
    this.linkedPeriod,
  }) {
    // A double assignment must have both linked fields or neither.
    // This assertion ensures data integrity.
    assert((linkedScheduledActivity == null) == (linkedPeriod == null));
}

  /// A convenience getter to determine if this represents a two-period block.
  bool get isDoubleAssignment => linkedScheduledActivity != null;
}
