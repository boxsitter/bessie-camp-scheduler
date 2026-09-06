
import 'dart:convert';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_disposable.dart';

import '../ember_core.dart';
import '../algorithms/evaluation/participant_evaluation_report.dart';

class IOService extends GetxService {
  final _jsonEncoder = const JsonEncoder.withIndent('  ');

  /// Prompts the user for a save location and exports JSON data to a file.
  ///
  /// Returns the path of the saved file, or `null` if the user cancels the dialog.
  Future<String?> exportDataAsJson({
    required dynamic data,
    required String dialogTitle,
    required String fileName,
  }) async {
    final jsonString = _jsonEncoder.convert(data);
    final Uint8List bytes = utf8.encode(jsonString);

    return await FilePicker.platform.saveFile(
      dialogTitle: dialogTitle,
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: bytes,
    );
  }

  /// Exports a list of CoreObjects to a single JSON file.
  ///
  /// Returns the path of the saved file, or `null` if the user cancels.
  Future<String?> exportCoreObjects({
    required List<CoreObject> objects,
    required String dialogTitle,
    required String fileName,
  }) async {
    final jsonData = objects.map((o) => o.toJson()).toList();
    return await exportDataAsJson(
      data: jsonData,
      dialogTitle: dialogTitle,
      fileName: fileName,
    );
  }

  /// Prepares and exports camper activity assignment data as a JSON backup.
  ///
  /// Handles both combined and separate file exports.
  /// Returns a list of paths for the successfully saved files.
  Future<List<String>> backupAssignments({
    required Map<String, Map<String, String>> backupData,
    required List<AMABlock> selectedBlocks,
    required bool separateFiles,
  }) async {
    final List<String> savedFiles = [];

    if (separateFiles) {
      for (final block in selectedBlocks) {
        final blockId = block.id;
        final dataForBlock = {blockId: backupData[blockId]};
        final savedPath = await exportDataAsJson(
          data: dataForBlock,
          dialogTitle: 'Save Backup for ${block.displayTitle}',
          fileName: 'assignments_backup_${block.idTag}.json',
        );
        if (savedPath != null) {
          savedFiles.add(savedPath);
        }
      }
    } else {
      final savedPath = await exportDataAsJson(
        data: backupData,
        dialogTitle: 'Save Combined Backup',
        fileName: 'assignments_backup_combined.json',
      );
      if (savedPath != null) {
        savedFiles.add(savedPath);
      }
    }
    return savedFiles;
  }

  /// Exports a list of participant evaluation reports to a CSV file.
  ///
  /// Returns the path of the saved file, or `null` if the user cancels.
  Future<String?> exportEvaluationReportAsCsv({
    required List<ParticipantEvaluationReport> reports,
    required String fileName,
  }) async {
    final StringBuffer csvBuffer = StringBuffer();

    // Add the header row
    csvBuffer.writeln(ParticipantEvaluationReport.getCsvHeader().map(_escapeCsvField).join(','));

    // Add the data rows
    for (final report in reports) {
      csvBuffer.writeln(report.toCsvRow().map(_escapeCsvField).join(','));
    }

    final Uint8List bytes = utf8.encode(csvBuffer.toString());

    return await FilePicker.platform.saveFile(
      dialogTitle: 'Save Evaluation Report',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['csv'],
      bytes: bytes,
    );
  }

  /// Exports a list of roster groups to a CSV formatted string.
  ///
  /// If `selectedItems` is provided, only those items will be included.
  String exportToCsv({
    required List<RosterGroup> groups,
    required List<RosterField> columns,
    required List<ActivityDependent> activityDependents,
    required Map<PrincipalActivityId, PrincipalActivity> principalActivities,
    Set<Rosterable>? selectedItems,
  }) {
    final StringBuffer csvBuffer = StringBuffer();
    final bool isGrouped = groups.length > 1;
    final bool hasSelection = selectedItems != null && selectedItems.isNotEmpty;

    final header = columns.map((field) => _escapeCsvField(field.title)).join(',');

    if (!isGrouped) {
      csvBuffer.writeln(header);
      csvBuffer.writeln('');
    }

    for (final group in groups) {
      final itemsToExport = hasSelection ? group.items.where((item) => selectedItems.contains(item)).toList() : group.items;

      if (itemsToExport.isEmpty) {
        continue;
      }

      if (isGrouped) {
        // Find the activity dependent by its ID (which is the group.title)
        final activityDependent =
            activityDependents.firstWhereOrNull((dep) => dep.id == group.title);
        final principalActivity = principalActivities[activityDependent?.principalPar];

        // Use the principal activity name if found, otherwise default to the group's original title.
        final groupTitle = principalActivity?.name ?? group.title;

          csvBuffer.writeln(_escapeCsvField(groupTitle));
        csvBuffer.writeln(header);
        csvBuffer.writeln('');
      }

      for (final item in itemsToExport) {
        final row = columns
            .map((field) {
          final value = (field is AMABlock)
              ? _getActivityDependentName(
                  item, field, activityDependents, principalActivities)
              : item.getFieldAsString(field);
              return _escapeCsvField(value);
            })
            .join(',');
        csvBuffer.writeln(row);
      }

      if (isGrouped) {
        csvBuffer.writeln('');
      }
    }

    return csvBuffer.toString();
  }

  /// Escapes a field for CSV format.
  String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      final escapedField = field.replaceAll('"', '""');
      return '"$escapedField"';
    }
    return field;
  }

  /// Resolves the name of an activity dependent for display.
  String _getActivityDependentName(
    Rosterable rosterItem,
    RosterField field,
    List<ActivityDependent> activityDependents,
    Map<PrincipalActivityId, PrincipalActivity> principalActivities,
  ) {
    String activityDependentId = rosterItem.getFieldAsString(field);
    if (activityDependentId.isEmpty) {
      return 'Unassigned';
    }

    // Use firstWhereOrNull for a safe lookup without a try-catch block.
    final activityDependent = activityDependents
        .firstWhereOrNull((dep) => dep.id == activityDependentId);

    if (activityDependent == null) {
      return 'Error (not found)';
    }

    final principalActivity = principalActivities[activityDependent.principalPar];
    return principalActivity?.name ?? 'Error (no principal)';
  }


}
