import '../evaluation/participant_evaluation_report.dart';
import '../evaluation/step_report.dart';

/// One participant placed into one scheduled activity (hence one period).
/// A double-schedule assignment yields two of these.
class NewPlacement {
  final String participantId;
  final String scheduledActivityId;

  const NewPlacement({
    required this.participantId,
    required this.scheduledActivityId,
  });

  @override
  bool operator ==(Object other) =>
      other is NewPlacement &&
      other.participantId == participantId &&
      other.scheduledActivityId == scheduledActivityId;

  @override
  int get hashCode => Object.hash(participantId, scheduledActivityId);

  @override
  String toString() => '$participantId -> $scheduledActivityId';
}

/// A (participant, period) slot the engine could not fill.
class Stalemate {
  final String participantId;
  final String periodId;

  /// A human-readable explanation of why every option was ruled out.
  final String reason;

  const Stalemate({
    required this.participantId,
    required this.periodId,
    required this.reason,
  });

  @override
  String toString() => '$participantId @ $periodId: $reason';
}

/// The immutable outcome of an engine run.
class AssignmentResult {
  /// ONLY the placements this run added (never the existing assignments), in
  /// the order they were made.
  final List<NewPlacement> newPlacements;

  /// participantId -> satisfaction in 0..1 over the participant's whole week
  /// (existing + new). Participants with a stalemate or no assignments at all
  /// are omitted.
  final Map<String, double> satisfaction;

  /// Every slot that could not be filled.
  final List<Stalemate> stalemates;

  /// One evaluation report per participant of the run.
  final List<ParticipantEvaluationReport> evaluationReports;

  /// One timed report per executed pipeline step.
  final List<StepReport> stepReports;

  final Set<String> _stalematedParticipantIds;

  AssignmentResult({
    required List<NewPlacement> newPlacements,
    Map<String, double> satisfaction = const {},
    List<Stalemate> stalemates = const [],
    List<ParticipantEvaluationReport> evaluationReports = const [],
    List<StepReport> stepReports = const [],
  })  : newPlacements = List.unmodifiable(newPlacements),
        satisfaction = Map.unmodifiable(satisfaction),
        stalemates = List.unmodifiable(stalemates),
        evaluationReports = List.unmodifiable(evaluationReports),
        stepReports = List.unmodifiable(stepReports),
        _stalematedParticipantIds = {for (final s in stalemates) s.participantId};

  /// Whether any of the participant's slots is a stalemate. O(1).
  bool hasStalemate(String participantId) =>
      _stalematedParticipantIds.contains(participantId);
}
