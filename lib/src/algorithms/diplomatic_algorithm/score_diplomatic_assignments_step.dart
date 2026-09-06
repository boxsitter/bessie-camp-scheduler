import 'dart:math';

import '../data_models/analogs/algo_period.dart';
import '../data_models/assignment_context.dart';
import '../data_models/assignment_result.dart';
import '../data_models/enums.dart';
import '../data_models/interfaces/algorithm_step.dart';
import '../data_models/pipeline_state.dart';
import '../data_models/potential_assignment.dart';
import '../evaluation/step_report.dart';

/// Scores assignments based on a tiered priority system.
///
/// This step implements a multi-tiered scoring logic that prioritizes
/// unfulfilled requests, then novel activities, and finally repeated activities,
/// using age and repetition as tie-breakers.
class ScoreDiplomaticAssignmentsStep extends AlgorithmStep {
  // --- TIER SCORES ---
  /// The highest score, for an activity a camper has requested but not yet received.
  static const double unfulfilledRequestScore = 1000.0;

  /// A high score for a new, non-requested activity.
  static const double novelActivityScore = 500.0;

  /// The base score for a flexible activity that has already been assigned.
  static const double repeatedActivityScore = 10.0;

  // --- TIE-BREAKER BONUSES & PENALTIES ---
  /// The maximum bonus a younger camper can receive to break ties within a tier.
  static const double youngerParticipantMaxBonus = 0.0;

  /// The age at which the bonus starts to apply.
  static const int youngerParticipantMinAge = 8;

  /// The age at which the bonus becomes zero.
  static const int youngerParticipantMaxAge = 13;

  /// The base penalty for repeating an activity on the same day.
  static const double baseRepetitionPenalty = -50.0;

  /// How quickly the repetition penalty fades with each period of separation.
  static const double repetitionPenaltyDecayFactor = 0.6;

  @override
  String get stepName => 'Score Diplomatic Assignments';

  @override
  StepReport execute(PipelineState state) {
    // --- REMOVE THESE LINES ---
    // final fulfilledRequests = <String, Set<String>>{};
    // final assignedActivities = <String, Set<String>>{};

    for (final potentialAssignment in state.potentialAssignments) {
      potentialAssignment.score = _calculateScore(
        potentialAssignment,
        state, // --- PASS THE ENTIRE STATE ---
      );
    }

    return StepReport(
      stepName: stepName,
      summary: 'Calculated tiered scores for ${state.potentialAssignments.length} assignments.',
      details: {'count': state.potentialAssignments.length},
      duration: Duration.zero,
    );
  }

  /// Calculates the score for a single potential assignment using a tiered system.
  double _calculateScore(
    PotentialAssignment assignment,
    PipelineState state, // --- USE THE PIPELINE STATE ---
  ) {
    final participantId = assignment.participant.id;
    final activityId = assignment.activity.id;

    // --- USE THE STATE MAPS ---
    final fulfilledRequests = state.fulfilledRequests;
    final assignedActivities = state.assignedActivities;

    final preferenceValue = state.context.participantPreferences[participantId]?[activityId];
    final preferenceType = _getPreferenceType(preferenceValue);

    // Determine the base score from the tier system.
    double baseScore;
    final isNewActivity = !(assignedActivities[participantId]?.contains(activityId) ?? false);

    // Tier 1: Is this an unfulfilled request?
    if (preferenceType == PreferenceType.request && !(fulfilledRequests[participantId]?.contains(activityId) ?? false)) {
      baseScore = unfulfilledRequestScore;
      // Mark it as fulfilled and assigned for the rest of the scoring run.
      (fulfilledRequests[participantId] ??= {}).add(activityId);
      (assignedActivities[participantId] ??= {}).add(activityId);
    }
    // Tier 2: Is this a new, flexible choice?
    else if (isNewActivity) {
      baseScore = novelActivityScore;
      (assignedActivities[participantId] ??= {}).add(activityId);
    }
    // Tier 3: It must be a repeated, flexible choice.
    else {
      baseScore = repeatedActivityScore;
    }

    // Add tie-breaker scores.
    final ageBonus = _calculateAgeBonus(assignment.participant.birthdate);
    final repetitionPenalty = _getRepetitionPenalty(assignment, state.context, state.result);

    return baseScore + ageBonus + repetitionPenalty;
  }

  /// Calculates an age-based bonus using a linear sliding scale.
  double _calculateAgeBonus(DateTime birthdate) {
    final now = DateTime.now();
    int age = now.year - birthdate.year;
    if (now.month < birthdate.month || (now.month == birthdate.month && now.day < birthdate.day)) {
      age--;
    }

    if (age <= youngerParticipantMinAge) return youngerParticipantMaxBonus;
    if (age >= youngerParticipantMaxAge) return 0.0;

    final ageRange = (youngerParticipantMaxAge - youngerParticipantMinAge).toDouble();
    final participantPositionInRange = (age - youngerParticipantMinAge).toDouble();
    final bonus = youngerParticipantMaxBonus * (1 - (participantPositionInRange / ageRange));
    return max(0.0, bonus);
  }

  /// Applies a penalty for same-day activity repetitions.
  double _getRepetitionPenalty(PotentialAssignment currentAssignment, AssignmentContext context, AssignmentResult result) {
    double totalPenalty = 0.0;
    final participantId = currentAssignment.participant.id;
    final activityId = currentAssignment.activity.id;

    // Check against all assignments made so far.
    final allAssignments = [
      ...context.getAssignmentsForParticipant(participantId),
      ...result.getAssignmentsForParticipant(participantId),
    ];

    for (final otherAssignment in allAssignments) {
      if (otherAssignment.activity.id == activityId) {
        final distance = _calculatePeriodDistance(currentAssignment.period, otherAssignment.period, context.weeklyPeriodsSorted);

        if (distance != -1) {
          // Same day
          final decay = pow(repetitionPenaltyDecayFactor, distance);
          totalPenalty += (baseRepetitionPenalty * decay);
        }
      }
    }
    return totalPenalty;
  }

  /// Converts a nullable double preference value into a concrete PreferenceType.
  PreferenceType _getPreferenceType(double? preference) {
    if (preference == 1.0) return PreferenceType.request;
    if (preference == 0.0) return PreferenceType.veto;
    return PreferenceType.flexible;
  }

  /// Calculates the number of periods between two assignments on the same day.
  int _calculatePeriodDistance(AlgoPeriod periodA, AlgoPeriod periodB, List<AlgoPeriod> weeklyPeriodsSorted) {
    // Note: A more robust solution would be to use a date library for this.
    final dayA = DateTime(periodA.start.year, periodA.start.month, periodA.start.day);
    final dayB = DateTime(periodB.start.year, periodB.start.month, periodB.start.day);

    if (dayA != dayB) return -1; // -1 signifies different days

    final indexA = weeklyPeriodsSorted.indexWhere((p) => p.id == periodA.id);
    final indexB = weeklyPeriodsSorted.indexWhere((p) => p.id == periodB.id);

    if (indexA == -1 || indexB == -1) return -1;

    // The distance is the number of periods *between* the two.
    return (indexA - indexB).abs() - 1;
  }
}
