import '../../../algorithms/evaluation/participant_evaluation_report.dart';
import 'roster_column.dart';
import 'roster_view.dart';

/// Writes the roster as shown (searched, sorted, grouped) as CSV text.
abstract final class RosterCsvExporter {
  /// Ungrouped, the file is a header row followed by one row per camper.
  /// Grouped, each non-empty group becomes the group's title on a line of its
  /// own, the header row, the group's campers, and a blank line.
  ///
  /// Block columns print the name of the camper's activity in that block, or
  /// "Unassigned".
  static String export({
    required List<RosterGroup> groups,
    required List<RosterColumn> columns,
    required RosterView view,
    required bool grouped,
  }) {
    final header = formatRow([for (final column in columns) column.displayTitle]);
    final out = StringBuffer();

    if (!grouped) {
      out.writeln(header);
      for (final group in groups) {
        for (final camper in group.campers) {
          out.writeln(formatRow([for (final column in columns) view.text(camper, column)]));
        }
      }
      return out.toString();
    }

    for (final group in groups) {
      if (group.campers.isEmpty) continue;
      out
        ..writeln(escapeField(group.title))
        ..writeln(header);
      for (final camper in group.campers) {
        out.writeln(formatRow([for (final column in columns) view.text(camper, column)]));
      }
      out.writeln();
    }
    return out.toString();
  }

  /// The auto-assignment's per-camper evaluation as CSV, with the camper's
  /// name in front of the engine's own columns. [nameOf] maps a participant id
  /// to a name; unknown ids are left blank.
  static String evaluationReport(List<ParticipantEvaluationReport> reports, {required String? Function(String id) nameOf}) {
    final out = StringBuffer()..writeln(formatRow(['Camper', ...ParticipantEvaluationReport.getCsvHeader()]));
    for (final report in reports) {
      out.writeln(formatRow([nameOf(report.participantId) ?? '', ...report.toCsvRow()]));
    }
    return out.toString();
  }

  static String formatRow(Iterable<String> fields) => fields.map(escapeField).join(',');

  /// Quotes a field that contains a comma, a quote or a line break.
  static String escapeField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n') || field.contains('\r')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
}
