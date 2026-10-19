import '../evaluation/participant_evaluation_report.dart';
import 'assignment_context.dart';
import 'assignment_ledger.dart';
import 'potential_assignment.dart';
import 'stalemate_log.dart';

/// The shared, mutable state that flows through the pipeline.
///
/// Steps read what earlier steps produced and add their own output. The only
/// record of who holds what is the [ledger]; there is no second copy.
class PipelineState {
  final AssignmentContext context;

  /// Who holds which seat: existing assignments plus everything placed so far.
  final AssignmentLedger ledger;

  /// The candidates produced by the generate step, then scored and sorted by
  /// the following steps.
  List<PotentialAssignment> potentialAssignments = [];

  /// The slots that could not be filled.
  final StalemateLog stalemates = StalemateLog();

  /// participantId -> satisfaction, filled by the evaluation step.
  final Map<String, double> satisfaction = {};

  /// Per-participant evaluation reports, filled by the evaluation step.
  List<ParticipantEvaluationReport> evaluationReports = [];

  PipelineState({required this.context, required this.ledger});
}
