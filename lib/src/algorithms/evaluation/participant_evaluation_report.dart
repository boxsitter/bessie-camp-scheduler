/// The evaluation results for a single participant.
class ParticipantEvaluationReport {
  final String participantId;

  /// Whether the participant's whole week avoids every veto and contains every
  /// request.
  final bool preferencesSatisfied;

  /// Schedule variety in 0..1, or `null` when the participant has no
  /// assignments at all.
  final double? noveltyScore;

  const ParticipantEvaluationReport({required this.participantId, required this.preferencesSatisfied, required this.noveltyScore});

  /// Converts the report into a list of strings for a CSV row.
  List<String> toCsvRow() {
    return [participantId, preferencesSatisfied.toString(), noveltyScore?.toStringAsFixed(3) ?? 'N/A'];
  }

  /// Generates the header row for the CSV file.
  static List<String> getCsvHeader() {
    return ['Participant ID', 'Preferences Satisfied', 'Novelty Index'];
  }
}
