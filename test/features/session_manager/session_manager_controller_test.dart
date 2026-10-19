@Tags(['integration'])
library;

import 'package:bessie/src/core/errors.dart';
import 'package:bessie/src/features/session_manager/session_manager_controller.dart';
import 'package:bessie/src/features/session_manager/session_setup_logic.dart';
import 'package:bessie/src/models/camp_session.dart';
import 'package:bessie/src/models/camper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../support/local_supabase.dart';
import '../branch_manager/support/controller_env.dart';

void main() {
  late bool available;
  ControllerEnv? env;
  late CampSession session;
  late SessionManagerController controller;

  setUpAll(() async {
    available = await localSupabaseAvailable();
  });

  tearDownAll(ControllerEnv.closeClients);

  /// Opens the page as [email], on a throwaway session unless that account may not create one.
  Future<void> open(String email, {bool throwaway = true}) async {
    env = await ControllerEnv.open(email);
    session = throwaway ? await env!.createTestSession() : env!.context.currentSession;
    controller = Get.put(SessionManagerController());
    await controller.reload();
  }

  tearDown(() async {
    final open = env;
    env = null;
    if (open == null) return;
    Get.delete<SessionManagerController>(force: true);
    await open.dispose();
  });

  Future<Camper> addCamper(String cabinName, {String first = 'Zed'}) async {
    await env!.roster.importCampers(session.id, [
      CamperImportRow(firstName: first, lastName: 'Test', birthdate: DateTime(2016, 1, 2), cabinName: cabinName),
    ]);
    return (await env!.roster.fetchCampers(session.id)).firstWhere((c) => c.firstName == first);
  }

  String cabinId(String name) => controller.setup.value!.cabins.firstWhere((c) => c.name == name).id;

  test('loads the current session with its cabins, schedule and campers', () async {
    if (!available) return markTestSkipped('local Supabase is not running');
    await open(admin);
    await addCamper('Oak');
    await controller.reload();

    final setup = controller.setup.value!;
    expect(setup.session.id, session.id);
    expect(setup.cabins, hasLength(8));
    expect(setup.registeredCabinIds, hasLength(8));
    expect(controller.selectedCabinIds, setup.registeredCabinIds);
    expect(setup.blockCount, 10);
    expect(setup.camperCount, 1);
    expect(setup.campersByCabin, {cabinId('Oak'): 1});
    expect(setup.activities, hasLength(greaterThan(20)));
    expect(controller.limitsDraft.value, LimitsDraft.fromLimits(session.limits));
    expect(controller.canEdit, isTrue);
    expect(controller.loadError.value, isNull);
    expect(controller.isLoading.value, isFalse);
  });

  test('switching sessions never shows the previous session\'s data', () async {
    if (!available) return markTestSkipped('local Supabase is not running');
    await open(admin);
    final other = env!.context.sessions.firstWhere((s) => s.id != session.id);

    env!.context.session.value = other;
    expect(controller.setup.value, isNull, reason: 'cleared at once, before the new data arrives');
    await controller.reload();

    expect(controller.setup.value!.session.id, other.id);
    expect(controller.selectedCabinIds, controller.setup.value!.registeredCabinIds);
  });

  group('cabins', () {
    test('saves exactly the ticked cabins without asking when nobody is affected', () async {
      if (!available) return markTestSkipped('local Supabase is not running');
      await open(admin);

      controller.toggleCabin(cabinId('Oak'));
      expect(controller.selectedCabinIds, hasLength(7));
      await controller.saveCabins();

      expect(env!.popups.confirmations, isEmpty);
      final stored = await env!.sessions.listSessionCabins(session.id);
      expect(stored.map((c) => c.name), isNot(contains('Oak')));
      expect(stored, hasLength(7));
      expect(controller.setup.value!.registeredCabinIds, hasLength(7));
      expect(controller.isSaving.value, isFalse);
    });

    test('confirms with the number of campers who would lose their cabin', () async {
      if (!available) return markTestSkipped('local Supabase is not running');
      await open(admin);
      final camper = await addCamper('Maple');
      await controller.reload();

      controller.toggleCabin(cabinId('Maple'));
      env!.popups.answer = false;
      await controller.saveCabins();

      expect(env!.popups.confirmations.single.message, contains('1 camper will be left without a cabin'));
      expect(
        (await env!.sessions.listSessionCabins(session.id)).map((c) => c.name),
        contains('Maple'),
        reason: 'declined, so nothing changed',
      );
      expect(controller.selectedCabinIds, isNot(contains(cabinId('Maple'))), reason: 'the unsaved choice is kept');

      env!.popups.answer = true;
      await controller.saveCabins();

      expect((await env!.sessions.listSessionCabins(session.id)).map((c) => c.name), isNot(contains('Maple')));
      final campers = await env!.roster.fetchCampers(session.id);
      expect(campers.firstWhere((c) => c.id == camper.id).cabinId, isNull, reason: 'the camper stays on the roster without a cabin');
    });

    test('resetting drops unsaved choices', () async {
      if (!available) return markTestSkipped('local Supabase is not running');
      await open(admin);

      controller.setCabinsSelected([cabinId('Oak'), cabinId('Fox')], false);
      expect(controller.selectedCabinIds, hasLength(6));
      controller.resetCabins();

      expect(controller.selectedCabinIds, controller.setup.value!.registeredCabinIds);
    });

    test('unsaved choices survive a reload of the same session', () async {
      if (!available) return markTestSkipped('local Supabase is not running');
      await open(admin);

      controller.toggleCabin(cabinId('Oak'));
      await controller.reload();

      expect(controller.selectedCabinIds, isNot(contains(cabinId('Oak'))));
    });
  });

  group('preference limits', () {
    test('saves the limits and tells the rest of the app', () async {
      if (!available) return markTestSkipped('local Supabase is not running');
      await open(admin);

      controller.setLimits(controller.limitsDraft.value.copyWith(maxRequests: 6, maxSkillsVetoes: 0));
      await controller.saveLimits();
      await controller.reload();

      final stored = (await env!.sessions.fetchSession(session.id)).limits;
      expect(stored.maxRequests, 6);
      expect(stored.maxSkillsVetoes, 0);
      expect(env!.context.session.value!.limits.maxRequests, 6, reason: 'the context reflects it for every page');
      expect(controller.setup.value!.session.limits.maxRequests, 6);
      expect(controller.limitsDraft.value, LimitsDraft.fromLimits(stored));
    });

    test('resetting restores the saved limits', () async {
      if (!available) return markTestSkipped('local Supabase is not running');
      await open(admin);

      controller.setLimits(controller.limitsDraft.value.copyWith(maxVetoes: 9));
      controller.resetLimits();

      expect(controller.limitsDraft.value, LimitsDraft.fromLimits(session.limits));
    });
  });

  group('schedule', () {
    test('schedules activities in a block, and removing one tells how many campers lose it', () async {
      if (!available) return markTestSkipped('local Supabase is not running');
      await open(admin);
      final setup = controller.setup.value!;
      final block = setup.schedule.blocks.firstWhere((b) => !b.isSkillsRec);
      final soccer = setup.activities.firstWhere((a) => a.name == 'Soccer');
      final pottery = setup.activities.firstWhere((a) => a.name == 'Pottery');

      await controller.scheduleActivities(block, [soccer.id, pottery.id]);
      final scheduled = controller.setup.value!.schedule.scheduledIn(block.id);
      expect(scheduled.map((s) => s.activityId), unorderedEquals([soccer.id, pottery.id]));

      final camper = await addCamper('Oak');
      final soccerScheduled = scheduled.firstWhere((s) => s.activityId == soccer.id);
      await env!.roster.assignCampers([camper.id], soccerScheduled.id);

      env!.popups.answer = false;
      await controller.removeActivity(block, soccerScheduled);
      expect(env!.popups.confirmations.single.message, contains('1 camper assigned to it will lose that assignment'));
      expect((await env!.sessions.fetchSchedule(session.id)).scheduledIn(block.id), hasLength(2), reason: 'declined, so nothing changed');

      env!.popups.answer = true;
      await controller.removeActivity(block, soccerScheduled);

      final after = await env!.sessions.fetchSchedule(session.id);
      expect(after.scheduledIn(block.id).map((s) => s.activityId), [pottery.id]);
      expect(controller.setup.value!.schedule.scheduledIn(block.id), hasLength(1));
      expect((await env!.roster.fetchCampers(session.id)).single.assignments, isEmpty);
    });

    test('says no campers are affected when nobody is assigned', () async {
      if (!available) return markTestSkipped('local Supabase is not running');
      await open(admin);
      final block = controller.setup.value!.schedule.blocks.first;
      final arts = controller.setup.value!.activities.firstWhere((a) => a.name == 'Arts & Crafts');
      await controller.scheduleActivities(block, [arts.id]);

      await controller.removeActivity(block, controller.setup.value!.schedule.scheduledIn(block.id).single);

      expect(env!.popups.confirmations.single.message, contains('No campers are assigned to it.'));
      expect(controller.setup.value!.schedule.scheduledIn(block.id), isEmpty);
    });
  });

  group('new session', () {
    test('creates the session and switches to it', () async {
      if (!available) return markTestSkipped('local Supabase is not running');
      await open(admin);
      final name = ControllerEnv.uniqueName('new');

      await controller.createSession(
        NewSessionRequest(
          name: name,
          startsOn: DateTime(2031, 8, 4),
          limits: const LimitsDraft(maxRequests: 5, maxVetoes: 1, maxSkillsRequests: 4, maxSkillsVetoes: 3),
          registerAllCabins: false,
        ),
      );
      await controller.reload();

      final current = env!.context.session.value!;
      expect(current.name, name);
      expect(current.startsOn, DateTime(2031, 8, 4));
      expect(current.limits.maxRequests, 5);
      expect(current.limits.maxSkillsVetoes, 3);
      expect(controller.setup.value!.session.id, current.id);
      expect(controller.setup.value!.registeredCabinIds, isEmpty, reason: 'cabins were left for later');
      expect(controller.setup.value!.blockCount, 10, reason: 'the weekly template is copied');
      expect(controller.limitsDraft.value.maxRequests, 5);
    });

    test('refuses a name the season already has, with the database message', () async {
      if (!available) return markTestSkipped('local Supabase is not running');
      await open(admin);

      await expectLater(
        controller.createSession(
          NewSessionRequest(name: session.name, startsOn: DateTime(2031, 8, 4), limits: LimitsDraft.defaults, registerAllCabins: true),
        ),
        throwsA(isA<AppException>().having((e) => e.message, 'message', 'That already exists.')),
      );
    });
  });

  group('counselors', () {
    test('can look but not change', () async {
      if (!available) return markTestSkipped('local Supabase is not running');
      await open(counselor, throwaway: false);
      expect(controller.canEdit, isFalse);
      expect(controller.setup.value, isNotNull, reason: 'they can still read it');
      final cabinsBefore = await env!.sessions.listSessionCabins(session.id);
      final scheduledBefore = (await env!.sessions.fetchSchedule(session.id)).scheduledActivities;

      controller.toggleCabin(cabinId('Oak'));
      await controller.saveCabins();
      controller.setLimits(controller.limitsDraft.value.copyWith(maxRequests: 9));
      await controller.saveLimits();
      await controller.scheduleActivities(controller.setup.value!.schedule.blocks.first, [controller.setup.value!.activities.first.id]);

      expect(env!.popups.confirmations, isEmpty);
      expect(await env!.sessions.listSessionCabins(session.id), hasLength(cabinsBefore.length));
      expect((await env!.sessions.fetchSession(session.id)).limits.maxRequests, session.limits.maxRequests);
      expect((await env!.sessions.fetchSchedule(session.id)).scheduledActivities, hasLength(scheduledBefore.length));
    });
  });
}
