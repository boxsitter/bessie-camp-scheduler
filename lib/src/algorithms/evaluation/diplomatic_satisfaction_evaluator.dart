import '../data_models/assignment_context.dart';
import '../data_models/assignment_ledger.dart';
import '../data_models/enums.dart';

/// Evaluates whether a participant's schedule honours their explicit requests
/// and vetoes.
class DiplomaticSatisfactionEvaluator {
  /// A participant is satisfied when, over their WHOLE week (existing plus new
  /// placements):
  ///  1. they hold no vetoed activity, and
  ///  2. they hold every requested activity at least once.
  ///
  /// A participant with no preferences at all is trivially satisfied.
  bool isSatisfied({required String participantId, required AssignmentContext context, required AssignmentLedger ledger}) {
    final preferences = context.preferences[participantId];
    if (preferences == null || preferences.isEmpty) return true;

    final heldActivityIds = ledger.weekActivityIds(participantId).toSet();

    for (final entry in preferences.entries) {
      final held = heldActivityIds.contains(entry.key);
      if (entry.value == PreferenceType.veto && held) return false;
      if (entry.value == PreferenceType.request && !held) return false;
    }
    return true;
  }
}
