import 'package:file_saver/file_saver.dart' show MimeType;
import 'package:intl/intl.dart';

import '../cli/cli.dart';
import '../data/roster_repository.dart';
import '../data/session_repository.dart';
import '../models/schedule.dart';
import '../services/backup_service.dart';
import '../services/context_service.dart';
import '../services/file_service.dart';
import 'labels.dart';

/// The file name (without extension) of an assignments backup, e.g.
/// `assignments-session-2-2026-07-06-1530` or, for one block,
/// `assignments-session-2-monday-choice-activity-1-2026-07-06-1530`.
String backupFileName(String sessionName, DateTime now, {Block? block}) {
  String slug(String text) => text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
  final parts = ['assignments', slug(sessionName), if (block != null) slug(block.displayTitle), DateFormat('yyyy-MM-dd-HHmm').format(now)];
  return parts.where((part) => part.isNotEmpty).join('-');
}

/// `bka`: save a readable JSON copy of the activity assignments.
class BackupActivityAssignments extends EmberCommand<void> {
  BackupActivityAssignments({
    required super.userInput,
    required super.userOutput,
    required ContextService context,
    required SessionRepository sessions,
    required RosterRepository roster,
    required BackupService backup,
    required FileService files,
    DateTime Function()? clock,
  }) : _context = context,
       _sessions = sessions,
       _roster = roster,
       _backup = backup,
       _files = files,
       _clock = clock ?? DateTime.now {
    argParser
      ..addFlag('all', abbr: 'a', negatable: false, help: 'Back up every block without asking.')
      ..addFlag('separate', abbr: 's', negatable: false, help: 'Back up every block into one file per block (implies --all).');
  }

  final ContextService _context;
  final SessionRepository _sessions;
  final RosterRepository _roster;
  final BackupService _backup;
  final FileService _files;
  final DateTime Function() _clock;

  @override
  final String name = 'bka';
  @override
  final String description = 'Saves the activity assignments of the current session to a JSON file. Do this before rstact.';
  @override
  List<String> get examples => const ['bka', 'bka --all', 'bka --separate'];

  @override
  Future<void> run() async {
    final session = _context.currentSession;
    final schedule = await _sessions.fetchSchedule(session.id);
    if (schedule.blocks.isEmpty) {
      userOutput.error('${session.name} has no blocks to back up.');
      return;
    }

    final List<Block> blocks;
    final bool separate;
    final wantsSeparate = argResults['separate'] as bool;
    if (argResults['all'] as bool || wantsSeparate) {
      blocks = schedule.blocks;
      separate = wantsSeparate;
    } else {
      final answers = await userInput.promptForm('Back up activity assignments', [
        MultiSelectFormFieldDescriptor<Block>(
          label: 'Blocks to back up',
          options: schedule.blocks,
          optionLabelBuilder: (value) => blockLabel(value as Block),
          defaultValue: schedule.blocks,
        ),
        BooleanFormFieldDescriptor(label: 'A separate file for each block?'),
      ]);
      if (answers == null) {
        userOutput.info('Backup cancelled.');
        return;
      }
      blocks = (answers[0] as List?)?.cast<Block>() ?? const <Block>[];
      separate = answers[1] as bool? ?? false;
    }
    if (blocks.isEmpty) {
      userOutput.info('No blocks were selected, so there is nothing to back up.');
      return;
    }

    final campers = await _roster.fetchCampers(session.id);
    final now = _clock();
    final batches =
        separate
            ? [
              for (final block in blocks) [block],
            ]
            : [blocks];
    for (final batch in batches) {
      final contents = _backup.assignmentsBackup(
        sessionId: session.id,
        campers: campers,
        schedule: schedule,
        blockIds: {for (final block in batch) block.id},
        now: now,
      );
      await _files.saveText(
        name: backupFileName(session.name, now, block: separate ? batch.single : null),
        extension: 'json',
        contents: contents,
        mimeType: MimeType.json,
      );
    }
    userOutput.success('Saved ${batches.length} backup ${batches.length == 1 ? 'file' : 'files'}.');
  }
}

/// `rstact`: clear every camper's activity assignments (and optionally their preferences).
class ResetActivityAssignments extends EmberCommand<void> {
  ResetActivityAssignments({
    required super.userInput,
    required super.userOutput,
    required ContextService context,
    required RosterRepository roster,
  }) : _context = context,
       _roster = roster {
    argParser.addFlag('preferences', abbr: 'p', negatable: false, help: 'Also clear every camper\'s activity requests and vetoes.');
  }

  final ContextService _context;
  final RosterRepository _roster;

  @override
  final String name = 'rstact';
  @override
  final String description = 'Clears every camper\'s activity assignments in the current session. Run bka first to keep a copy.';
  @override
  List<String> get examples => const ['rstact', 'rstact --preferences'];

  @override
  Future<void> run() async {
    final session = _context.currentSession;
    final clearPreferences = argResults['preferences'] as bool;

    final confirmed = await userInput.confirm(
      'Clear every camper\'s activity assignments in ${session.name}${clearPreferences ? ', along with their requests and vetoes' : ''}? '
      'This cannot be undone.',
    );
    if (!confirmed) {
      userOutput.info('Nothing was changed.');
      return;
    }
    await _roster.resetAssignments(session.id, clearPreferences: clearPreferences);
    userOutput.success('Cleared the assignments${clearPreferences ? ' and preferences' : ''} in ${session.name}.');
  }
}
