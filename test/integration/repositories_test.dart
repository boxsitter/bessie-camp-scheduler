@Tags(['integration'])
library;

import 'package:bessie/src/core/errors.dart';
import 'package:bessie/src/data/catalog_repository.dart';
import 'package:bessie/src/data/roster_repository.dart';
import 'package:bessie/src/data/session_repository.dart';
import 'package:bessie/src/models/camper.dart';
import 'package:bessie/src/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../support/local_supabase.dart';

void main() {
  late bool available;
  late SupabaseClient adminClient;
  late CatalogRepository catalog;
  late SessionRepository sessions;
  late RosterRepository roster;
  late String sessionId;

  setUpAll(() async {
    available = await localSupabaseAvailable();
    if (!available) return;
    adminClient = await signedInClient(admin);
    catalog = CatalogRepository(adminClient);
    sessions = SessionRepository(adminClient);
    roster = RosterRepository(adminClient);

    final branch = (await catalog.listBranches()).first;
    final season = (await catalog.listSeasons(branch.id)).first;
    final created = await sessions.createSession(
      seasonId: season.id,
      name: 'Repo test ${DateTime.now().microsecondsSinceEpoch}',
      startsOn: DateTime(2031, 6, 2),
      maxVetoes: 1,
    );
    sessionId = created.id;
  });

  tearDownAll(() async {
    if (!available) return;
    await adminClient.from('sessions').delete().eq('id', sessionId);
    await adminClient.dispose();
  });

  test('reads the seeded hierarchy', () async {
    if (!available) return markTestSkipped('local Supabase is not running');
    final org = await catalog.fetchOrganization();
    expect(org?.name, 'Camp Bessie');
    final branches = await catalog.listBranches();
    expect(branches.single.name, 'Main Camp');
    expect(await catalog.listActivities(branches.single.id), hasLength(greaterThan(20)));
    final cabins = await catalog.listCabins(branches.single.id);
    expect(cabins.firstWhere((c) => c.name == 'Squirt').title, 'Ernie', reason: 'display_name replaces the name');
  });

  test('createSession builds the weekly template and registers cabins', () async {
    if (!available) return markTestSkipped('local Supabase is not running');
    final schedule = await sessions.fetchSchedule(sessionId);
    expect(schedule.days, hasLength(5));
    expect(schedule.blocks, hasLength(10));
    expect(schedule.blocks.first.title, 'Choice Activity 1', reason: 'blocks are chronological');
    expect(schedule.blocks.first.start, DateTime(2031, 6, 2, 10, 15), reason: 'wall-clock times, no timezone shift');
    final skills = schedule.blocks.singleWhere((b) => b.isSkillsRec);
    expect(skills.date.weekday, DateTime.tuesday);
    expect(skills.start, DateTime(2031, 6, 3, 9, 15));
    expect(await sessions.listSessionCabins(sessionId), hasLength(8));
  });

  test('schedules activities, imports campers and assigns them', () async {
    if (!available) return markTestSkipped('local Supabase is not running');
    final branch = (await catalog.listBranches()).first;
    final activities = {for (final a in await catalog.listActivities(branch.id)) a.name: a};
    var schedule = await sessions.fetchSchedule(sessionId);
    final block = schedule.blocks.firstWhere((b) => !b.isSkillsRec);

    await sessions.scheduleActivities(
      sessionId: sessionId,
      blockId: block.id,
      activityIds: [activities['Pottery']!.id, activities['Swimming']!.id],
    );
    // Scheduling twice is harmless.
    await sessions.scheduleActivities(sessionId: sessionId, blockId: block.id, activityIds: [activities['Pottery']!.id]);
    schedule = await sessions.fetchSchedule(sessionId);
    expect(schedule.scheduledIn(block.id), hasLength(2));
    expect(schedule.activityOf(schedule.scheduledIn(block.id).first), isNotNull);

    final result = await roster.importCampers(sessionId, [
      CamperImportRow(firstName: 'Ada', lastName: 'Lovelace', birthdate: DateTime(2016, 5, 5), gender: Gender.female, cabinName: 'oak'),
      CamperImportRow(firstName: 'Bob', lastName: 'Builder', birthdate: DateTime(2015, 1, 9), cabinName: 'Ernie'),
      CamperImportRow(firstName: 'Cy', lastName: 'Young', birthdate: DateTime(2014, 2, 3), cabinName: 'Nowhere'),
      CamperImportRow(firstName: 'ada', lastName: 'LOVELACE', birthdate: DateTime(2016, 5, 5)),
    ]);
    expect(result.inserted, 3);
    expect(result.duplicates, 1);
    expect(result.unknownCabins, ['Nowhere']);

    var campers = await roster.fetchCampers(sessionId);
    expect(campers.map((c) => c.firstName), containsAll(['Ada', 'Bob', 'Cy']));
    final ada = campers.firstWhere((c) => c.firstName == 'Ada');
    expect(ada.birthdate, DateTime(2016, 5, 5), reason: 'dates round-trip without timezone drift');
    expect(ada.gender, Gender.female);
    expect(ada.cabinId, isNotNull);

    final pottery = schedule.scheduledIn(block.id).firstWhere((s) => s.activityId == activities['Pottery']!.id);
    final swimming = schedule.scheduledIn(block.id).firstWhere((s) => s.activityId == activities['Swimming']!.id);

    expect(await roster.assignCampers(campers.map((c) => c.id), pottery.id), 3);
    expect(await roster.assignCampers([ada.id], swimming.id), 1, reason: 'moved within the block');
    campers = await roster.fetchCampers(sessionId);
    expect(campers.firstWhere((c) => c.id == ada.id).assignments, {block.id: swimming.id});
    expect(campers.where((c) => c.assignments[block.id] == pottery.id), hasLength(2));

    expect(await roster.unassignCampers([ada.id], blockId: block.id), 1);
    await roster.swapCabins(campers.where((c) => c.cabinId != null).map((c) => c.id));
  });

  test('preferences are validated by the database', () async {
    if (!available) return markTestSkipped('local Supabase is not running');
    final branch = (await catalog.listBranches()).first;
    final activities = {for (final a in await catalog.listActivities(branch.id)) a.name: a};
    final schedule = await sessions.fetchSchedule(sessionId);
    final block = schedule.blocks.firstWhere((b) => !b.isSkillsRec);
    await sessions.scheduleActivities(
      sessionId: sessionId,
      blockId: block.id,
      activityIds: [activities['Soccer']!.id, activities['Kayaking']!.id, activities['Canoeing']!.id],
    );
    final camper = (await roster.fetchCampers(sessionId)).first;

    // A counselor (read-only) can still save preferences.
    final counselorClient = await signedInClient(counselor);
    final asCounselor = RosterRepository(counselorClient);
    await asCounselor.setPreferences(
      camperId: camper.id,
      requestedActivityIds: [activities['Soccer']!.id],
      vetoedActivityIds: [activities['Kayaking']!.id],
    );
    var reloaded = (await roster.fetchCampers(sessionId)).firstWhere((c) => c.id == camper.id);
    expect(reloaded.preferences, {activities['Soccer']!.id: PreferenceKind.request, activities['Kayaking']!.id: PreferenceKind.veto});
    expect(reloaded.preferencesSubmitted, isTrue);

    // The session allows one veto.
    await expectLater(
      asCounselor.setPreferences(
        camperId: camper.id,
        requestedActivityIds: const [],
        vetoedActivityIds: [activities['Kayaking']!.id, activities['Canoeing']!.id],
      ),
      throwsA(isA<AppException>().having((e) => e.message, 'message', contains('at most 1'))),
    );

    // ...but a counselor may not edit the roster itself.
    await expectLater(
      asCounselor.deleteCampers([camper.id]),
      throwsA(isA<AppException>().having((e) => e.message, 'message', contains('permission'))),
    );
    expect(await roster.fetchCampers(sessionId), contains(predicate<Camper>((c) => c.id == camper.id)));

    await roster.clearPreferences([camper.id]);
    reloaded = (await roster.fetchCampers(sessionId)).firstWhere((c) => c.id == camper.id);
    expect(reloaded.preferences, isEmpty);
    expect(reloaded.preferencesSubmitted, isFalse);
    await counselorClient.dispose();
  });

  test('watchCampers pushes live changes', () async {
    if (!available) return markTestSkipped('local Supabase is not running');
    final emissions = <List<Camper>>[];
    final subscription = roster.watchCampers(sessionId).listen(emissions.add);

    Future<void> waitFor(bool Function() condition) async {
      for (var i = 0; i < 100 && !condition(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      expect(condition(), isTrue, reason: 'timed out waiting for the roster stream');
    }

    await waitFor(() => emissions.isNotEmpty);
    expect(emissions.last, isNotEmpty);
    final target = emissions.last.first;
    final wasArrived = target.arrived;

    await roster.setArrived([target.id], !wasArrived);
    await waitFor(() => emissions.last.firstWhere((c) => c.id == target.id).arrived == !wasArrived);

    await subscription.cancel();
  });
}
