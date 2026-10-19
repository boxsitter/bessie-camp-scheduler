import 'dart:math';

import 'package:file_saver/file_saver.dart';
import 'package:get/get.dart';

import '../../../cli/io/form_field_descriptors.dart';
import '../../../data/roster_repository.dart';
import '../../../models/cabin.dart';
import '../../../models/camp_session.dart';
import '../../../models/camper.dart';
import '../../../models/schedule.dart';
import '../../../services/assignment_service.dart';
import '../../../services/backup_service.dart';
import '../../../services/file_service.dart';
import '../../../services/roster_import_service.dart';
import '../../../shared/services/popup_service.dart';
import '../../../shared/services/toast.dart';
import '../../console/controller/console_controller.dart';
import '../models/activity_hints.dart';
import '../models/random_preferences.dart';
import '../models/roster_column.dart';
import '../models/roster_csv_exporter.dart';
import '../models/roster_messages.dart';
import '../models/roster_selection.dart';
import '../models/roster_view.dart';

/// Asks the user to fill in a small form; null when they cancel.
typedef FormPrompter = Future<List<dynamic>?> Function(String title, List<FormFieldDescriptor> fields);

/// Everything the roster page does to the database, to files, or to the
/// user's attention: confirmations, spinners and toasts included.
///
/// The methods take the campers and schedule to act on, so they hold no page
/// state. Failures are reported with a toast and never thrown. Whether the
/// signed-in user may edit is decided by the caller.
class RosterActions {
  RosterActions({
    RosterRepository? roster,
    AssignmentService? assignment,
    FileService? files,
    BackupService? backups,
    RosterCsvParser? parser,
    PopupService? popups,
    FormPrompter? prompt,
  }) : _roster = roster ?? Get.find<RosterRepository>(),
       _assignment = assignment ?? Get.find<AssignmentService>(),
       _files = files ?? Get.find<FileService>(),
       _backups = backups ?? Get.find<BackupService>(),
       _parser = parser ?? Get.find<RosterCsvParser>(),
       _popups = popups ?? Get.find<PopupService>(),
       _prompt = prompt ?? ((title, fields) => Get.find<ConsoleController>().promptForm(title, fields));

  final RosterRepository _roster;
  final AssignmentService _assignment;
  final FileService _files;
  final BackupService _backups;
  final RosterCsvParser _parser;
  final PopupService _popups;
  final FormPrompter _prompt;

  static List<String> _ids(Iterable<Camper> campers) => [for (final camper in campers) camper.id];

  Future<bool> _confirm(String title, String message) => _popups.showConfirmationDialog(title: title, message: message);

  /// Runs [action]; true when it completed, false when it failed (a toast has
  /// been shown).
  Future<bool> _run(Future<void> Function() action) async {
    final done = await attempt(() async {
      await action();
      return true;
    });
    return done ?? false;
  }

  // Import and export ---------------------------------------------------------

  /// Lets the user pick an UltraCamp roster and adds its campers to the
  /// session. True when the file was imported; false when the user backed out
  /// or the file couldn't be imported.
  Future<bool> importCsv(String sessionId) async {
    final bytes = await attempt(_files.pickCsv);
    if (bytes == null) return false;

    final ParsedRoster parsed;
    try {
      parsed = _parser.parse(_parser.decode(bytes));
    } on RosterImportException catch (e) {
      Toast.error(e.message, title: 'Could not read the file');
      return false;
    } catch (e, st) {
      Toast.failure(e, st);
      return false;
    }

    final result = await attempt(() => _roster.importCampers(sessionId, parsed.rows));
    if (result == null) return false;

    final summary = summarizeImport(parsed, result);
    if (summary.imported) {
      Toast.success(summary.message, title: 'Roster imported');
    } else {
      Toast.info(summary.message);
    }
    if (summary.cabinWarning != null) Toast.warning(summary.cabinWarning!);
    return true;
  }

  /// Saves the roster as shown as a CSV file.
  Future<void> exportCsv({
    required List<RosterGroup> groups,
    required List<RosterColumn> columns,
    required RosterView view,
    required bool grouped,
  }) async {
    final csv = RosterCsvExporter.export(groups: groups, columns: columns, view: view, grouped: grouped);
    await _saveText('roster_${fileStamp(DateTime.now())}', 'csv', csv, MimeType.csv);
  }

  /// Saves the selected campers' assignments and preferences as JSON.
  Future<void> exportBackup({required String sessionId, required List<Camper> campers, required Schedule schedule}) async {
    final json = _backups.assignmentsBackup(sessionId: sessionId, campers: campers, schedule: schedule);
    await _saveText('assignments_backup_${fileStamp(DateTime.now())}', 'json', json, MimeType.json);
  }

  /// Saves how well the last smart assign served each camper.
  Future<void> exportEvaluationReport(AssignmentRunReport report, Iterable<Camper> campers) async {
    final names = {for (final camper in campers) camper.id: camper.fullName};
    final csv = RosterCsvExporter.evaluationReport(report.evaluationReports, nameOf: (id) => names[id]);
    await _saveText('evaluation_report_${fileStamp(DateTime.now())}', 'csv', csv, MimeType.csv);
  }

  Future<void> _saveText(String name, String extension, String contents, MimeType mimeType) async {
    await attempt(() => _files.saveText(name: name, extension: extension, contents: contents, mimeType: mimeType));
  }

  // Campers -------------------------------------------------------------------

  /// Deletes the campers after asking. True when they were deleted.
  Future<bool> deleteCampers(List<Camper> campers) async {
    final proceed = await _confirm(
      'Delete ${countOf(campers.length, 'camper')}?',
      'Once deleted, campers cannot be restored. Their activity assignments and preferences for this session will be gone. '
          'Are you sure you want to proceed?',
    );
    if (!proceed) return false;
    final deleted = await _run(() => _roster.deleteCampers(_ids(campers)));
    if (deleted) Toast.success('Deleted ${countOf(campers.length, 'camper')}.');
    return deleted;
  }

  /// Marks everyone arrived, or (when they all have) nobody.
  Future<void> toggleArrived(List<Camper> campers) async {
    await _run(() => _roster.setArrived(_ids(campers), RosterSelection.arrivedTarget(campers)));
  }

  /// Asks which of [cabins] (or none) the campers should move to.
  Future<void> setCabin(List<Camper> campers, List<Cabin> cabins) async {
    const none = '';
    final labels = {for (final cabin in cabins) cabin.id: cabin.title, none: 'No cabin'};
    final answer = await _prompt('Select Cabin', [
      SelectFormFieldDescriptor<String>(
        label: 'Cabin',
        options: labels.keys.toList(),
        optionLabelBuilder: (id) => labels[id] ?? id.toString(),
      ),
    ]);
    final chosen = answer?.firstOrNull as String?;
    if (chosen == null) return;

    final moved = await _run(() => _roster.setCabin(_ids(campers), chosen == none ? null : chosen));
    if (moved) {
      Toast.success(
        chosen == none
            ? 'Removed ${countOf(campers.length, 'camper')} from their cabin.'
            : 'Moved ${countOf(campers.length, 'camper')} to ${labels[chosen]}.',
      );
    }
  }

  /// Sends each selected camper to the other of the two cabins they span.
  Future<void> swapCabins(List<Camper> campers) async {
    final problem = RosterSelection.cabinSwapProblem(campers);
    if (problem != null) {
      Toast.warning(problem, title: 'Can\'t swap cabins');
      return;
    }
    final swapped = await _run(() => _roster.swapCabins(_ids(campers)));
    if (swapped) Toast.success('Swapped the cabins of ${countOf(campers.length, 'camper')}.');
  }

  // Assignments ---------------------------------------------------------------

  /// Puts the campers into [target], replacing what they have in its block.
  /// Asks first when that would fill it beyond its capacity.
  Future<void> assign({
    required List<Camper> campers,
    required ScheduledActivity target,
    required String activityName,
    required Seats seats,
  }) async {
    if (seats.wouldOverflow) {
      final proceed = await _confirm(
        'Over capacity',
        '$activityName has room for ${seats.capacity}. Adding ${countOf(seats.incoming, 'camper')} would put '
            '${seats.enrolled + seats.incoming} in it. Assign anyway?',
      );
      if (!proceed) return;
    }
    final changed = await attempt(() => _roster.assignCampers(_ids(campers), target.id));
    if (changed == null) return;
    if (changed == 0) {
      Toast.info('Everyone selected is already in $activityName.');
    } else {
      Toast.success('Assigned ${countOf(changed, 'camper')} to $activityName.');
    }
  }

  Future<void> unassignFromActivity(List<Camper> campers, ScheduledActivity target, String activityName) async {
    final removed = await attempt(() => _roster.unassignCampers(_ids(campers), scheduledActivityId: target.id));
    if (removed == null) return;
    if (removed == 0) {
      Toast.info('None of the selected campers are in $activityName.');
    } else {
      Toast.success('Removed ${countOf(removed, 'camper')} from $activityName.');
    }
  }

  Future<void> unassignFromBlock(List<Camper> campers, Block block) async {
    final removed = await attempt(() => _roster.unassignCampers(_ids(campers), blockId: block.id));
    if (removed == null) return;
    if (removed == 0) {
      Toast.info('None of the selected campers have an activity in ${block.displayTitle}.');
    } else {
      Toast.success('Unassigned ${countOf(removed, 'camper')} from ${block.displayTitle}.');
    }
  }

  /// Removes every assignment of the campers after asking.
  Future<void> unassignFromAll(List<Camper> campers) async {
    final proceed = await _confirm(
      'Unassign ${countOf(campers.length, 'camper')}?',
      'Are you sure you want to unassign the selected campers from all of their activities? This action cannot be undone.',
    );
    if (!proceed) return;
    final removed = await attempt(() => _roster.unassignCampers(_ids(campers)));
    if (removed != null) Toast.success('Removed $removed ${removed == 1 ? 'assignment' : 'assignments'}.');
  }

  /// Runs the auto-assignment for [selected] campers, or everyone when it is
  /// null. For selected campers the user chooses which periods to fill.
  /// Returns the report, or null when the run was cancelled or failed.
  Future<AssignmentRunReport?> smartAssign({
    required String sessionId,
    required Schedule schedule,
    required List<Camper> everyone,
    List<Camper>? selected,
  }) async {
    final targets = selected ?? everyone;
    if (targets.isEmpty) {
      Toast.info('There are no campers to assign.');
      return null;
    }

    if (AssignmentService.withoutPreferences(targets).isNotEmpty) {
      final proceed = await _confirm(
        'Confirm',
        'Some ${selected == null ? '' : 'selected '}campers have not finished indicating their preferences yet. '
            'Their preference for these activities will be treated as neutral which could cause fully random assignments. '
            'Are you sure you want to proceed?',
      );
      if (!proceed) return null;
    }

    Set<String>? blockIds;
    if (selected != null) {
      blockIds = await _promptBlocks(schedule);
      if (blockIds == null) return null;
    }

    final report = await attempt(
      () => _popups.executeWithSpinner(
        title: 'Smart assign',
        inProgressMessage: 'Assigning campers. This could take a moment...',
        task: () => _assignment.run(
          sessionId: sessionId,
          camperIds: selected == null ? null : _ids(selected).toSet(),
          blockIds: blockIds,
        ),
      ),
    );
    if (report == null) return null;

    if (report.assignedCount > 0) {
      Toast.success('Smart assign made ${countOf(report.assignedCount, 'assignment')}.');
    } else if (!report.hasStalemates) {
      Toast.info('Nothing to assign: everyone already has an activity in the chosen periods.');
    }
    if (report.hasStalemates) {
      final count = report.stalemates.length;
      Toast.warning('${countOf(count, 'slot')} could not be filled and ${count == 1 ? 'was' : 'were'} left unassigned.');
    }
    return report;
  }

  Future<Set<String>?> _promptBlocks(Schedule schedule) async {
    if (schedule.blocks.isEmpty) {
      Toast.info('This session has no schedule yet.');
      return null;
    }
    final labels = {for (final block in schedule.blocks) block.id: block.displayTitle};
    final answer = await _prompt('Select Activities', [
      MultiSelectFormFieldDescriptor<String>(
        label: 'Periods',
        options: labels.keys.toList(),
        optionLabelBuilder: (id) => labels[id] ?? id.toString(),
      ),
    ]);
    if (answer == null) return null;
    final chosen = (answer.firstOrNull as List?)?.whereType<String>().toSet();
    return (chosen == null || chosen.isEmpty) ? null : chosen;
  }

  // Preferences ---------------------------------------------------------------

  /// Testing aid: replaces the campers' preferences with random ones.
  Future<void> rankRandom({
    required List<Camper> campers,
    required Schedule schedule,
    required PreferenceLimits limits,
    Random? random,
  }) async {
    final proceed = await _confirm(
      'Rank random (testing only)',
      'This is a testing aid. It replaces the requests and vetoes of ${countOf(campers.length, 'selected camper')} '
          'with random ones, within this session\'s limits. This action cannot be undone. Continue?',
    );
    if (!proceed) return;

    final rng = random ?? Random();
    final done = await _run(
      () => _popups.executeWithSpinner(
        title: 'Rank random',
        inProgressMessage: 'Choosing random preferences...',
        task: () async {
          for (final camper in campers) {
            final picks = pickRandomPreferences(schedule: schedule, limits: limits, random: rng);
            await _roster.setPreferences(camperId: camper.id, requestedActivityIds: picks.requests, vetoedActivityIds: picks.vetoes);
          }
        },
      ),
    );
    if (done) Toast.success('Gave ${countOf(campers.length, 'camper')} random preferences.');
  }

  /// Removes the campers' requests and vetoes after asking.
  Future<void> clearPreferences(List<Camper> campers) async {
    final proceed = await _confirm(
      'Clear preferences?',
      'Are you sure you want to remove these activity preferences? This action cannot be undone.',
    );
    if (!proceed) return;
    final cleared = await _run(() => _roster.clearPreferences(_ids(campers)));
    if (cleared) Toast.success('Cleared the preferences of ${countOf(campers.length, 'camper')}.');
  }
}
