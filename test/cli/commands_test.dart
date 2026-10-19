import 'package:bessie/src/cli/cli.dart';
import 'package:bessie/src/commands/assignment_commands.dart';
import 'package:bessie/src/commands/context_commands.dart';
import 'package:bessie/src/commands/core_commands.dart';
import 'package:bessie/src/commands/session_commands.dart';
import 'package:bessie/src/models/activity.dart';
import 'package:bessie/src/models/enums.dart';
import 'package:bessie/src/models/schedule.dart';
import 'package:bessie/src/services/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_io.dart';
import 'support/fake_services.dart';

void main() {
  group('parseSessionDate', () {
    DateTime? parse(String text) => parseSessionDate(text, defaultYear: 2026);

    test('reads YYYY-MM-DD', () {
      expect(parse('2027-07-06'), DateTime(2027, 7, 6));
      expect(parse('2026-7-6'), DateTime(2026, 7, 6));
    });

    test('takes a missing year from the default', () {
      expect(parse('07/06'), DateTime(2026, 7, 6));
      expect(parse('7/6'), DateTime(2026, 7, 6));
      expect(parseSessionDate('07/06', defaultYear: 2031), DateTime(2031, 7, 6));
    });

    test('an explicit year wins over the default', () {
      expect(parse('07/06/2028'), DateTime(2028, 7, 6));
    });

    test('ignores surrounding space', () {
      expect(parse('  07/06 '), DateTime(2026, 7, 6));
    });

    test('rejects dates that do not exist', () {
      expect(parse('02/30'), isNull);
      expect(parse('13/01'), isNull);
      expect(parse('2026-04-31'), isNull);
      expect(parse('00/10'), isNull);
    });

    test('accepts a leap day only in a leap year', () {
      expect(parse('02/29'), isNull);
      expect(parseSessionDate('02/29', defaultYear: 2028), DateTime(2028, 2, 29));
    });

    test('rejects text that is not a date', () {
      expect(parse(''), isNull);
      expect(parse('soon'), isNull);
      expect(parse('07-06'), isNull);
      expect(parse('2026/07/06'), isNull);
    });
  });

  group('con and whoami', () {
    test('con shows where the user is working', () async {
      final world = TestWorld(sessions: [campSession('s1', 'Session 1', DateTime(2026, 6, 15))])..loadSeason();
      final io = FakeIo();
      await ViewContext(userInput: io, userOutput: io, context: world.context).runWithArgs([]);

      expect(io.lines, [
        'Organization: Camp Bessie',
        'Branch: Main Branch',
        'Season: Summer 2026 (2026-06-01 to 2026-08-30)',
        'Session: Session 1 (starts 2026-06-15)',
      ]);
    });

    test('con says so when nothing is selected', () async {
      final world = TestWorld();
      final io = FakeIo();
      await ViewContext(userInput: io, userOutput: io, context: world.context).runWithArgs([]);

      expect(io.lines, ['Organization: none', 'Branch: none', 'Season: none', 'Session: none']);
    });

    test('whoami shows name, role and organization', () async {
      final world = TestWorld(profile: staffProfile(role: StaffRole.director, first: 'Grace', last: 'Hopper', preferred: 'Amazing'))
        ..loadSeason();
      final io = FakeIo();
      await WhoAmI(userInput: io, userOutput: io, auth: world.auth, context: world.context).runWithArgs([]);

      expect(io.lines, ['Name: Amazing Hopper', 'Role: Director', 'Organization: Camp Bessie']);
    });

    test('whoami reports when nobody is signed in', () async {
      final world = TestWorld();
      final io = FakeIo();
      await WhoAmI(userInput: io, userOutput: io, auth: world.auth, context: world.context).runWithArgs([]);

      expect(io.lines.single, startsWith('error:'));
    });
  });

  group('sess and sw', () {
    late TestWorld world;
    late FakeIo io;

    setUp(() {
      world = TestWorld(
        sessions: [campSession('s1', 'Session 1', DateTime(2026, 6, 15)), campSession('s2', 'Session 2', DateTime(2026, 7, 6))],
      )..loadSeason();
      io = FakeIo();
    });

    test('sess lists the sessions and marks the current one', () async {
      await ListSessions(userInput: io, userOutput: io, context: world.context).runWithArgs([]);

      expect(io.tables.single, [
        ['Session', 'Starts', 'Current'],
        ['Session 1', '2026-06-15', 'yes'],
        ['Session 2', '2026-07-06', ''],
      ]);
    });

    test('sw switches to the session named on the command line, ignoring case', () async {
      await SwitchSession(userInput: io, userOutput: io, context: world.context).runWithArgs(['session 2']);

      expect(world.context.session.value?.id, 's2');
      expect(io.printed('Switched to Session 2'), isTrue);
    });

    test('sw explains when the name matches no session', () async {
      await SwitchSession(userInput: io, userOutput: io, context: world.context).runWithArgs(['Session 9']);

      expect(world.context.session.value?.id, 's1');
      expect(io.printed('error: There is no session called "Session 9"'), isTrue);
    });

    test('sw offers the sessions in a form and switches to the chosen one', () async {
      final form = FakeIo(
        forms: [
          [world.context.sessions[1]],
        ],
      );
      await SwitchSession(userInput: form, userOutput: form, context: world.context).runWithArgs([]);

      final fields = form.forms.single.$2.single as SelectFormFieldDescriptor;
      expect(fields.options, hasLength(2));
      expect(world.context.session.value?.id, 's2');
    });

    test('sw does nothing when the form is cancelled', () async {
      final form = FakeIo(forms: [null]);
      await SwitchSession(userInput: form, userOutput: form, context: world.context).runWithArgs([]);

      expect(world.context.session.value?.id, 's1');
      expect(form.printed('Cancelled'), isTrue);
    });

    test('sw answers to its old name migcon', () {
      final command = SwitchSession(userInput: io, userOutput: io, context: world.context);
      expect(commandRegistry([command])['migcon'], same(command));
    });
  });

  group('mksesh', () {
    late TestWorld world;
    late FakeSessionRepository sessions;

    setUp(() {
      world = TestWorld(sessions: [campSession('s1', 'Session 1', DateTime(2026, 6, 15))])..loadSeason();
      sessions = FakeSessionRepository(catalog: world.catalog);
    });

    MakeSession command(FakeIo io) => MakeSession(userInput: io, userOutput: io, context: world.context, sessions: sessions);

    test('creates a session from arguments, taking the year from the season', () async {
      final io = FakeIo();
      await command(io).runWithArgs(['Session 2', '07/06']);

      expect(sessions.created.single, (seasonId: 'season-1', name: 'Session 2', startsOn: DateTime(2026, 7, 6)));
      expect(io.prompts, isEmpty);
      expect(io.printed('success: Created Session 2, starting 2026-07-06'), isTrue);
    });

    test('uses the season\'s year, not a hardcoded one', () async {
      world.loadSeason(startsOn: DateTime(2031, 6, 1), endsOn: DateTime(2031, 8, 30));
      final io = FakeIo();
      await command(io).runWithArgs(['Session 2', '07/06']);

      expect(sessions.created.single.startsOn, DateTime(2031, 7, 6));
    });

    test('selects the new session', () async {
      await command(FakeIo()).runWithArgs(['Session 2', '2026-07-06']);

      expect(world.context.session.value?.name, 'Session 2');
      expect(world.context.sessions.map((s) => s.name), ['Session 1', 'Session 2']);
    });

    test('asks for whatever the arguments left out', () async {
      final io = FakeIo(prompts: ['Session 3', '7/20']);
      await command(io).runWithArgs([]);

      expect(io.prompts, hasLength(2));
      expect(sessions.created.single, (seasonId: 'season-1', name: 'Session 3', startsOn: DateTime(2026, 7, 20)));
    });

    test('refuses a date that does not exist', () async {
      final io = FakeIo();
      await command(io).runWithArgs(['Session 2', '02/30']);

      expect(sessions.created, isEmpty);
      expect(io.printed('error: "02/30" is not a date'), isTrue);
    });

    test('refuses a name the season already has', () async {
      final io = FakeIo();
      await command(io).runWithArgs(['session 1', '07/06']);

      expect(sessions.created, isEmpty);
      expect(io.printed('already has a session called'), isTrue);
    });

    test('asks before creating a session outside the season', () async {
      final declined = FakeIo(confirmations: [false]);
      await command(declined).runWithArgs(['Fall camp', '2026-10-05']);
      expect(sessions.created, isEmpty);
      expect(declined.confirmations.single, contains('outside Summer 2026'));

      final accepted = FakeIo(confirmations: [true]);
      await command(accepted).runWithArgs(['Fall camp', '2026-10-05']);
      expect(sessions.created.single.startsOn, DateTime(2026, 10, 5));
    });

    test('has nowhere to put a session without a season', () async {
      world.context.season.value = null;
      final io = FakeIo();
      await command(io).runWithArgs(['Session 2', '07/06']);

      expect(sessions.created, isEmpty);
      expect(io.lines.single, startsWith('error:'));
    });
  });

  group('addact and rmact', () {
    final monday = DateTime(2026, 7, 6);
    final block1 = block('b1', 'Choice Activity 1', monday);
    final canoe = activity('a-canoe', 'Canoeing');
    final pottery = activity('a-pottery', 'Pottery', isSkillsRec: true);
    final archery = activity('a-archery', 'Archery');

    late TestWorld world;
    late FakeSessionRepository sessions;

    setUp(() {
      world = TestWorld(sessions: [campSession('session-1', 'Session 1', monday)])..loadSeason();
      world.catalog.activities = [archery, canoe, pottery];
      sessions = FakeSessionRepository(
        schedule: Schedule(
          days: [],
          blocks: [block1],
          scheduledActivities: [ScheduledActivity(id: 'sa-canoe', sessionId: 'session-1', blockId: 'b1', activityId: 'a-canoe')],
          activitiesById: {'a-canoe': canoe},
        ),
      );
    });

    test('addact offers the chosen activities, leaving out those already offered', () async {
      final io = FakeIo(
        forms: [
          [block1],
          [
            [archery],
            [pottery],
          ],
        ],
      );
      await AddActivities(
        userInput: io,
        userOutput: io,
        context: world.context,
        sessions: sessions,
        catalog: world.catalog,
      ).runWithArgs([]);

      final activityForm = io.forms.last.$2.cast<MultiSelectFormFieldDescriptor<Activity>>();
      expect(activityForm.map((f) => f.label), ['Standard choice activities', 'Skills recs']);
      expect(activityForm.first.options, [archery]);
      expect(sessions.scheduled.single.blockId, 'b1');
      expect(sessions.scheduled.single.activityIds, ['a-archery', 'a-pottery']);
      expect(io.printed('Offered 2 activities'), isTrue);
    });

    test('addact does nothing when no activity is chosen', () async {
      final io = FakeIo(
        forms: [
          [block1],
          [<Activity>[], <Activity>[]],
        ],
      );
      await AddActivities(
        userInput: io,
        userOutput: io,
        context: world.context,
        sessions: sessions,
        catalog: world.catalog,
      ).runWithArgs([]);

      expect(sessions.scheduled, isEmpty);
    });

    test('rmact asks for confirmation before removing', () async {
      final scheduled = sessions.schedule!.scheduledActivities.single;
      final declined = FakeIo(
        forms: [
          [block1],
          [
            [scheduled],
          ],
        ],
        confirmations: [false],
      );
      await RemoveActivities(userInput: declined, userOutput: declined, context: world.context, sessions: sessions).runWithArgs([]);
      expect(sessions.unscheduled, isEmpty);
      expect(declined.confirmations.single, contains('lose that assignment'));

      final accepted = FakeIo(
        forms: [
          [block1],
          [
            [scheduled],
          ],
        ],
        confirmations: [true],
      );
      await RemoveActivities(userInput: accepted, userOutput: accepted, context: world.context, sessions: sessions).runWithArgs([]);
      expect(sessions.unscheduled.single, ['sa-canoe']);
    });

    test('rmact says so when nothing is offered', () async {
      sessions.schedule = Schedule(days: [], blocks: [block1], scheduledActivities: [], activitiesById: {});
      final io = FakeIo();
      await RemoveActivities(userInput: io, userOutput: io, context: world.context, sessions: sessions).runWithArgs([]);

      expect(io.printed('No activities are offered'), isTrue);
    });
  });

  group('bka and rstact', () {
    final monday = DateTime(2026, 7, 6);
    final block1 = block('b1', 'Choice Activity 1', monday);
    final block2 = block('b2', 'Choice Activity 2', monday, startHour: 11);

    late TestWorld world;
    late FakeSessionRepository sessions;
    late FakeRosterRepository roster;
    late FakeFileService files;

    setUp(() {
      world = TestWorld(sessions: [campSession('session-1', 'Session 2: Wet & Wild', monday)])..loadSeason();
      sessions = FakeSessionRepository(
        schedule: Schedule(
          days: [],
          blocks: [block1, block2],
          scheduledActivities: [ScheduledActivity(id: 'sa-1', sessionId: 'session-1', blockId: 'b1', activityId: 'a-canoe')],
          activitiesById: {'a-canoe': activity('a-canoe', 'Canoeing')},
        ),
      );
      roster = FakeRosterRepository(
        campers: [
          camper('c1', 'Ann', assignments: {'b1': 'sa-1'}),
          camper('c2', 'Bo'),
        ],
      );
      files = FakeFileService();
    });

    BackupActivityAssignments backup(FakeIo io) => BackupActivityAssignments(
      userInput: io,
      userOutput: io,
      context: world.context,
      sessions: sessions,
      roster: roster,
      backup: const BackupService(),
      files: files,
      clock: () => DateTime(2026, 7, 8, 15, 30),
    );

    test('bka --all saves one file with every block', () async {
      final io = FakeIo();
      await backup(io).runWithArgs(['--all']);

      expect(files.saved, hasLength(1));
      expect(files.saved.single.name, 'assignments-session-2-wet-wild-2026-07-08-1530');
      expect(files.saved.single.extension, 'json');
      expect(files.saved.single.contents, contains('Canoeing'));
      expect(io.printed('Saved 1 backup file.'), isTrue);
    });

    test('bka --separate saves one file per block', () async {
      await backup(FakeIo()).runWithArgs(['--separate']);

      expect(files.saved.map((f) => f.name), [
        'assignments-session-2-wet-wild-monday-choice-activity-1-2026-07-08-1530',
        'assignments-session-2-wet-wild-monday-choice-activity-2-2026-07-08-1530',
      ]);
    });

    test('bka asks which blocks to back up', () async {
      final io = FakeIo(
        forms: [
          [
            [block2],
            false,
          ],
        ],
      );
      await backup(io).runWithArgs([]);

      expect(files.saved, hasLength(1));
      expect(files.saved.single.contents, isNot(contains('Canoeing')));
    });

    test('bka saves nothing when cancelled', () async {
      final io = FakeIo(forms: [null]);
      await backup(io).runWithArgs([]);

      expect(files.saved, isEmpty);
      expect(io.printed('cancelled'), isTrue);
    });

    test('backupFileName slugs the session and block', () {
      expect(backupFileName('Session 1', DateTime(2026, 1, 2, 3, 4)), 'assignments-session-1-2026-01-02-0304');
      expect(backupFileName('!!!', DateTime(2026, 1, 2, 3, 4)), 'assignments-2026-01-02-0304');
    });

    test('rstact does nothing unless confirmed', () async {
      final io = FakeIo(confirmations: [false]);
      await ResetActivityAssignments(userInput: io, userOutput: io, context: world.context, roster: roster).runWithArgs([]);

      expect(roster.resets, isEmpty);
      expect(io.confirmations.single, contains('Session 2: Wet & Wild'));
    });

    test('rstact resets assignments only, by default', () async {
      final io = FakeIo(confirmations: [true]);
      await ResetActivityAssignments(userInput: io, userOutput: io, context: world.context, roster: roster).runWithArgs([]);

      expect(roster.resets.single, (sessionId: 'session-1', clearPreferences: false));
    });

    test('rstact --preferences also clears preferences, and says so in the question', () async {
      final io = FakeIo(confirmations: [true]);
      await ResetActivityAssignments(userInput: io, userOutput: io, context: world.context, roster: roster).runWithArgs(['--preferences']);

      expect(roster.resets.single.clearPreferences, isTrue);
      expect(io.confirmations.single, contains('requests and vetoes'));
    });
  });

  group('help', () {
    test('lists every command once, with its aliases', () async {
      final io = FakeIo();
      final switchCommand = SwitchSession(userInput: io, userOutput: io, context: TestWorld().context);
      final registry = commandRegistry([switchCommand]);
      registry['help'] = HelpCommand(userInput: io, userOutput: io, registry: registry);
      await registry['help']!.runWithArgs([]);

      final rows = io.tables.single;
      expect(rows.first, ['Command', 'Also', 'What it does']);
      expect(rows.skip(1).map((r) => r.first), ['help', 'sw']);
      expect(rows.firstWhere((r) => r.first == 'sw')[1], 'migcon');
    });

    test('explains one command', () async {
      final io = FakeIo();
      final switchCommand = SwitchSession(userInput: io, userOutput: io, context: TestWorld().context);
      final registry = commandRegistry([switchCommand]);
      await HelpCommand(userInput: io, userOutput: io, registry: registry).runWithArgs(['migcon']);

      expect(io.output, contains('sw [session name]'));
      expect(io.output, contains('sw "Session 2"'));
    });

    test('says when there is no such command', () async {
      final io = FakeIo();
      await HelpCommand(userInput: io, userOutput: io, registry: {}).runWithArgs(['nope']);

      expect(io.printed('error: There is no command called "nope"'), isTrue);
    });
  });
}
