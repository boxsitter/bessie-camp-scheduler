@Tags(['integration'])
library;

import 'package:bessie/src/data/auth_repository.dart';
import 'package:bessie/src/data/catalog_repository.dart';
import 'package:bessie/src/data/profile_repository.dart';
import 'package:bessie/src/data/roster_repository.dart';
import 'package:bessie/src/data/session_repository.dart';
import 'package:bessie/src/features/activity_preferences/controllers/activity_preferences_controller.dart';
import 'package:bessie/src/models/activity.dart';
import 'package:bessie/src/models/camp_session.dart';
import 'package:bessie/src/models/camper.dart';
import 'package:bessie/src/models/enums.dart';
import 'package:bessie/src/services/auth_service.dart';
import 'package:bessie/src/services/context_service.dart';
import 'package:bessie/src/shared/services/popup_service.dart';
import 'package:bessie/src/shared/widgets/header/controllers/menu_bar_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../support/local_supabase.dart';

/// The preferences flow against the real local database, with the controller
/// signed in as a counselor (who may save preferences but nothing else).
void main() {
  late bool available;
  late SupabaseClient adminClient;
  late SupabaseClient counselorClient;
  late SessionRepository adminSessions;
  late RosterRepository adminRoster;
  late CampSession session;
  late Map<String, Activity> activities;
  late ActivityPreferencesController controller;

  Future<void> until(bool Function() condition, {String reason = 'condition'}) async {
    final deadline = DateTime.now().add(const Duration(seconds: 10));
    while (!condition()) {
      if (DateTime.now().isAfter(deadline)) fail('Timed out waiting for $reason');
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  setUpAll(() async {
    available = await localSupabaseAvailable();
    if (!available) return;
    adminClient = await signedInClient(admin);
    counselorClient = await signedInClient(counselor);
    final catalog = CatalogRepository(adminClient);
    adminSessions = SessionRepository(adminClient);
    adminRoster = RosterRepository(adminClient);

    final branch = (await catalog.listBranches()).first;
    final season = (await catalog.listSeasons(branch.id)).first;
    session = await adminSessions.createSession(
      seasonId: season.id,
      name: 'Preferences test ${DateTime.now().microsecondsSinceEpoch}',
      startsOn: DateTime(2032, 6, 7),
    );
    activities = {for (final a in await catalog.listActivities(branch.id)) a.name: a};

    final block = (await adminSessions.fetchSchedule(session.id)).blocks.firstWhere((b) => !b.isSkillsRec);
    await adminSessions.scheduleActivities(
      sessionId: session.id,
      blockId: block.id,
      activityIds: [for (final n in ['Soccer', 'Kayaking', 'Canoeing', 'Pottery']) activities[n]!.id],
    );
    await adminRoster.importCampers(session.id, [
      CamperImportRow(firstName: 'Ada', lastName: 'Lovelace', birthdate: DateTime(2016, 5, 5), cabinName: 'oak'),
      CamperImportRow(firstName: 'Bob', lastName: 'Builder', birthdate: DateTime(2015, 1, 9), cabinName: 'oak'),
    ]);
  });

  tearDownAll(() async {
    if (!available) return;
    await adminClient.from('sessions').delete().eq('id', session.id);
    await adminClient.dispose();
    await counselorClient.dispose();
  });

  setUp(() async {
    if (!available) return;
    Get.reset();
    Get.put<RosterRepository>(RosterRepository(counselorClient));
    Get.put<SessionRepository>(SessionRepository(counselorClient));
    Get.put<ContextService>(
      ContextService(
        CatalogRepository(counselorClient),
        ProfileRepository(counselorClient),
        AuthService(AuthRepository(counselorClient), ProfileRepository(counselorClient)),
      )..session.value = session,
    );
    Get.put(PopupService());
    Get.put(MenuBarController());
    controller = Get.put(ActivityPreferencesController());
  });

  tearDown(() async {
    if (!available) return;
    Get.reset();
    // Let the realtime channel close before the next test.
    await Future<void>.delayed(const Duration(milliseconds: 200));
  });

  Future<Camper> storedCamper(String firstName) async =>
      (await adminRoster.fetchCampers(session.id)).firstWhere((c) => c.firstName == firstName);

  test('collects preferences as a counselor, and the database has the last word on the limits', () async {
    if (!available) return markTestSkipped('local Supabase is not running');

    controller.onNavigateTo('/activity-preferences', null);
    await until(() => !controller.isLoading, reason: 'the page to load');
    expect(controller.loadError, isNull);
    expect(controller.cabinGroups.map((g) => g.title), ['Oak']);
    expect(controller.cabinGroups.single.total, 2);

    // The board offers exactly what the session schedules.
    controller.selectCabinGroup(controller.cabinGroups.single);
    expect(controller.selectedCamper?.firstName, 'Bob', reason: 'sorted by last name');
    expect(controller.board!.activities.map((a) => a.name), ['Canoeing', 'Kayaking', 'Pottery', 'Soccer']);

    // Save a draft.
    controller.place(activities['Soccer']!, PreferenceKind.request);
    controller.place(activities['Kayaking']!, PreferenceKind.veto);
    expect(await controller.flush(), isTrue);
    var bob = await storedCamper('Bob');
    expect(bob.requestedActivityIds, {activities['Soccer']!.id});
    expect(bob.vetoedActivityIds, {activities['Kayaking']!.id});
    expect(bob.preferencesSubmitted, isTrue);
    expect(controller.cabinGroups.single.submitted, 1);

    // The camper list follows changes made elsewhere (realtime).
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await adminRoster.setPreferences(
      camperId: (await storedCamper('Ada')).id,
      requestedActivityIds: const [],
      vetoedActivityIds: const [],
    );
    await until(() => controller.cabinGroups.single.submitted == 2, reason: 'the other camper\'s save to show up');

    // Tighten the limit behind the controller's back: the database refuses
    // the save, and the camper goes back to what is stored.
    await adminSessions.updateLimits(
      session.id,
      const PreferenceLimits(maxRequests: 1, maxVetoes: 2, maxSkillsRequests: 2, maxSkillsVetoes: 1),
    );
    controller.place(activities['Pottery']!, PreferenceKind.request);
    expect(controller.board!.requestedIds, hasLength(2), reason: 'the controller still has the old limit');
    expect(await controller.flush(), isFalse);

    expect(controller.board!.requestedIds, {activities['Soccer']!.id});
    expect(controller.hasUnsavedChanges, isFalse);
    bob = await storedCamper('Bob');
    expect(bob.requestedActivityIds, {activities['Soccer']!.id}, reason: 'the refused save changed nothing');
  });
}
