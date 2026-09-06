import 'assignment_context.dart';
import 'assignment_result.dart';
import 'potential_assignment.dart';

/// A container for the shared state that is passed through the algorithm pipeline.
///
/// Each [AlgorithmStep] can read from and write to this state, allowing data
/// to be built up and transformed progressively through the run.
class PipelineState {
  final AssignmentContext context;
  final AssignmentResult result;
  List<PotentialAssignment> potentialAssignments;

  // --- ADD THESE LINES ---
  /// A map of participant IDs to a set of activity IDs that they have requested
  /// and have been fulfilled.
  final Map<String, Set<String>> fulfilledRequests;

  /// A map of participant IDs to a set of all activity IDs they have been
  /// assigned during this run.
  final Map<String, Set<String>> assignedActivities;

  PipelineState({
    required this.context,
    required this.result,
    this.potentialAssignments = const [],
    // --- ADD THESE LINES ---
    this.fulfilledRequests = const {},
    this.assignedActivities = const {},
  });
}