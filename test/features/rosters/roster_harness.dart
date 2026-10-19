import 'package:bessie/src/data/auth_repository.dart';
import 'package:bessie/src/data/catalog_repository.dart';
import 'package:bessie/src/data/profile_repository.dart';
import 'package:bessie/src/data/roster_repository.dart';
import 'package:bessie/src/data/session_repository.dart';
import 'package:bessie/src/features/rosters/controllers/rosters_controller.dart';
import 'package:bessie/src/models/camp_session.dart';
import 'package:bessie/src/models/camper.dart';
import 'package:bessie/src/models/enums.dart';
import 'package:bessie/src/models/schedule.dart';
import 'package:bessie/src/models/staff_profile.dart';
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

import 'fake_repositories.dart';
import 'roster_fixtures.dart';

CampSession fakeSession(String id) => CampSession(
  id: id,
  seasonId: 'season',
  name: 'Session $id',
  startsOn: DateTime(2026, 7, 6),
  limits: const PreferenceLimits(maxRequests: 3, maxVetoes: 2, maxSkillsRequests: 1, maxSkillsVetoes: 1),
);

StaffProfile fakeProfile(StaffRole role) => StaffProfile(
  id: 'user',
  organizationId: 'org',
  firstName: 'Test',
  lastName: 'User',
  preferredName: null,
  role: role,
  active: true,
  preferences: const {},
);

/// A [RostersController] wired to fake repositories, the way the app's
/// bindings wire the real ones.
class RostersHarness {
  RostersHarness() {
    Get.testMode = true;
    client = SupabaseClient('http://127.0.0.1:1', 'anon-key', authOptions: const AuthClientOptions(autoRefreshToken: false));
    roster = FakeRosterRepository(client);
    sessions = FakeSessionRepository(client)
      ..schedules['s1'] = singleBlockSchedule('s1-b1')
      ..schedules['s2'] = singleBlockSchedule('s2-b1')
      ..cabins['s1'] = [makeCabin('c1', 'Cabin 1', displayName: 'Eagles')];
    auth = AuthService(AuthRepository(client), ProfileRepository(client));
    context = ContextService(CatalogRepository(client), ProfileRepository(client), auth);

    Get.put<RosterRepository>(roster);
    Get.put<SessionRepository>(sessions);
    Get.put(auth);
    Get.put(context);
    Get.put(AssignmentService(sessions, roster));
    Get.put(const FileService());
    Get.put(const BackupService());
    Get.put(const RosterCsvParser());
    Get.put(PopupService());
    controller = Get.put(RostersController());
  }

  late final SupabaseClient client;
  late final FakeRosterRepository roster;
  late final FakeSessionRepository sessions;
  late final AuthService auth;
  late final ContextService context;
  late final RostersController controller;

  static Schedule singleBlockSchedule(String blockId) => makeSchedule(
    blocks: [makeBlock(blockId, 'AM1')],
    activities: [makeActivity('a1', 'Archery')],
    scheduled: {'$blockId-a1': (blockId, 'a1')},
  );

  /// Signs in as [role], opens session `s1`, shows the page and emits [campers].
  Future<void> start({StaffRole role = StaffRole.director, required List<Camper> campers}) async {
    auth.profile.value = fakeProfile(role);
    context.session.value = fakeSession('s1');
    controller.onNavigateTo('/', null);
    await pumpEventQueue();
    roster.latest.add(campers);
    await pumpEventQueue();
  }

  Future<void> dispose() async {
    Get.reset();
    await client.dispose();
  }
}
