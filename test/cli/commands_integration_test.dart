@Tags(['integration'])
library;

import 'dart:convert';

import 'package:bessie/src/commands/assignment_commands.dart';
import 'package:bessie/src/commands/context_commands.dart';
import 'package:bessie/src/commands/session_commands.dart';
import 'package:bessie/src/core/errors.dart';
import 'package:bessie/src/data/auth_repository.dart';
import 'package:bessie/src/data/catalog_repository.dart';
import 'package:bessie/src/data/profile_repository.dart';
import 'package:bessie/src/data/roster_repository.dart';
import 'package:bessie/src/data/session_repository.dart';
import 'package:bessie/src/models/organization.dart';
import 'package:bessie/src/services/auth_service.dart';
import 'package:bessie/src/services/backup_service.dart';
import 'package:bessie/src/services/context_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../support/local_supabase.dart';
import 'support/fake_io.dart';
import 'support/fake_services.dart';

/// The console commands against the seeded local Supabase stack, signed in as
/// the demo admin. Everything written goes into a session of its own that is
/// deleted afterwards.
/// A day inside [season], typed the short way (`MM/DD`) so the year comes from the season.
(DateTime, String) aDayIn(Season season) {
  final day = DateTime(season.startsOn.year, season.startsOn.month, season.startsOn.day + 7);
  return (day, '${day.month}/${day.day}');
}

void main() {
  late bool available;
  late SupabaseClient client;
  late CatalogRepository catalog;
  late SessionRepository sessions;
  late RosterRepository roster;
  late AuthService auth;
  late ContextService context;
  late Map<String, dynamic> originalPreferences;
  String? createdSessionId;

  setUpAll(() async {
    available = await localSupabaseAvailable();
    if (!available) return;
    client = await signedInClient(admin);
    final profiles = ProfileRepository(client);
    catalog = CatalogRepository(client);
    sessions = SessionRepository(client);
    roster = RosterRepository(client);
    auth = AuthService(AuthRepository(client), profiles);
    await auth.init();
    originalPreferences = Map.of(auth.currentProfile.preferences);
    context = ContextService(catalog, profiles, auth);
    await context.load();
  });

  tearDownAll(() async {
    if (!available) return;
    if (createdSessionId != null) await client.from('sessions').delete().eq('id', createdSessionId!);
    // Creating a session remembers it as the user's last one; put that back.
    await client.from('profiles').update({'preferences': originalPreferences}).eq('id', auth.currentProfile.id);
    await client.dispose();
  });

  test('con, whoami, brns, seas and sess describe the seeded camp', () async {
    if (!available) return markTestSkipped('local Supabase is not running');

    final io = FakeIo();
    await ViewContext(userInput: io, userOutput: io, context: context).runWithArgs([]);
    await WhoAmI(userInput: io, userOutput: io, auth: auth, context: context).runWithArgs([]);
    await ListBranches(userInput: io, userOutput: io, context: context, catalog: catalog).runWithArgs([]);
    await ListSeasons(userInput: io, userOutput: io, context: context, catalog: catalog).runWithArgs([]);
    await ListSessions(userInput: io, userOutput: io, context: context).runWithArgs([]);

    expect(io.printed('Organization: Camp Bessie'), isTrue);
    expect(io.printed('Role: Admin'), isTrue);
    expect(io.tables[0].map((row) => row.first), contains('Main Camp'));
    expect(io.tables[1].skip(1).any((row) => row.last == 'yes'), isTrue, reason: 'the current season is marked');
    expect(io.tables[2].skip(1).any((row) => row.last == 'yes'), isTrue, reason: 'the current session is marked');
  });

  test('mksesh, addact, rmact, bka, rstact and sw work on a session of their own', () async {
    if (!available) return markTestSkipped('local Supabase is not running');
    final firstSession = context.currentSession;
    final name = 'CLI test ${DateTime.now().microsecondsSinceEpoch}';
    final (startDay, typedDay) = aDayIn(context.season.value!);

    // mksesh: MM/DD takes its year from the season.
    var io = FakeIo();
    await MakeSession(userInput: io, userOutput: io, context: context, sessions: sessions).runWithArgs([name, typedDay]);
    final created = context.currentSession;
    createdSessionId = created.id;
    expect(created.name, name);
    expect(created.startsOn, startDay);
    expect(context.sessions.map((s) => s.id), contains(created.id));
    var schedule = await sessions.fetchSchedule(created.id);
    expect(schedule.blocks, isNotEmpty, reason: 'the branch templates were applied');

    // addact: one standard and one skills-rec activity into a block.
    final activities = await catalog.listActivities(context.branchId);
    final standard = activities.firstWhere((a) => !a.isSkillsRec);
    final skills = activities.firstWhere((a) => a.isSkillsRec);
    final block = schedule.blocks.first;
    io = FakeIo(
      forms: [
        [block],
        [
          [standard],
          [skills],
        ],
      ],
    );
    await AddActivities(userInput: io, userOutput: io, context: context, sessions: sessions, catalog: catalog).runWithArgs([]);
    schedule = await sessions.fetchSchedule(created.id);
    expect(schedule.scheduledIn(block.id).map((s) => s.activityId), unorderedEquals([standard.id, skills.id]));

    // rmact: remove the standard one, after confirming.
    final scheduledStandard = schedule.scheduledIn(block.id).firstWhere((s) => s.activityId == standard.id);
    io = FakeIo(
      forms: [
        [block],
        [
          [scheduledStandard],
        ],
      ],
      confirmations: [true],
    );
    await RemoveActivities(userInput: io, userOutput: io, context: context, sessions: sessions).runWithArgs([]);
    schedule = await sessions.fetchSchedule(created.id);
    expect(schedule.scheduledIn(block.id).map((s) => s.activityId), [skills.id]);

    // bka: a backup of the new session.
    final files = FakeFileService();
    io = FakeIo();
    await BackupActivityAssignments(
      userInput: io,
      userOutput: io,
      context: context,
      sessions: sessions,
      roster: roster,
      backup: const BackupService(),
      files: files,
    ).runWithArgs(['--all']);
    expect(files.saved, hasLength(1));
    expect((jsonDecode(files.saved.single.contents) as Map)['sessionId'], created.id);

    // rstact: nothing to reset in an empty session, but the call must go through.
    io = FakeIo(confirmations: [true]);
    await ResetActivityAssignments(userInput: io, userOutput: io, context: context, roster: roster).runWithArgs(['--preferences']);
    expect(io.printed('success: Cleared the assignments and preferences'), isTrue);

    // sw: back to where we were.
    io = FakeIo();
    await SwitchSession(userInput: io, userOutput: io, context: context).runWithArgs([firstSession.name]);
    expect(context.currentSession.id, firstSession.id);
  });

  test('the database stops a counselor who runs a writing command', () async {
    if (!available) return markTestSkipped('local Supabase is not running');
    final counselorClient = await signedInClient(counselor);
    addTearDown(counselorClient.dispose);
    final profiles = ProfileRepository(counselorClient);
    final counselorAuth = AuthService(AuthRepository(counselorClient), profiles);
    await counselorAuth.init();
    final counselorContext = ContextService(CatalogRepository(counselorClient), profiles, counselorAuth);
    await counselorContext.load();

    final io = FakeIo();
    final command = MakeSession(userInput: io, userOutput: io, context: counselorContext, sessions: SessionRepository(counselorClient));

    await expectLater(
      command.runWithArgs(['Counselor attempt ${DateTime.now().microsecondsSinceEpoch}', aDayIn(counselorContext.season.value!).$2]),
      throwsA(isA<AppException>().having((e) => e.message, 'message', contains('permission'))),
    );
  });
}
