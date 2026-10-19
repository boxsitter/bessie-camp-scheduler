import 'dart:convert';
import 'dart:typed_data';

import 'package:bessie/src/algorithms/data_models/assignment_result.dart';
import 'package:bessie/src/features/rosters/controllers/roster_actions.dart';
import 'package:bessie/src/features/rosters/models/activity_hints.dart';
import 'package:bessie/src/features/rosters/models/roster_column.dart';
import 'package:bessie/src/features/rosters/models/roster_context.dart';
import 'package:bessie/src/features/rosters/models/roster_view.dart';
import 'package:bessie/src/models/camp_session.dart';
import 'package:bessie/src/models/camper.dart';
import 'package:bessie/src/services/assignment_service.dart';
import 'package:bessie/src/services/backup_service.dart';
import 'package:bessie/src/services/roster_import_service.dart';
import 'package:bessie/src/shared/services/popup_service.dart';
import 'package:bessie/src/shared/services/toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'fake_repositories.dart';
import 'fake_services.dart';
import 'roster_fixtures.dart';

Uint8List _csv(String text) => Uint8List.fromList(utf8.encode(text));

void main() {
  late SupabaseClient client;
  late FakeRosterRepository roster;
  late FakePopupService popups;
  late FakeFileService files;
  late FakeAssignmentService assignment;
  late List<(String, List<Object>)> prompts;
  late List<dynamic>? Function(String title) promptAnswer;
  late RosterActions actions;

  final ada = makeCamper(first: 'Ada', last: 'Lovelace', cabinId: 'c1', preferencesSubmittedAt: DateTime(2026));
  final bo = makeCamper(first: 'Bo', last: 'Brown', cabinId: 'c2', preferencesSubmittedAt: DateTime(2026));
  final cy = makeCamper(first: 'Cy', last: 'Green'); // no preferences yet

  final schedule = makeSchedule(
    blocks: [makeBlock('b1', 'AM1'), makeBlock('b2', 'PM1', dayIndex: 1)],
    activities: [
      for (var i = 0; i < 8; i++) makeActivity('act$i', 'Activity $i'),
      makeActivity('skill1', 'Skill 1', skills: true),
      makeActivity('skill2', 'Skill 2', skills: true),
    ],
    scheduled: {
      's-b1-act0': ('b1', 'act0'),
      for (var i = 0; i < 8; i++) 's-b2-act$i': ('b2', 'act$i'),
      's-skill1': ('b2', 'skill1'),
      's-skill2': ('b2', 'skill2'),
    },
  );

  setUp(() {
    client = SupabaseClient('http://127.0.0.1:1', 'anon-key', authOptions: const AuthClientOptions(autoRefreshToken: false));
    roster = FakeRosterRepository(client);
    popups = FakePopupService();
    files = FakeFileService();
    assignment = FakeAssignmentService();
    prompts = [];
    promptAnswer = (_) => null;
    actions = RosterActions(
      roster: roster,
      assignment: assignment,
      files: files,
      backups: const BackupService(),
      parser: const RosterCsvParser(),
      popups: popups,
      prompt: (title, fields) async {
        prompts.add((title, [for (final f in fields) f]));
        return promptAnswer(title);
      },
    );
  });

  tearDown(() async {
    Get.reset();
    await client.dispose();
  });

  /// Mounts an app so toasts reach the (fake) popup service, then runs [body].
  void actionTest(String description, Future<void> Function() body) {
    testWidgets(description, (tester) async {
      Get.testMode = true;
      Get.put<PopupService>(popups);
      await tester.pumpWidget(const GetMaterialApp(home: SizedBox()));
      await tester.runAsync(body);
    });
  }

  group('import', () {
    actionTest('sends the parsed campers and reports the result', () async {
      files.picked = _csv('nameFirst,nameLast,Birthdate,Cabin\nAda,Lovelace,12/10/2014,Cabin 1\nBo,Brown,01/02/2013,\n');
      roster.importResult = const CamperImportResult(inserted: 2, duplicates: 0, unknownCabins: []);

      expect(await actions.importCsv('s1'), isTrue);

      expect(roster.importCalls.single.$1, 's1');
      expect(roster.importCalls.single.$2.map((r) => r.firstName), ['Ada', 'Bo']);
      expect(roster.importCalls.single.$2.first.cabinName, 'Cabin 1');
      expect(popups.messages(ToastType.success), ['Added 2 campers.']);
    });

    actionTest('reports duplicates and cabins that are not in the session', () async {
      files.picked = _csv('nameFirst,nameLast,Birthdate\nAda,Lovelace,12/10/2014\nAda,Lovelace,12/10/2014\n');
      roster.importResult = const CamperImportResult(inserted: 0, duplicates: 1, unknownCabins: ['Moon']);

      await actions.importCsv('s1');

      expect(popups.messages(ToastType.info).single, contains('already on the roster'));
      expect(popups.messages(ToastType.warning).single, contains('Moon'));
    });

    actionTest('shows the message of a file that cannot be read and imports nothing', () async {
      files.picked = _csv('nameFirst,nameLast\nAda,Lovelace\n');

      expect(await actions.importCsv('s1'), isFalse);

      expect(roster.importCalls, isEmpty);
      expect(popups.messages(ToastType.error).single, contains('Birthdate'));
    });

    actionTest('does nothing when no file is chosen', () async {
      expect(await actions.importCsv('s1'), isFalse);
      expect(roster.importCalls, isEmpty);
      expect(popups.toasts, isEmpty);
    });
  });

  group('destructive actions ask first', () {
    actionTest('delete: nothing happens when declined, and the message says what is lost', () async {
      popups.confirmAnswer = false;
      expect(await actions.deleteCampers([ada, bo]), isFalse);
      expect(roster.deleteCalls, isEmpty);
      expect(popups.confirmations.single.message, contains('assignments and preferences'));

      popups.confirmAnswer = true;
      expect(await actions.deleteCampers([ada, bo]), isTrue);
      expect(roster.deleteCalls.single, [ada.id, bo.id]);
    });

    actionTest('unassign from everything', () async {
      popups.confirmAnswer = false;
      await actions.unassignFromAll([ada]);
      expect(roster.unassignCalls, isEmpty);

      popups.confirmAnswer = true;
      await actions.unassignFromAll([ada, bo]);
      expect(roster.unassignCalls.single.$1, [ada.id, bo.id]);
      expect(roster.unassignCalls.single.$2, isNull);
      expect(roster.unassignCalls.single.$3, isNull);
    });

    actionTest('clear preferences', () async {
      popups.confirmAnswer = false;
      await actions.clearPreferences([ada]);
      expect(roster.clearCalls, isEmpty);

      popups.confirmAnswer = true;
      await actions.clearPreferences([ada]);
      expect(roster.clearCalls.single, [ada.id]);
    });

    actionTest('unassigning from one activity or one block needs no confirmation', () async {
      final scheduled = schedule.scheduledActivityById('s-b1-act0')!;
      await actions.unassignFromActivity([ada], scheduled, 'Activity 0');
      await actions.unassignFromBlock([ada], schedule.blockById('b1')!);
      expect(roster.unassignCalls.map((c) => (c.$2, c.$3)), [(null, 's-b1-act0'), ('b1', null)]);
      expect(popups.confirmations, isEmpty);
    });
  });

  group('assign', () {
    final target = schedule.scheduledActivityById('s-b1-act0')!;

    actionTest('assigns without asking when it fits', () async {
      await actions.assign(
        campers: [ada],
        target: target,
        activityName: 'Activity 0',
        seats: const Seats(enrolled: 3, capacity: 10, incoming: 1),
      );
      expect(roster.assignCalls.single.$1, [ada.id]);
      expect(roster.assignCalls.single.$2, 's-b1-act0');
      expect(popups.confirmations, isEmpty);
    });

    actionTest('asks before overfilling an activity', () async {
      popups.confirmAnswer = false;
      const seats = Seats(enrolled: 9, capacity: 10, incoming: 2);
      await actions.assign(campers: [ada, bo], target: target, activityName: 'Activity 0', seats: seats);
      expect(roster.assignCalls, isEmpty);
      expect(popups.confirmations.single.message, contains('room for 10'));

      popups.confirmAnswer = true;
      await actions.assign(campers: [ada, bo], target: target, activityName: 'Activity 0', seats: seats);
      expect(roster.assignCalls.single.$1, [ada.id, bo.id]);
    });
  });

  group('cabins', () {
    final cabins = [makeCabin('c1', 'Cabin 1', displayName: 'Eagles'), makeCabin('c2', 'Cabin 2')];

    actionTest('set cabin lists cabins by title plus "No cabin" and moves the campers', () async {
      promptAnswer = (_) => ['c2'];
      await actions.setCabin([ada, bo], cabins);

      final field = prompts.single.$2.single as dynamic;
      expect((field.options as List).length, 3);
      expect((field.optionLabelBuilder as String Function(dynamic))('c1'), 'Eagles');
      expect((field.optionLabelBuilder as String Function(dynamic))(''), 'No cabin');
      expect(roster.cabinCalls.single.$1, [ada.id, bo.id]);
      expect(roster.cabinCalls.single.$2, 'c2');
    });

    actionTest('choosing "No cabin" clears the cabin and cancelling changes nothing', () async {
      promptAnswer = (_) => [''];
      await actions.setCabin([ada], cabins);
      expect(roster.cabinCalls.single.$1, [ada.id]);
      expect(roster.cabinCalls.single.$2, isNull);

      roster.cabinCalls.clear();
      promptAnswer = (_) => null;
      await actions.setCabin([ada], cabins);
      expect(roster.cabinCalls, isEmpty);
    });

    actionTest('swap sends the selection to the repository only when it spans exactly two cabins', () async {
      await actions.swapCabins([ada]);
      await actions.swapCabins([ada, cy]);
      expect(roster.swapCalls, isEmpty);
      expect(popups.messages(ToastType.warning), hasLength(2));

      await actions.swapCabins([ada, bo]);
      expect(roster.swapCalls.single, [ada.id, bo.id]);
    });
  });

  group('smart assign', () {
    actionTest('asks first when campers have no saved preferences, and stops when declined', () async {
      popups.confirmAnswer = false;
      final report = await actions.smartAssign(sessionId: 's1', schedule: schedule, everyone: [ada, bo, cy]);
      expect(report, isNull);
      expect(assignment.runs, isEmpty);
      expect(popups.confirmations.single.message, startsWith('Some campers have not finished indicating their preferences'));
    });

    actionTest('all campers: runs for everyone and every period', () async {
      final report = await actions.smartAssign(sessionId: 's1', schedule: schedule, everyone: [ada, bo, cy]);
      expect(report, same(assignment.report));
      expect(assignment.runs.single.sessionId, 's1');
      expect(assignment.runs.single.camperIds, isNull);
      expect(assignment.runs.single.blockIds, isNull);
      expect(popups.messages(ToastType.success).single, contains('5 assignments'));
    });

    actionTest('does not ask when everyone targeted has saved preferences', () async {
      promptAnswer =
          (_) => [
            ['b2'],
          ];
      await actions.smartAssign(sessionId: 's1', schedule: schedule, everyone: [ada, bo, cy], selected: [ada, bo]);
      expect(popups.confirmations, isEmpty);
    });

    actionTest('selected campers: asks for the periods and runs for exactly those', () async {
      promptAnswer =
          (_) => [
            ['b1', 'b2'],
          ];
      await actions.smartAssign(sessionId: 's1', schedule: schedule, everyone: [ada, bo, cy], selected: [ada, bo]);

      expect(prompts.single.$1, 'Select Activities');
      final field = prompts.single.$2.single as dynamic;
      expect((field.optionLabelBuilder as String Function(dynamic))('b2'), 'Tuesday - PM1');
      expect(assignment.runs.single.camperIds, {ada.id, bo.id});
      expect(assignment.runs.single.blockIds, {'b1', 'b2'});
    });

    actionTest('selected campers: cancelling the period prompt runs nothing', () async {
      await actions.smartAssign(sessionId: 's1', schedule: schedule, everyone: [ada, bo], selected: [ada]);
      expect(assignment.runs, isEmpty);
    });

    actionTest('warns about slots that could not be filled and returns the report for download', () async {
      assignment.report = const AssignmentRunReport(
        assignedCount: 3,
        placementCount: 3,
        stalemates: [Stalemate(participantId: 'x', periodId: 'b1', reason: 'full')],
        evaluationReports: [],
        stepReports: [],
      );
      final report = await actions.smartAssign(sessionId: 's1', schedule: schedule, everyone: [ada, bo]);
      expect(report?.hasStalemates, isTrue);
      expect(popups.messages(ToastType.warning).single, '1 slot could not be filled and was left unassigned.');
    });

    actionTest('does nothing with no campers', () async {
      expect(await actions.smartAssign(sessionId: 's1', schedule: schedule, everyone: const []), isNull);
      expect(assignment.runs, isEmpty);
    });
  });

  group('rank random', () {
    const limits = PreferenceLimits(maxRequests: 3, maxVetoes: 2, maxSkillsRequests: 1, maxSkillsVetoes: 1);

    actionTest('does nothing when declined', () async {
      popups.confirmAnswer = false;
      await actions.rankRandom(campers: [ada, bo], schedule: schedule, limits: limits);
      expect(roster.preferenceCalls, isEmpty);
      expect(popups.confirmations.single.title, contains('testing'));
    });

    actionTest('gives every selected camper their own random preferences within the limits', () async {
      await actions.rankRandom(campers: [ada, bo], schedule: schedule, limits: limits);
      expect(roster.preferenceCalls.map((c) => c.camperId), [ada.id, bo.id]);
      for (final call in roster.preferenceCalls) {
        expect(call.requests, hasLength(4)); // 3 regular + 1 skills rec
        expect(call.vetoes, hasLength(3)); // 2 regular + 1 skills rec
        expect({...call.requests, ...call.vetoes}, hasLength(7));
      }
    });
  });

  group('exports', () {
    final context = RosterContext(schedule: schedule, cabinsById: {'c1': makeCabin('c1', 'Cabin 1')}, now: DateTime(2026, 7, 6));
    final view = RosterView(context);

    actionTest('saves the roster as shown as a CSV file', () async {
      final groups = view.arrange([ada, bo], sortBy: RosterColumns.lastName);
      await actions.exportCsv(
        groups: groups,
        columns: const [FieldColumn(RosterField.fullName), FieldColumn(RosterField.cabin)],
        view: view,
        grouped: false,
      );
      final saved = files.saved.single;
      expect(saved.extension, 'csv');
      expect(saved.name, startsWith('roster_'));
      expect(saved.contents, 'Full Name,Cabin\nBo Brown,Unknown cabin\nAda Lovelace,Cabin 1\n');
    });

    actionTest('saves the selected campers\' assignments as JSON', () async {
      final assigned = makeCamper(first: 'Ada', last: 'Lovelace', assignments: {'b1': 's-b1-act0'});
      await actions.exportBackup(sessionId: 's1', campers: [assigned], schedule: schedule);
      final saved = files.saved.single;
      expect(saved.extension, 'json');
      final json = jsonDecode(saved.contents) as Map<String, dynamic>;
      expect(json['sessionId'], 's1');
      expect((json['campers'] as List).single['assignments']['b1']['activity'], 'Activity 0');
    });
  });
}
