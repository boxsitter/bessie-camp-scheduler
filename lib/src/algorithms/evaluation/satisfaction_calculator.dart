import 'dart:math';

import 'package:bessie/src/algorithms/evaluation/satisfaction_constants.dart';

import '../data_models/analogs/algo_participant.dart';
import '../data_models/assignment_context.dart';
import '../data_models/assignment_result.dart';
import '../data_models/potential_assignment.dart';

/// A tool to evaluate how satisfied a participant should be with their schedule.
class SatisfactionCalculator {
  /// Calculates a satisfaction index (0.0 - 1.0) for a single participant's weekly schedule.
  /// Returns null if the participant has any stalemates (unassigned blocks).
  double? calculate({
    required String participantId,
    required AssignmentContext context,
    required AssignmentResult result,
  }) {
    // ---- PRECONDITION CHECK ----
    // First, check for stalemates. If the participant has an incomplete schedule, we can't score it.
    if (result.stalemates.containsKey(participantId)) {
      return null;
    }

    final participant = context.participants[participantId];
    if (participant == null) {
      throw Exception('Participant with ID $participantId not found in the provided context.');
    }

    final participantAssignments = result.getAssignmentsForParticipant(participantId).toList();
    if (participantAssignments.isEmpty) {
      return null; // Cannot score an empty schedule.
    }

    // ---- FACTOR 1: PREFERENCE FULFILLMENT ----
    final preferenceScore = _calculatePreferenceScore(participant, participantAssignments, context);

    // ---- FACTOR 2: SCHEDULE NOVELTY ----
    final noveltyScore = _calculateNoveltyScore(participantAssignments);

    // ---- FINAL CALCULATION ----
    final preferenceWeight = SatisfactionConstants.satisfactionWeights[SatisfactionFactor.preference]!;
    final noveltyWeight = SatisfactionConstants.satisfactionWeights[SatisfactionFactor.novelty]!;

    final satisfactionIndex = (preferenceScore * preferenceWeight) + (noveltyScore * noveltyWeight);

    // Clamp the result between 0.0 and 1.0 to handle any floating point inaccuracies.
    return satisfactionIndex.clamp(0.0, 1.0);
  }

  /// Calculates the preference score, adjusted for age-based discouragement.
  double _calculatePreferenceScore(
      AlgoParticipant participant, List<PotentialAssignment> assignments, AssignmentContext context) {
    // 1. Get the age-specific discouragement multiplier for this participant.
    final discouragementMultiplier =
        calculateDiscouragementMultiplier(participant.birthdate, SatisfactionConstants.discouragementSettings);

    // 2. Calculate the total "adjusted impact" of the participant's schedule.
    double totalAdjustedImpact = 0;
    for (final assignment in assignments) {
      final preference = context.participantPreferences[participant.id]?[assignment.activity.id] ??
          SatisfactionConstants.neutralPreferencePoint;

      final rawImpact = preference - SatisfactionConstants.neutralPreferencePoint;

      if (rawImpact < 0) {
        totalAdjustedImpact += rawImpact * discouragementMultiplier; // Apply penalty
      } else {
        totalAdjustedImpact += rawImpact;
      }
    }

    // 3. Normalize the score against the theoretical best and worst possible outcomes.
    final double maxPossibleImpact =
        assignments.length * (1.0 - SatisfactionConstants.neutralPreferencePoint);
    final double minPossibleImpact = assignments.length *
        (0.0 - SatisfactionConstants.neutralPreferencePoint) *
        discouragementMultiplier;

    // Avoid division by zero if max and min are the same (e.g., only one possible outcome).
    if (maxPossibleImpact == minPossibleImpact) {
        return 0.5;
    }

    final normalizedScore = (totalAdjustedImpact - minPossibleImpact) / (maxPossibleImpact - minPossibleImpact);

    return normalizedScore;
  }

  /// Calculates the novelty score based on activity variety.
  double _calculateNoveltyScore(List<PotentialAssignment> assignments) {
    final uniqueActivityIds = assignments.map((a) => a.activity.id).toSet();
    return uniqueActivityIds.length / assignments.length;
  }

  /// Calculates an age-based discouragement multiplier.
  /// The multiplier is highest for the youngest participants and decreases linearly
  /// until it reaches 1.0 (no effect) at the `maxAge`.
  double calculateDiscouragementMultiplier(DateTime birthdate, DiscouragementSettings settings) {
    final now = DateTime.now();
    int age = now.year - birthdate.year;
    if (now.month < birthdate.month || (now.month == birthdate.month && now.day < birthdate.day)) {
      age--;
    }

    // If participant is outside the bonus age range, return the max or min multiplier.
    if (age <= settings.minAge) {
      return settings.maxMultiplier;
    }
    if (age >= settings.maxAge) {
      return 1.0; // No discouragement effect.
    }

    // Calculate the linear falloff.
    final ageRange = (settings.maxAge - settings.minAge).toDouble();
    final participantPositionInRange = (age - settings.minAge).toDouble();
    final falloffFactor = participantPositionInRange / ageRange;

    // The multiplier starts at maxMultiplier and falls off to 1.0.
    final multiplier = settings.maxMultiplier - (falloffFactor * (settings.maxMultiplier - 1.0));

    return max(1.0, multiplier);
  }
}