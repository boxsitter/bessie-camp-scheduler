import '../evaluation/participant_evaluation_report.dart';
import '../evaluation/step_report.dart';
import 'potential_assignment.dart';

/// Represents the final output of the assignment algorithm.
///
/// This class collects all successful assignments, as well as participants
/// who could not be assigned (stalemates), providing a complete picture of
/// the algorithm's outcome.
class AssignmentResult {
  /// A list of all the successful assignments made during the run.
  final List<PotentialAssignment> successfulAssignments = [];

  /// A map of participants who could not be assigned, along with the reason.
  /// The key is a string combination of "participantId-periodId" to uniquely
  /// identify a stalemate for a participant in a specific period.
  final Map<String, String> stalemates = {};

  /// A list of all assignments that existed *before* this algorithm run.
  final List<PotentialAssignment> existingAssignments = [];

  /// A log of reports from each step of the assignment pipeline.
  final List<StepReport> reports = [];

  /// A list of evaluation reports for each participant after the run.
  List<ParticipantEvaluationReport> evaluationReports = [];

  /// Adds a step report to the result's log.
  void addReport(StepReport report) {
    reports.add(report);
  }

  /// Adds a successful assignment to the results.
  void addSuccess(PotentialAssignment assignment) {
    successfulAssignments.add(assignment);
  }

  /// Records a stalemate for a participant in a specific period.
  void addStalemate(String participantId, String periodId, String reason) {
    final key = '$participantId-$periodId';
    stalemates[key] = reason;
  }

  /// Returns all new assignments for a specific period.
  Iterable<PotentialAssignment> getAssignmentsForPeriod(String periodId) {
    return successfulAssignments.where((a) => a.period.id == periodId);
  }

  /// Returns all new assignments for a specific participant.
  Iterable<PotentialAssignment> getAssignmentsForParticipant(String participantId) {
    return successfulAssignments.where((a) => a.participant.id == participantId);
  }
}