import 'dart:async';

import 'package:bessie/src/services/database_repair_service.dart';
import 'package:get/get.dart';

import '../ember_core.dart';

typedef OrganizationId = String;
typedef BranchId = String;
typedef SeasonId = String;
typedef SessionId = String;

class ClientContext extends GetxService {
  // Replace Completers with simple, late-initialized fields
  late OrganizationId organizationId;
  late BranchId branchId;
  late SeasonId seasonId;
  late SessionId sessionId;

  // For any services that relied on the Future, you can keep
  // these methods for compatibility. They now return an already-completed Future.
  Future<OrganizationId> getOrganizationId() => Future.value(organizationId);
  Future<BranchId> getBranchId() => Future.value(branchId);
  Future<SeasonId> getSeasonId() => Future.value(seasonId);
  Future<SessionId> getSessionId() => Future.value(sessionId);

  bool justMigrated = false;
}

class ContextService extends GetxService {
  PullRepository pullRepo = Get.find<PullRepository>();
  CommitRepository commitRepo = Get.find<CommitRepository>();
  final ClientContext clientContext = Get.find<ClientContext>();

  Future<Session> get session async => pullRepo.getObject(await clientContext.getSessionId());
  Future<Schedule> get schedule async => (await pullRepo.getObjectsInCollection<Schedule>('schedule', 'ses')).values.first;
  Future<String> get sessionName async => await pullRepo.getFieldValue(clientContext.sessionId, 'name');
  Future<String> get seasonName async => await pullRepo.getFieldValue(clientContext.seasonId, 'name');

  /// Resolves the organization, branch, season, and session the client starts in.
  ///
  /// Bessie runs one deployment per camp, so the active organization, branch,
  /// and season are the records held in the backend, and the starting session
  /// is the one closest to the current date.
  Future<void> setDefaultContext() async {
    if (clientContext.justMigrated) {
      clientContext.justMigrated = false;
      return;
    }

    clientContext.organizationId = await _activeDomainId('organization', 'rot');
    clientContext.branchId = await _activeDomainId('branch', 'org');
    clientContext.seasonId = await _activeDomainId('season', 'brn');

    final Set<Session> sessions = (await pullRepo.getObjectsInCollection<Session>('session', 'sea')).values.toSet();
    if (sessions.isEmpty) {
      throw StateError('The active season has no sessions.');
    }
    clientContext.sessionId = DateTimeHelpers.findClosest<Session>(
      items: sessions,
      getDateTime: (item) => item.start,
      roundDown: true,
    ).id;
  }

  /// Returns the id of the active [collection] record for the current deployment.
  Future<String> _activeDomainId(String collection, String prefix) async {
    final Map<String, dynamic> records = await pullRepo.getFieldFromCollection(collection, prefix, 'name');
    if (records.isEmpty) {
      throw StateError('No $collection is configured for this deployment.');
    }
    return records.keys.first;
  }

  Future<void> basicDomainCreate(Domain domain) async {
    Commit commit = Commit(disarmRequirementsLevel: 0);
    commit.addObjectToPush(domain);
    await commitRepo.commit(commit);
  }

  Future<void> migrateContext(SessionId sessionId) async {
    Session? session = await pullRepo.getObject(sessionId);
    if (session != null) {
      clientContext.sessionId = sessionId;
    } else {
      throw StateError('Attempted to migrate to a context that doesn\'t exist');
    }
    clientContext.justMigrated = true;
    FrontendManager.instance.onNewContext();
    await EmberCore.onNewContext(Get.find<DatabaseRepairService>(), Get.find<CommitRepository>());
    Get.offAllNamed('/');
  }

  Future<Map<String, String>> getSessionNames() async {
    final dynamicMap = await pullRepo.getFieldFromCollection('session', 'sea', 'name');
    return dynamicMap.map((key, value) {
      return MapEntry(key, value.toString());
    });
  }
}
