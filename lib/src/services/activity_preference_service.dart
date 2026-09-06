import 'dart:math';

import 'package:get/get.dart';

import '../ember_core.dart';

class ActivityPreferenceService extends GetxService {
  RosterService rosterService = Get.find<RosterService>();
  PullRepository pullRepo = Get.find<PullRepository>();

  // follows the rules of the simple assignment algorithm
  Future<void> setRanking({
    required Commit commit,
    required CamperId camperId,
    required List<PrincipalActivityId> orderedPrincipalActivityIds,
  }) async {
    Camper camper = commit.getObject(camperId) ?? await pullRepo.getObject(camperId);

    int position = 0;
    int totalPositions = orderedPrincipalActivityIds.length - 1;
    List<PrincipalActivityId> invertedList = orderedPrincipalActivityIds.reversed.toList();
    for (PrincipalActivityId principalActivityId in invertedList) {
      camper.preferenceRefs[principalActivityId] = position / totalPositions;
      position++;
    }

    commit.addObjectToPush(camper);
  }

  Future<void> setActivityPreference({
    required Commit commit,
    required CamperId camperId,
    required PrincipalActivityId principalActivityId,
    required double? preference,
  }) async {
    Camper camper = commit.getObject(camperId) ?? await pullRepo.getObject(camperId);
    camper.preferenceRefs[principalActivityId] = preference;

    commit.addObjectToPush(camper);
  }

  Future<void> setMultipleActivityPreferences({
    required Commit commit,
    required Map<CamperId, Map<PrincipalActivityId, double?>> preferences,
  }) async {
    final Set<Camper> campers = await pullRepo.getObjects(preferences.keys.toSet());
    for (Camper camper in campers) {
      camper.preferenceRefs.clear();
      camper.preferenceRefs.addEntries(preferences[camper.id]!.entries);
      commit.addObjectToPush(camper);
    }
  }

  Future<void> clearPreference(Commit commit, CamperId camperId) async {
    Camper camper = commit.getObject(camperId) ?? await pullRepo.getObject(camperId);

    camper.preferenceRefs.forEach((key, value) {
      camper.preferenceRefs[key] = null;
      camper.preferenceWeightRefs[key] = 0;
    });

    commit.addObjectToPush(camper);
  }

  // assigns all campers a random preference for each activity
  // for testing
  Future<void> rankRandom(Commit commit, CamperId camperId) async {
    Camper camper = commit.getObject(camperId) ?? await pullRepo.getObject(camperId);
    if (camper.cabinRef == null) return;
    final random = Random();

    camper.preferenceRefs.forEach((key, value) {
      if (value == null) {
        camper.preferenceRefs[key] = random.nextDouble();
      }
    });

    commit.addObjectToPush(camper);
  }

  Future<PrincipalActivity> getPrincipalActivity(PrincipalActivityId id) {
    return pullRepo.getObject(id);
  }
}
