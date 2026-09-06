
import 'dart:math';

import '../../data_models/assignment_result.dart';
import '../../data_models/enums.dart';
import '../../data_models/interfaces/Constraint.dart';
import '../../data_models/interfaces/algorithm_step.dart';
import '../../data_models/pipeline_state.dart';
import '../../data_models/potential_assignment.dart';
import '../../evaluation/step_report.dart';

/// The final step, updated to correctly handle merged double-assignments and configurable stalemates.
///
/// This step iterates through the sorted list. When it encounters a successful
/// assignment, it checks if it's a double. If so, it confirms both halves
/// and blocks both periods simultaneously. It then handles any unassigned
/// slots based on the selected StalemateStrategy.
class ProcessAssignmentsStep extends AlgorithmStep {
  final List<Constraint> constraints;
  final StalemateStrategy stalemateStrategy;

  ProcessAssignmentsStep({
    required this.constraints,
    this.stalemateStrategy = StalemateStrategy.leaveUnassigned,
    Random? random,
  });

  @override
  String get stepName => 'Process & Finalize Assignments';

  @override
  StepReport execute(PipelineState state) {
    final assignedInPeriod = _getInitialAssignments(state.result);
    int newSuccessCount = 0;

    for (final assignment in state.potentialAssignments) {
      final participantId = assignment.participant.id;

      // --- Check Primary Period ---
      if (assignedInPeriod[assignment.period.id]?.contains(participantId) ?? false) {
        continue;
      }

      // --- Handle Double Assignments ---
      if (assignment.isDoubleAssignment) {
        final linkedPeriodId = assignment.linkedPeriod!.id;

        // Check if the participant is already busy during the second period.
        if (assignedInPeriod[linkedPeriodId]?.contains(participantId) ?? false) {
          continue;
        }

        // Check constraints ONLY for the primary half of the assignment.
        final primaryViolation = _getViolationReason(assignment, state);
        if (primaryViolation != null) {
          continue;
        }

        // SUCCESS: The double assignment is valid.
        // Create the linked assignment without further checks.
        final linkedAssignment = PotentialAssignment(
          participant: assignment.participant,
          activity: assignment.activity,
          scheduledActivity: assignment.linkedScheduledActivity!,
          period: assignment.linkedPeriod!,
        );

        // Add both halves to the result.
        state.result.addSuccess(assignment);
        state.result.addSuccess(linkedAssignment);
        newSuccessCount += 2;

        // Mark the participant as assigned in both periods.
        (assignedInPeriod[assignment.period.id] ??= {}).add(participantId);
        (assignedInPeriod[linkedPeriodId] ??= {}).add(participantId);
      } else {
        // --- Handle Single Assignments ---
        if (_getViolationReason(assignment, state) != null) {
          continue;
        }

        // SUCCESS: The single assignment is valid.
        state.result.addSuccess(assignment);
        newSuccessCount++;
        (assignedInPeriod[assignment.period.id] ??= {}).add(participantId);
      }
    }

    final Map<String, String> stalemateDetails = _handleStalemates(state, assignedInPeriod);
    if (stalemateStrategy == StalemateStrategy.fail && stalemateDetails.isNotEmpty) {
      final summary = 'Algorithm failed with ${stalemateDetails.length} stalemates.';
      final details = stalemateDetails.entries.map((e) => '${e.key}: ${e.value}').join('\n\n');
      throw Exception('$summary\n\nStalemate Details:\n$details');
    }

    return StepReport(
      stepName: stepName,
      summary: 'Created $newSuccessCount new assignments. Encountered ${stalemateDetails.length} stalemates.',
      details: {
        'newlyAssignedCount': newSuccessCount,
        'stalemateCount': stalemateDetails.length,
        'stalemateStrategy': stalemateStrategy.toString().split('.').last,
      },
      duration: Duration.zero,
    );
  }

  Map<String, String> _handleStalemates(PipelineState state, Map<String, Set<String>> assignedInPeriod) {
    final stalemateDetails = <String, String>{};
    for (final participant in state.context.participants.values) {
      for (final period in state.context.targetPeriods.values) {
        if (!(assignedInPeriod[period.id]?.contains(participant.id) ?? false)) {
          final stalemateKey = 'Participant: ${participant.id}, Period: ${period.id}';
          final reason = _getStalemateReason(participant.id, period.id, state);
          stalemateDetails[stalemateKey] = reason;
          state.result.addStalemate(participant.id, period.id, reason);
        }
      }
    }
    return stalemateDetails;
  }

  String _getStalemateReason(String participantId, String periodId, PipelineState state) {
    final potentialAssignmentsForSlot = state.potentialAssignments
        .where((pa) => pa.participant.id == participantId && pa.period.id == periodId)
        .toList();

    if (potentialAssignmentsForSlot.isEmpty) {
      return 'No potential assignments were generated for this slot. The participant may have vetoed all available activities.';
    }

    final violationReasons = <String, List<String>>{};
    for (final pa in potentialAssignmentsForSlot) {
      final reasons = <String>[];
      for (final constraint in constraints) {
        if (constraint.isViolated(pa, state.context, state.result)) {
          reasons.add(constraint.violationMessage);
        }
    }
      if (reasons.isNotEmpty) {
        violationReasons[pa.activity.id] = reasons;
      }
    }

    if (violationReasons.isEmpty) {
      return 'An unknown error occurred. Potential assignments existed but none were chosen.';
    }

    final reasonDetails = violationReasons.entries
        .map((e) => 'Activity ${e.key} violated: [${e.value.join(', ')}]')
        .join('; ');

    return 'All potential assignments violated constraints: $reasonDetails';
  }

  String? _getViolationReason(
      PotentialAssignment assignment, PipelineState state) {
    for (final constraint in constraints) {
      if (constraint.isViolated(assignment, state.context, state.result)) {
        return constraint.violationMessage;
      }
    }
    return null;
  }

  Map<String, Set<String>> _getInitialAssignments(AssignmentResult result) {
    final map = <String, Set<String>>{};
    for (final success in result.successfulAssignments) {
      (map[success.period.id] ??= {}).add(success.participant.id);
    }
    return map;
  }
  }