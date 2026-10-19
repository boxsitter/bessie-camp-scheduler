@Tags(['integration'])
library;

import 'package:bessie/src/core/errors.dart';
import 'package:bessie/src/features/branch_manager/branch_manager_controller.dart';
import 'package:bessie/src/features/branch_manager/catalog_logic.dart';
import 'package:bessie/src/models/activity.dart';
import 'package:bessie/src/models/enums.dart';
import 'package:bessie/src/models/camper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../support/local_supabase.dart';
import 'support/controller_env.dart';

void main() {
  late bool available;
  ControllerEnv? env;
  late BranchManagerController controller;

  setUpAll(() async {
    available = await localSupabaseAvailable();
  });

  tearDownAll(ControllerEnv.closeClients);

  Future<void> open(String email) async {
    env = await ControllerEnv.open(email);
    controller = Get.put(BranchManagerController());
    await controller.load();
  }

  tearDown(() async {
    final open = env;
    env = null;
    if (open == null) return;
    Get.delete<BranchManagerController>(force: true);
    await open.dispose();
  });

  Activity named(String name) => controller.activities.firstWhere((a) => a.name == name);

  test('loads the branch catalog', () async {
    if (!available) return markTestSkipped('local Supabase is not running');
    await open(admin);

    expect(controller.hasLoaded.value, isTrue);
    expect(controller.activities, hasLength(greaterThan(20)));
    expect(controller.cabins, hasLength(8));
    expect(controller.canEdit, isTrue);
    expect(controller.branchName, 'Main Camp');
    expect(groupCabinsByVillage(controller.cabins).map((g) => g.village), ['Pines', 'Meadow']);
  });

  group('activities', () {
    test('creates, edits and deletes an activity', () async {
      if (!available) return markTestSkipped('local Supabase is not running');
      await open(admin);
      final name = ControllerEnv.uniqueName('activity');
      final before = controller.activities.length;

      await controller.saveActivity(
        ActivityFormInput(
          name: name,
          description: ' Hand built ',
          capacity: '7',
          category: ActivityCategory.creative,
          doubleSchedule: true,
          maxAssignments: '2',
          isHidden: true,
          preferenceRequired: false,
        ),
      );

      expect(controller.activities, hasLength(before + 1));
      final created = named(name);
      expect(created.description, 'Hand built');
      expect(created.capacity, 7);
      expect(created.category, ActivityCategory.creative);
      expect(created.doubleSchedule, isTrue);
      expect(created.maxAssignments, 2);
      expect(created.isHidden, isTrue);
      expect(created.preferenceRequired, isFalse);

      await controller.saveActivity(ActivityFormInput.fromActivity(created).copyWithCapacity('9', maxAssignments: ''), editing: created);

      expect(controller.activities, hasLength(before + 1));
      final edited = named(name);
      expect(edited.id, created.id);
      expect(edited.capacity, 9);
      expect(edited.maxAssignments, isNull);
      expect((await env!.catalog.listActivities(env!.context.branchId)).firstWhere((a) => a.id == created.id).capacity, 9);

      await controller.deleteActivity(edited);

      expect(env!.popups.confirmations.single.title, 'Delete $name?');
      expect(controller.activities, hasLength(before));
      expect((await env!.catalog.listActivities(env!.context.branchId)).where((a) => a.id == created.id), isEmpty);
    });

    test('a declined delete changes nothing', () async {
      if (!available) return markTestSkipped('local Supabase is not running');
      await open(admin);
      await controller.saveActivity(ActivityFormInput(name: ControllerEnv.uniqueName('activity'), capacity: '5'));
      final created = controller.activities.firstWhere((a) => a.name.startsWith(ControllerEnv.prefix));

      env!.popups.answer = false;
      await controller.deleteActivity(created);

      expect(controller.activities.map((a) => a.id), contains(created.id));
      expect((await env!.catalog.listActivities(env!.context.branchId)).map((a) => a.id), contains(created.id));
    });

    test('the database refuses names that already exist, and the message reaches the form', () async {
      if (!available) return markTestSkipped('local Supabase is not running');
      await open(admin);

      await expectLater(
        controller.saveActivity(const ActivityFormInput(name: 'Soccer', capacity: '5')),
        throwsA(isA<AppException>().having((e) => e.message, 'message', 'That already exists.')),
      );
    });

    test('an activity that is still scheduled stays', () async {
      if (!available) return markTestSkipped('local Supabase is not running');
      await open(admin);
      await controller.saveActivity(ActivityFormInput(name: ControllerEnv.uniqueName('activity'), capacity: '5'));
      final created = controller.activities.firstWhere((a) => a.name.startsWith(ControllerEnv.prefix));
      final session = await env!.createTestSession();
      final block = (await env!.sessions.fetchSchedule(session.id)).blocks.first;
      await env!.sessions.scheduleActivities(sessionId: session.id, blockId: block.id, activityIds: [created.id]);

      await controller.deleteActivity(created);

      expect(env!.popups.confirmations, hasLength(1));
      expect(controller.activities.map((a) => a.id), contains(created.id), reason: 'the database refused');
      expect(activityStillScheduledMessage(await _deleteFailure(env!, created), created), isNotNull);
    });
  });

  group('cabins', () {
    test('creates a cabin after the existing ones and deletes it', () async {
      if (!available) return markTestSkipped('local Supabase is not running');
      await open(admin);
      final name = ControllerEnv.uniqueName('cabin');
      final highest = controller.cabins.map((c) => c.position).reduce((a, b) => a > b ? a : b);

      await controller.createCabin(CabinFormInput(name: name, displayName: ' Nickname ', village: ' Pines ', capacity: '6'));

      final created = controller.cabins.firstWhere((c) => c.name == name);
      expect(created.displayName, 'Nickname');
      expect(created.title, 'Nickname');
      expect(created.village, 'Pines');
      expect(created.capacity, 6);
      expect(created.position, highest + 1);
      expect(groupCabinsByVillage(controller.cabins).first.cabins.last.id, created.id, reason: 'listed after the other Pines cabins');

      await controller.deleteCabin(created);

      expect(controller.cabins.map((c) => c.id), isNot(contains(created.id)));
      expect((await env!.catalog.listCabins(env!.context.branchId)).map((c) => c.id), isNot(contains(created.id)));
    });

    test('deleting a cabin warns how many campers in the current session lose it', () async {
      if (!available) return markTestSkipped('local Supabase is not running');
      await open(admin);
      final name = ControllerEnv.uniqueName('cabin');
      await controller.createCabin(CabinFormInput(name: name, capacity: '6'));
      final created = controller.cabins.firstWhere((c) => c.name == name);
      final session = await env!.createTestSession();
      final everyCabin = [...(await env!.sessions.listSessionCabins(session.id)).map((c) => c.id), created.id];
      await env!.sessions.setSessionCabins(session.id, everyCabin);
      await env!.roster.importCampers(session.id, [
        CamperImportRow(firstName: 'Zed', lastName: 'Test', birthdate: DateTime(2016, 1, 2), cabinName: name),
      ]);

      env!.popups.answer = false;
      await controller.deleteCabin(created);

      expect(env!.popups.confirmations.single.message, contains('(1 camper in ${session.name})'));
      expect(controller.cabins.map((c) => c.id), contains(created.id), reason: 'declined');

      env!.popups.answer = true;
      await controller.deleteCabin(created);

      expect(controller.cabins.map((c) => c.id), isNot(contains(created.id)));
      expect((await env!.roster.fetchCampers(session.id)).single.cabinId, isNull);
    });

    test('the database refuses a cabin name that already exists', () async {
      if (!available) return markTestSkipped('local Supabase is not running');
      await open(admin);

      await expectLater(
        controller.createCabin(const CabinFormInput(name: 'Oak', capacity: '6')),
        throwsA(isA<AppException>().having((e) => e.message, 'message', 'That already exists.')),
      );
    });
  });

  test('counselors can look but not change', () async {
    if (!available) return markTestSkipped('local Supabase is not running');
    await open(counselor);
    expect(controller.canEdit, isFalse);
    expect(controller.activities, isNotEmpty, reason: 'they can still read the catalog');

    final soccer = named('Soccer');
    final cabin = controller.cabins.first;
    await controller.deleteActivity(soccer);
    await controller.deleteCabin(cabin);
    await controller.openActivityForm();
    await controller.openCabinForm();

    expect(env!.popups.confirmations, isEmpty);
    expect(controller.activities.map((a) => a.id), contains(soccer.id));
    expect(controller.cabins.map((c) => c.id), contains(cabin.id));
  });
}

/// The failure the database gives for deleting [activity] now.
Future<Object> _deleteFailure(ControllerEnv env, Activity activity) async {
  try {
    await env.catalog.deleteActivity(activity.id);
  } catch (e) {
    return e;
  }
  throw StateError('The activity was deleted');
}

extension on ActivityFormInput {
  ActivityFormInput copyWithCapacity(String capacity, {required String maxAssignments}) => ActivityFormInput(
    name: name,
    description: description,
    capacity: capacity,
    category: category,
    isSkillsRec: isSkillsRec,
    doubleSchedule: doubleSchedule,
    maxAssignments: maxAssignments,
    isHidden: isHidden,
    preferenceRequired: preferenceRequired,
  );
}
