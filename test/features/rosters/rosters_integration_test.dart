@Tags(['integration'])
library;

import 'package:bessie/src/data/auth_repository.dart';
import 'package:bessie/src/data/catalog_repository.dart';
import 'package:bessie/src/data/profile_repository.dart';
import 'package:bessie/src/data/roster_repository.dart';
import 'package:bessie/src/data/session_repository.dart';
import 'package:bessie/src/features/rosters/controllers/rosters_controller.dart';
import 'package:bessie/src/models/camper.dart';
import 'package:bessie/src/services/assignment_service.dart';
import 'package:bessie/src/services/auth_service.dart';
import 'package:bessie/src/services/backup_service.dart';
import 'package:bessie/src/services/context_service.dart';
import 'package:bessie/src/services/file_service.dart';
import 'package:bessie/src/services/roster_import_service.dart';
import 'package:bessie/src/shared/services/popup_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../support/local_supabase.dart';
import 'fake_services.dart';

/// The Rosters controller against the real database: a live roster, assigning,
/// toggling arrival, deleting and the auto-assignment, all in a session of its
/// own that is removed afterwards.
void main() {
  late bool available;
  late SupabaseClient client;
  late String sessionId;
  late FakePopupService popups;
  late RostersController controller;

  Future<void> waitFor(bool Function() condition, {String reason = 'condition'}) async {
    for (var i = 0; i < 100 && !condition(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    expect(condition(), isTrue, reason: 'timed out waiting for $reason');
  }

  Camper byName(String first) => controller.campers.firstWhere((c) => c.firstName == first);

  setUpAll(() async {
    available = await localSupabaseAvailable();
    if (!available) return;
    Get.testMode = true;
    client = await signedInClient(admin);

    final auth = AuthRepository(client);
    final profiles = ProfileRepository(client);
    final catalog = CatalogRepository(client);
    final sessions = SessionRepository(client);
    final roster = RosterRepository(client);

    final branch = (await catalog.listBranches()).first;
    final season = (await catalog.listSeasons(branch.id)).first;
    final created = await sessions.createSession(
      seasonId: season.id,
      name: 'Rosters test ${DateTime.now().microsecondsSinceEpoch}',
      startsOn: DateTime(2032, 6, 7),
    );
    sessionId = created.id;

    final activities = {for (final a in await catalog.listActivities(branch.id)) a.name: a};
    final schedule = await sessions.fetchSchedule(sessionId);
    final blocks = schedule.blocks.where((b) => !b.isSkillsRec).take(2).toList();
    for (final block in blocks) {
      await sessions.scheduleActivities(
        sessionId: sessionId,
        blockId: block.id,
        activityIds: [activities['Pottery']!.id, activities['Swimming']!.id, activities['Soccer']!.id],
      );
    }
    await roster.importCampers(sessionId, [
      for (final (i, name) in ['Ada', 'Bob', 'Cy', 'Di'].indexed)
        CamperImportRow(firstName: name, lastName: 'Tester', birthdate: DateTime(2015, 1, 1 + i), cabinName: i.isEven ? 'Ernie' : null),
    ]);

    final authService = AuthService(auth, profiles);
    authService.profile.value = await profiles.fetchMine();
    final context = ContextService(catalog, profiles, authService);
    context.session.value = created;

    popups = FakePopupService();
    Get.put<RosterRepository>(roster);
    Get.put<SessionRepository>(sessions);
    Get.put(authService);
    Get.put(context);
    Get.put(AssignmentService(sessions, roster));
    Get.put(const BackupService());
    Get.put(const RosterCsvParser());
    Get.put<PopupService>(popups);
    Get.put<FileService>(FakeFileService());
    controller = Get.put(RostersController());
  });

  tearDownAll(() async {
    if (!available) return;
    controller.onNavigateFrom('/', '/other');
    await client.from('sessions').delete().eq('id', sessionId);
    Get.reset();
    await client.dispose();
  });

  test('loads the session live and shows the cabin title', () async {
    if (!available) return markTestSkipped('local Supabase is not running');
    controller.onNavigateTo('/', null);
    await waitFor(() => !controller.loading, reason: 'the roster to load');

    expect(controller.campers.map((c) => c.firstName), unorderedEquals(['Ada', 'Bob', 'Cy', 'Di']));
    expect(controller.schedule.blocks, isNotEmpty);
    final ernie = controller.view.text(byName('Ada'), controller.columns.last);
    expect(ernie, 'Ernie', reason: 'the cabin column prints the title, not the id');
  });

  test('toggle arrived reaches the database and comes back through the live roster', () async {
    if (!available) return markTestSkipped('local Supabase is not running');
    controller.toggleSelection(byName('Ada'));
    controller.toggleSelection(byName('Bob'));
    await controller.toggleArrived();
    await waitFor(() => byName('Ada').arrived && byName('Bob').arrived, reason: 'arrival to come back');
    expect(byName('Cy').arrived, isFalse);

    await controller.toggleArrived();
    await waitFor(() => !byName('Ada').arrived && !byName('Bob').arrived, reason: 'arrival to be cleared');
    controller.clearSelection();
  });

  test('assigns the selected campers to an activity and unassigns them again', () async {
    if (!available) return markTestSkipped('local Supabase is not running');
    final block = controller.schedule.blocks.firstWhere((b) => controller.schedule.scheduledIn(b.id).isNotEmpty);
    final pottery = controller.schedule.scheduledIn(block.id).firstWhere((s) => controller.activityName(s) == 'Pottery');

    controller.toggleSelection(byName('Ada'));
    controller.toggleSelection(byName('Cy'));
    controller.selectBlock(block);
    controller.selectScheduled(pottery);
    expect(controller.canAssignToSelectedActivity, isTrue);

    await controller.assignSelected();
    await waitFor(
      () => byName('Ada').assignments[block.id] == pottery.id && byName('Cy').assignments[block.id] == pottery.id,
      reason: 'assignment',
    );
    expect(controller.enrollment[pottery.id], 2);
    expect(controller.view.text(byName('Ada'), controller.columns.first), isNotEmpty);

    await controller.unassignSelectedFromActivity();
    await waitFor(() => byName('Ada').assignments.isEmpty && byName('Cy').assignments.isEmpty, reason: 'unassignment');
    controller.clearSelection();
  });

  test('smart assign fills the periods for everyone after confirming', () async {
    if (!available) return markTestSkipped('local Supabase is not running');
    popups.confirmations.clear();
    await controller.smartAssignAll();

    expect(popups.confirmations, hasLength(1), reason: 'nobody has saved preferences yet');
    expect(controller.lastRunReport, isNotNull);
    final blocksWithActivities = controller.schedule.blocks.where((b) => controller.schedule.scheduledIn(b.id).isNotEmpty).length;
    await waitFor(
      () => controller.campers.every((c) => c.assignments.length == blocksWithActivities),
      reason: 'every camper to be assigned',
    );
    expect(controller.lastRunReport!.assignedCount, 4 * blocksWithActivities);
  });

  test('delete removes the campers from the roster after confirming', () async {
    if (!available) return markTestSkipped('local Supabase is not running');
    controller.toggleSelection(byName('Di'));
    popups.confirmations.clear();
    await controller.deleteSelected();

    expect(popups.confirmations, hasLength(1));
    await waitFor(() => controller.campers.every((c) => c.firstName != 'Di'), reason: 'Di to disappear');
    expect(controller.selectedIds, isEmpty);
  });

  test('admins may edit and clearing preferences asks first', () async {
    if (!available) return markTestSkipped('local Supabase is not running');
    expect(controller.canEdit, isTrue);
    controller.toggleSelection(byName('Ada'));
    popups.confirmations.clear();
    await controller.clearPreferencesOfSelected();
    expect(popups.confirmations, hasLength(1));
    controller.clearSelection();
  });
}
