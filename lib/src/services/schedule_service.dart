import 'dart:math';

import 'package:get/get.dart';

import '../ember_core.dart';

class ScheduleService extends GetxService {
  PullRepository pullRepo = Get.find<PullRepository>();
  ContextService clientContextService = Get.find<ContextService>();
  RosterService rosterService = Get.find<RosterService>();

  Future<Schedule> get schedule async => await clientContextService.schedule;
  Future<Set<ScheduleDay>> get scheduleDays async =>
      (await pullRepo.getObjectsInCollection<ScheduleDay>('schedule_day', 'ses')).values.toSet();
  Future<Set<AMABlock>> get amas async => (await pullRepo.getObjectsInCollection<AMABlock>('ama_block', 'ses')).values.toSet();
  Future<Set<ActivityDependent>> get activityDependents async =>
      (await pullRepo.getObjectsInCollection<ActivityDependent>('activity_dependent', 'ses')).values.toSet();
  Future<Map<PrincipalActivityId, PrincipalActivity>> get principalActivities async =>
      await pullRepo.getObjectsInCollection('principal_activity', 'brn');

  Future<Set<Session>> getSessions() async {
    return (await pullRepo.getObjectsInCollection('session', 'sea')).values.toSet() as Set<Session>;
  }

  Future<List<dynamic>> getActivityData() async {
    return await Future.wait([amas, activityDependents, principalActivities]);
  }

  Future<Set<String>> getSkillsActivityIds() async {
    Schedule schedule = await clientContextService.schedule;
    Set<PrincipalActivity> scheduledPrincipalActivities = await pullRepo.getObjects(schedule.principalActivityRefs);
    final Set<String> output = {};
    for (PrincipalActivity activity in scheduledPrincipalActivities) {
      if (activity.isSkillsRec) {
        output.add(activity.id);
      }
    }
    return output;
  }

  // if onlySkillsRecs is false, skills recs will not be fetched
  Future<Map<PrincipalActivityId, String>> getScheduledPrincipalActivitiesToNames(bool onlySkillsRecs) async {
    Schedule schedule = await clientContextService.schedule;
    Set<String> scheduledPrincipalActivityIds = schedule.principalActivityRefs;
    Set<PrincipalActivity> scheduledPrincipalActivities = await pullRepo.getObjects(scheduledPrincipalActivityIds);
    Map<PrincipalActivityId, String> scheduledPrincipalActivityMap = {};
    for (PrincipalActivity activity in scheduledPrincipalActivities) {
      if (activity.isSkillsRec == onlySkillsRecs) {
        scheduledPrincipalActivityMap[activity.id] = activity.name;
      }
    }
    return scheduledPrincipalActivityMap;
  }

  // if onlySkillsRecs is false, skills recs will not be fetched
  Future<Set<PrincipalActivity>> getScheduledPrincipalActivities() async {
    Schedule schedule = await clientContextService.schedule;
    Set<String> scheduledPrincipalActivityIds = schedule.principalActivityRefs;
    return await pullRepo.getObjects(scheduledPrincipalActivityIds);
  }

  Future<List<Map<ActivityDependent, PrincipalActivity>>> getActivities() async {
    final results = await Future.wait([clientContextService.schedule, activityDependents, principalActivities]);
    Schedule schedule = results[0] as Schedule;
    Set<ActivityDependent> activityDependentList = results[1] as Set<ActivityDependent>;
    Map<PrincipalActivityId, PrincipalActivity> principalActivityMap = results[2] as Map<PrincipalActivityId, PrincipalActivity>;

    Map<ActivityDependent, PrincipalActivity> standard = {};
    Map<ActivityDependent, PrincipalActivity> skills = {};

    for (ActivityDependent activityDependent in activityDependentList) {
      final PrincipalActivity? principal = principalActivityMap[activityDependent.principalPar];
      if (principal != null && schedule.principalActivityRefs.contains(principal.id)) {
        if (principal.isSkillsRec == true) {
          skills[activityDependent] = principal;
        } else if (principal.isSkillsRec == false) {
          standard[activityDependent] = principal;
        }
      }
    }

    return [standard, skills];
  }

  Future<List<PrincipalActivityId>> getOrderedActivities(CamperId camperId, bool onlySkillsRecs) async {
    final results = await Future.wait([pullRepo.getObject(camperId), clientContextService.schedule, getSkillsActivityIds()]);
    final Camper camper = results[0] as Camper;
    final Schedule schedule = results[1] as Schedule;
    final List<String> skillsActivityIds = (results[2] as Set<String>).toList();

    final List<MapEntry<PrincipalActivityId, double?>> entries = camper.preferenceRefs.entries.toList();
    if (onlySkillsRecs) {
      entries.removeWhere((element) => !skillsActivityIds.contains(element.key));
    } else {
      entries.removeWhere((element) => skillsActivityIds.contains(element.key));
    }

    if (ModelHelperFunctions.preferenceCompleted(camper, schedule)) {
      entries.sort((entryA, entryB) {
        final double? scoreA = entryA.value;
        final double? scoreB = entryB.value;

        // Handle null cases: nulls are considered lower than any number
        if (scoreA == null && scoreB == null) {
          return 0; // Keep original relative order if both are null
        } else if (scoreA == null) {
          return 1; // scoreA (null) is considered smaller, should come after scoreB
        } else if (scoreB == null) {
          return -1; // scoreB (null) is considered smaller, scoreA should come before it
        } else {
          // Both scores are non-null, compare them in descending order
          // Using compareTo: B.compareTo(A) gives descending order
          return scoreB.compareTo(scoreA);
        }
      });
      return entries.map((entry) => entry.key).toList();
    } else {
      // If the camper hasn't already set their preferences, return the activities in a random order
      final List<PrincipalActivityId> activityIds = entries.map((e) => e.key).toList();
      activityIds.shuffle(Random());
      return activityIds;
    }
  }

  Future<void> addBlockToDay(Commit commit, String scheduleDayToAddToId, ScheduleBlock blockToAdd) async {
    ScheduleDay day = commit.getObject(scheduleDayToAddToId) ?? await pullRepo.getObject(scheduleDayToAddToId);
    day.blockCmps.add(blockToAdd.id);
    commit.addObjectsToPush({blockToAdd, day});
  }

  Future<void> scheduleAMABlock(
    Commit commit,
    String name,
    String scheduleDayId,
    DateTime start,
    DateTime end,
    bool isSkillsRec,
  ) async {
    // TODO: infer the day from the start and end
    //  TODO: Add robust checking to make sure the AMA block doesn't overlap with other blocks or span days
    AMABlock amaBlockToCreate = AMABlock(title: name, isTemplate: false, start: start, end: end, isSkillsRec: isSkillsRec);
    commit.addObjectToPush(amaBlockToCreate);
    Schedule schedule = commit.getObjectOfType() ?? await clientContextService.schedule; // TODO: Remove this
    addBlockToDay(commit, schedule.scheduleDayCmps.first, amaBlockToCreate);
  }

  void createPrincipalActivity(Commit commit, String name, int capacity, String description, bool isSkillsRec, ActivityCategory category) {
    // TODO: Check with a query to make sure name is unique
    PrincipalActivity activityToCreate = PrincipalActivity(
      name: name,
      capacity: capacity,
      description: description,
      isSkillsRec: isSkillsRec,
      category: category,
    );
    commit.addObjectToPush(activityToCreate);
  }

  Future<void> scheduleActivity(Commit commit, String principalActivityId, String blockToAddToId) async {
    PrincipalActivity principalActivity =
        commit.getObject(principalActivityId) ?? (await pullRepo.getObject(principalActivityId));
    AMABlock blockToAddTo = commit.getObject(blockToAddToId) ?? (await pullRepo.getObject(blockToAddToId));
    ActivityDependent activityToSchedule = ActivityDependent(principalPar: principalActivity.id, blockRef: blockToAddTo.id);
    blockToAddTo.activityDependentCmps.add(activityToSchedule.id);

    Schedule schedule = commit.getObjectOfType() ?? await clientContextService.schedule;
    schedule.principalActivityRefs.add(activityToSchedule.principalPar);

    commit.addObjectsToPush({activityToSchedule, blockToAddTo, schedule});
  }

  Future<Map<String, ScheduleBlock>> getScheduleBlocks() async {
    Set<ScheduleDay> scheduleDays = await this.scheduleDays;
    Set<String> blockRefs = {};
    for (ScheduleDay scheduleDay in scheduleDays) {
      blockRefs.addAll(scheduleDay.blockCmps);
    }
    Set<ScheduleBlock> blocks = await pullRepo.getObjects(blockRefs);
    Map<String, ScheduleBlock> output = {};
    for (ScheduleBlock block in blocks) {
      output[block.id] = block;
    }
    return output;
  }

  Future<void> unScheduleActivity(
    Commit commit,
    ActivityDependentId activityDependentId,
  ) async {
    ActivityDependent activityToRemove = commit.getObject(activityDependentId) ?? await pullRepo.getObject(activityDependentId);
    AMABlock blockOfActivity = commit.getObject(activityToRemove.blockRef) ?? await pullRepo.getObject(activityToRemove.blockRef);
    blockOfActivity.activityDependentCmps.remove(activityToRemove.id);
    commit.addObjectToPush(blockOfActivity);


    Set<Camper> campers = (await rosterService.registeredCampers).values.toSet();
    for (Camper camper in campers) {
      if (camper.activityAssignmentRefs.containsKey(blockOfActivity.id)) {
        camper.activityAssignmentRefs[blockOfActivity.id] = null;
        commit.addObjectToPush(camper);
      }
    }

    commit.addObjectToDelete(activityToRemove);
  }

}
