import 'package:collection/collection.dart';

import '../cli/cli.dart';
import '../data/catalog_repository.dart';
import '../data/session_repository.dart';
import '../models/activity.dart';
import '../models/row_codec.dart';
import '../models/schedule.dart';
import '../services/context_service.dart';
import 'labels.dart';

final _isoDate = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$');
final _usDate = RegExp(r'^(\d{1,2})/(\d{1,2})(?:/(\d{4}))?$');

/// Reads a start date typed as `YYYY-MM-DD`, `MM/DD` or `MM/DD/YYYY`.
///
/// A date without a year gets [defaultYear] (the year of the current season).
/// Returns null for anything that is not a real calendar date.
DateTime? parseSessionDate(String input, {required int defaultYear}) {
  final text = input.trim();
  final int year, month, day;
  final iso = _isoDate.firstMatch(text);
  final us = _usDate.firstMatch(text);
  if (iso != null) {
    year = int.parse(iso[1]!);
    month = int.parse(iso[2]!);
    day = int.parse(iso[3]!);
  } else if (us != null) {
    month = int.parse(us[1]!);
    day = int.parse(us[2]!);
    year = us[3] == null ? defaultYear : int.parse(us[3]!);
  } else {
    return null;
  }
  final date = DateTime(year, month, day);
  // DateTime rolls 02/30 over to 03/02; a real date comes back unchanged.
  return date.year == year && date.month == month && date.day == day ? date : null;
}

/// `mksesh`: create a session in the current season and switch to it.
class MakeSession extends EmberCommand<void> {
  MakeSession({required super.userInput, required super.userOutput, required ContextService context, required SessionRepository sessions})
    : _context = context,
      _sessions = sessions;

  final ContextService _context;
  final SessionRepository _sessions;

  @override
  final String name = 'mksesh';
  @override
  final String description =
      'Creates a session in the current season, with its days and blocks from the branch templates, and switches to it. '
      'Dates are YYYY-MM-DD, or MM/DD in the season\'s year.';
  @override
  String get positionalSyntax => '[name] [start date]';
  @override
  int get maxPositionalArguments => 2;
  @override
  List<String> get examples => const ['mksesh', 'mksesh "Session 3" 07/06', 'mksesh "Session 3" 2026-07-06'];

  @override
  Future<void> run() async {
    final season = _context.season.value;
    if (season == null) {
      userOutput.error('No season is loaded, so there is nowhere to put a session.');
      return;
    }
    final given = argResults.rest;

    final sessionName = (given.isNotEmpty ? given[0] : await userInput.prompt('Session name:')).trim();
    if (sessionName.isEmpty) {
      userOutput.error('A session needs a name.');
      return;
    }
    if (_context.sessions.any((s) => s.name.toLowerCase() == sessionName.toLowerCase())) {
      userOutput.error('${season.name} already has a session called "$sessionName".');
      return;
    }

    final year = season.startsOn.year;
    final dateText =
        given.length > 1
            ? given[1]
            : await userInput.prompt(
              'Start date (YYYY-MM-DD or MM/DD):',
              validator: (text) => parseSessionDate(text, defaultYear: year) != null,
            );
    final startsOn = parseSessionDate(dateText, defaultYear: year);
    if (startsOn == null) {
      userOutput.error('"$dateText" is not a date I understand. Use YYYY-MM-DD or MM/DD.');
      return;
    }

    if (startsOn.isBefore(season.startsOn) || startsOn.isAfter(season.endsOn)) {
      final proceed = await userInput.confirm(
        '${formatDbDate(startsOn)} is outside ${season.name} (${formatDbDate(season.startsOn)} to ${formatDbDate(season.endsOn)}). Create the session anyway?',
      );
      if (!proceed) {
        userOutput.info('Cancelled.');
        return;
      }
    }

    final created = await _sessions.createSession(seasonId: season.id, name: sessionName, startsOn: startsOn);
    await _context.adoptNewSession(created);
    userOutput.success('Created ${created.name}, starting ${formatDbDate(created.startsOn)}, and switched to it.');
  }
}

/// `addact`: offer activities during a block.
class AddActivities extends EmberCommand<void> {
  AddActivities({
    required super.userInput,
    required super.userOutput,
    required ContextService context,
    required SessionRepository sessions,
    required CatalogRepository catalog,
  }) : _context = context,
       _sessions = sessions,
       _catalog = catalog;

  final ContextService _context;
  final SessionRepository _sessions;
  final CatalogRepository _catalog;

  @override
  final String name = 'addact';
  @override
  final String description = 'Offers activities during a block of the current session.';

  @override
  Future<void> run() async {
    final session = _context.currentSession;
    final schedule = await _sessions.fetchSchedule(session.id);
    if (schedule.blocks.isEmpty) {
      userOutput.error('${session.name} has no blocks yet.');
      return;
    }

    final block = await _chooseBlock(schedule.blocks);
    if (block == null) return;

    final alreadyOffered = schedule.scheduledIn(block.id).map((s) => s.activityId).toSet();
    final activities = (await _catalog.listActivities(_context.branchId)).where((a) => !alreadyOffered.contains(a.id)).toList();
    final groups =
        <(String, List<Activity>)>[
          ('Standard choice activities', activities.where((a) => !a.isSkillsRec).toList()),
          ('Skills recs', activities.where((a) => a.isSkillsRec).toList()),
        ].where((group) => group.$2.isNotEmpty).toList();
    if (groups.isEmpty) {
      userOutput.info('Every activity is already offered during ${block.displayTitle}.');
      return;
    }

    final answers = await userInput.promptForm('Offer activities during ${block.displayTitle}', [
      for (final (label, options) in groups)
        MultiSelectFormFieldDescriptor<Activity>(
          label: label,
          options: options,
          optionLabelBuilder: (value) => (value as Activity).name,
          isRequired: false,
        ),
    ]);
    if (answers == null) {
      userOutput.info('Cancelled.');
      return;
    }

    final chosen = [
      for (final answer in answers)
        if (answer is List) ...answer.cast<Activity>(),
    ];
    if (chosen.isEmpty) {
      userOutput.info('No activities were selected.');
      return;
    }
    await _sessions.scheduleActivities(sessionId: session.id, blockId: block.id, activityIds: chosen.map((a) => a.id));
    userOutput.success('Offered ${chosen.length} ${chosen.length == 1 ? 'activity' : 'activities'} during ${block.displayTitle}.');
  }

  Future<Block?> _chooseBlock(List<Block> blocks) async {
    final answers = await userInput.promptForm('Choose a block', [
      SelectFormFieldDescriptor<Block>(label: 'Block', options: blocks, optionLabelBuilder: (value) => blockLabel(value as Block)),
    ]);
    if (answers == null || answers.first == null) {
      userOutput.info('Cancelled.');
      return null;
    }
    return answers.first as Block;
  }
}

/// `rmact`: stop offering activities during a block.
class RemoveActivities extends EmberCommand<void> {
  RemoveActivities({
    required super.userInput,
    required super.userOutput,
    required ContextService context,
    required SessionRepository sessions,
  }) : _context = context,
       _sessions = sessions;

  final ContextService _context;
  final SessionRepository _sessions;

  @override
  final String name = 'rmact';
  @override
  final String description = 'Stops offering activities during a block. Campers assigned to them lose just that assignment.';

  @override
  Future<void> run() async {
    final session = _context.currentSession;
    final schedule = await _sessions.fetchSchedule(session.id);
    final blocks = schedule.blocks.where((b) => schedule.scheduledIn(b.id).isNotEmpty).toList();
    if (blocks.isEmpty) {
      userOutput.info('No activities are offered in ${session.name}.');
      return;
    }

    final blockAnswers = await userInput.promptForm('Choose a block', [
      SelectFormFieldDescriptor<Block>(label: 'Block', options: blocks, optionLabelBuilder: (value) => blockLabel(value as Block)),
    ]);
    if (blockAnswers == null || blockAnswers.first == null) {
      userOutput.info('Cancelled.');
      return;
    }
    final block = blockAnswers.first as Block;

    String activityName(dynamic value) {
      final scheduled = value as ScheduledActivity;
      return schedule.activityOf(scheduled)?.name ?? scheduled.activityId;
    }

    final offered = schedule.scheduledIn(block.id).sortedBy((s) => activityName(s).toLowerCase());
    final answers = await userInput.promptForm('Stop offering during ${block.displayTitle}', [
      MultiSelectFormFieldDescriptor<ScheduledActivity>(label: 'Activities to remove', options: offered, optionLabelBuilder: activityName),
    ]);
    final chosen = (answers?.first as List?)?.cast<ScheduledActivity>() ?? const <ScheduledActivity>[];
    if (chosen.isEmpty) {
      userOutput.info('No activities were removed.');
      return;
    }

    final confirmed = await userInput.confirm(
      'Stop offering ${chosen.length} ${chosen.length == 1 ? 'activity' : 'activities'} during ${block.displayTitle}? '
      'Campers assigned to ${chosen.length == 1 ? 'it' : 'them'} lose that assignment.',
    );
    if (!confirmed) {
      userOutput.info('Nothing was changed.');
      return;
    }
    await _sessions.unscheduleActivities(chosen.map((s) => s.id));
    userOutput.success('Removed ${chosen.length} ${chosen.length == 1 ? 'activity' : 'activities'} from ${block.displayTitle}.');
  }
}
