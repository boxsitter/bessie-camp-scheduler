/// A data class to hold the evaluation results for a single participant.
class ParticipantEvaluationReport {
  final String participantId;
  final bool preferencesSatisfied;
  final double? noveltyScore;

  ParticipantEvaluationReport({
    required this.participantId,
    required this.preferencesSatisfied,
    required this.noveltyScore,
  });

  /// Converts the report into a list of strings for a CSV row.
  List<String> toCsvRow() {
    return [
      participantId,
      preferencesSatisfied.toString(),
      noveltyScore?.toStringAsFixed(3) ?? 'N/A',
    ];
  }

  /// Generates the header row for the CSV file.
  static List<String> getCsvHeader() {
    return ['Participant ID', 'Preferences Satisfied', 'Novelty Index'];
  }
}