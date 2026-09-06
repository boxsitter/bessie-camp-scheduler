// ignore_for_file: dead_code

import 'dart:async';

import 'package:bessie/src/hardcode/hardcoded_domains.dart';
import 'package:bessie/src/services/database_repair_service.dart';
import 'package:get/get.dart';

import '../ember_core.dart';
import '../hardcode/hardcoded_test_schedule.dart';

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

  // TODO: This is sketchy rn. I will still need to implement robust checks for no assigned orgs/branches and no current or existing seasons or sessions
  Future<void> setDefaultContext() async {
    bool doDomainRepair = false; // TODO: ewwww get rid of this garbage

    if (clientContext.justMigrated) {
      clientContext.justMigrated = false;
      return;
    }

    // TODO: This is really painful, fix it
    if (doDomainRepair) {
      final Map<String, dynamic> dynamicOrgNames = await pullRepo.getFieldFromCollection('organization', 'rot', 'name');
      final Map<String, String> orgNames = {};
      dynamicOrgNames.forEach((key, value) {
        if (value is String) {
          orgNames[key] = value;
        }
      });
      if (!orgNames.containsValue(HardcodedDomains.ygs.name)) {
        Debug.logWarning('YGS doesn\'t exist, recreating it');
        await basicDomainCreate(HardcodedDomains.ygs);
      }
    }
    clientContext.organizationId = HardcodedDomains.ygs.id; // TODO: THIS NEEDS TO BE FIXED BEFORE ALLOWING MULTIPLE BRANCHES AND ORGS

    if (doDomainRepair) {
      final Map<String, dynamic> dynamicBranchNames = await pullRepo.getFieldFromCollection('branch', 'org', 'name');
      final Map<String, String> branchNames = {};
      dynamicBranchNames.forEach((key, value) {
        if (value is String) {
          branchNames[key] = value;
        }
      });
      if (!branchNames.containsValue(HardcodedDomains.colman.name)) {
        Debug.logWarning('Colman doesn\'t exist, recreating it');
        await basicDomainCreate(HardcodedDomains.colman);
      }
    }
    clientContext.branchId = HardcodedDomains.colman.id;

    // Retrieve the unique active Season.
    if (doDomainRepair) {
      final Map<String, dynamic> dynamicSeasonNames = await pullRepo.getFieldFromCollection('season', 'brn', 'name');
      final Map<String, String> seasonNames = {};
      dynamicSeasonNames.forEach((key, value) {
        if (value is String) {
          seasonNames[key] = value;
        }
      });
      if (!seasonNames.containsValue(HardcodedDomains.season.name)) {
        Debug.logWarning('2025 doesn\'t exist, recreating it');
        await basicDomainCreate(HardcodedDomains.season);
        clientContext.seasonId = HardcodedDomains.season.id;
      }
    }
    clientContext.seasonId = HardcodedDomains.season.id;

    if (doDomainRepair) {
      final Map<String, dynamic> dynamicSessionNames = await pullRepo.getFieldFromCollection('session', 'sea', 'name');
      final Map<String, String> sessionNames = {};
      dynamicSessionNames.forEach((key, value) {
        if (value is String) {
          sessionNames[key] = value;
        }
      });
      if (sessionNames.isEmpty) {
        Debug.logWarning('No sessions exist, creating one');
        await basicDomainCreate(HardcodedDomains.testSession);
        clientContext.sessionId = HardcodedDomains.testSession.id;
        Commit scheduleCommit = Commit(disarmRequirementsLevel: 0);
        scheduleCommit.addObjectToPush(HardcodedTestSchedule.schedule);
        await commitRepo.commit(scheduleCommit);
      } else {
        clientContext.sessionId = await pullRepo.getActiveObjectId('session', 'sea');
      }
    } else {
      Set<Session> sessions = (await pullRepo.getObjectsInCollection<Session>('session', 'sea')).values.toSet();
      clientContext.sessionId = DateTimeHelpers.findClosest<Session>(items: sessions, getDateTime: (item) => item.start, roundDown: true).id;
      // clientContext.sessionId = HardcodedSessionA.sessionA.id;
    }
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
