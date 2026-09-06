import 'package:bessie/src/shared/services/popup_service.dart';
import 'package:bessie/src/ember_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../../shared/mixins/route_aware_controller_mixin.dart';

typedef CabinDependantId = String;

class ActivityPreferencesControllerAbsolute extends GetxController with RouteAwareControllerMixin {
  final ContextService clientContextService = Get.find<ContextService>();
  final CabinService cabinsService = Get.find<CabinService>();
  final RosterService rosterService = Get.find<RosterService>();
  final ScheduleService scheduleService = Get.find<ScheduleService>();
  final PopupService popupService = Get.find<PopupService>();
  final ActivityPreferenceService activityPreferenceService = Get.find<ActivityPreferenceService>();
  final CommitRepository commitRepo = Get.find<CommitRepository>();

  final ScrollController scrollController = ScrollController();

  // --- State Variables ---
  List<((CabinDependent, PrincipalCabin), (List<Camper>, int))> cabinCamperData = [];
  ((CabinDependent, PrincipalCabin), (List<Camper>, int))? selectedCabinData;
  Camper? selectedCamper;

  List<(PrincipalActivity, int?)> principalActivities = [];
  int? totalActivityCount;
  final focusedActivityIndex = 0.obs;
  bool preferenceSelectionLoading = false;

  bool isCabinCamperDataLoaded = false;
  bool isActivityDataLoaded = false;
  bool showingSkillsRecs = false;
  bool cabinsOpened = true;
  bool campersOpened = true;

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  /// Determines which data to load based on whether a cabin has been selected.
  @override
  void onNavigateTo(String to, String? from) {
    setCabinsOpened(true);
    _loadActivityData(false);
    update();
  }

  @override
  void onNavigateFrom(String from, String to) {
    // Nothing here
  }

  Future<void> _loadCabinCamperData() async {
    cabinCamperData = [];
    isCabinCamperDataLoaded = false;
    update();

    final results = await Future.wait([
      cabinsService.getCabinDependentToPrincipalCabins(),
      rosterService.registeredCampers
    ]);
    final Map<CabinDependent, PrincipalCabin> cabinDepToPrinCabin = results[0] as Map<CabinDependent, PrincipalCabin>;
    final Set<Camper> campers = (results[1] as Map<String, Camper>).values.toSet();

    final List<((CabinDependent, PrincipalCabin), (List<Camper>, int))> output = [];
    for (CabinDependent cabinDependent in cabinDepToPrinCabin.keys) {
      List<Camper> cabinRoster = [];
      int camperCompletedCount = 0;
      for (Camper camper in campers) {
        if (cabinDependent.camperRefs.contains(camper.id)) {
          cabinRoster.add(camper);
          if (camper.relevantPrefsCompleted(principalActivities.map((e) => e.$1.id).toSet()) == true) {
            camperCompletedCount += 1;
          }
        }
      }
      cabinRoster.sort((a, b) => a.lastName.compareTo(b.lastName));
      output.add(((cabinDependent, cabinDepToPrinCabin[cabinDependent]!), (cabinRoster, camperCompletedCount)));
    }
    output.sort((a, b) => a.$1.$2.displayTitle.compareTo(b.$1.$2.displayTitle));
    cabinCamperData = output;
    isCabinCamperDataLoaded = true;
  }

  Future<void> _loadActivityData(bool onlySkills) async {
    if (selectedCamper == null || selectedCabinData == null) {
      return;
    }
    isActivityDataLoaded = false;
    update();

    this.principalActivities = [];
    this.totalActivityCount = null;

    Set<PrincipalActivity> principalActivities = await scheduleService.getScheduledPrincipalActivities();
    totalActivityCount = principalActivities.length;
    int hiddenCount = 0;
    principalActivities.forEach((element) {
      if (element.category == ActivityCategory.hidden) {
        hiddenCount++;
      }
    });
    totalActivityCount = totalActivityCount == null ? null : totalActivityCount! - hiddenCount;

    List<(PrincipalActivity, int?)> output = [];
    for (PrincipalActivity principalActivity in principalActivities) {
      if (principalActivity.category == ActivityCategory.hidden) {
        continue;
      }
        double? preference = selectedCamper?.preferenceRefs[principalActivity.id];
        int? preferenceAsInt = preference == null ? null : (preference * 10).round();
        output.add(((principalActivity, preferenceAsInt)));
    }

    output.sort((a, b) => a.$1.displayTitle.compareTo(b.$1.displayTitle));

    this.principalActivities = output;

    isActivityDataLoaded = true;
    preferenceSelectionLoading = false;
  }

  Future<void> setCabinsOpened(bool value) async {
    if (campersOpened && value == true) {
      campersOpened = false;
      update();
    }
    cabinsOpened = value;
    update();
    if (value == true) {
      await _loadCabinCamperData();
      update();
    }
  }

  Future<void> setCampersOpened(bool value) async {
    if (cabinsOpened) return;
    campersOpened = value;
    update();
    if (value == true) {
      await _loadCabinCamperData();
      update();
    }
  }

  Future<void> setSelectedCabinData(((CabinDependent, PrincipalCabin), (List<Camper>, int))? value) async {
    selectedCabinData = value;
    cabinsOpened = false;
    campersOpened = true;
    selectedCamper = selectedCabinData!.$2.$1.first;
    isActivityDataLoaded = false;
    await _loadCabinCamperData();
    update();
    await _loadActivityData(false);
    update();
  }

  Future<void> setSelectedCamper(Camper? value) async {
    selectedCamper = value;
    await _loadActivityData(false);
    update();
  }

  Future<void> showActivityInfo(PrincipalActivityId principalActivityId) async {
    final activity = await activityPreferenceService.getPrincipalActivity(principalActivityId);
    popupService.showActivityInfo(activity);
  }

  void setShowingSkillsRecs(bool state) {
    showingSkillsRecs = state;
    update();
  }

  void onPageChanged(int index) {
    focusedActivityIndex.value = index;
  }

  void setFocusedActivityIndex(int value) {
    if (value < 0 || value >= principalActivities.length) {
      return;
    }
    focusedActivityIndex.value = value;
    final double slotHeight = 76.0 + (4.0 * 2); // From cardousel.dart: _kCollapsedHeight + (_kMinVerticalMargin * 2)
    scrollController.animateTo(
      value * slotHeight,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  Future<void> setActivityPreference(int index, double? preference) async {
    if (selectedCamper == null || (preference != null && preference < 0.0) || (preference != null && preference > 1.0)) return;
    Commit commit = Commit(disarmRequirementsLevel: 0);
    selectedCamper?.preferenceRefs[principalActivities[index].$1.id] = preference;
    principalActivities[index] = (principalActivities[index].$1, preference == null ? null : (preference * 10).round());
    preferenceSelectionLoading = true;
    update();
    await activityPreferenceService.setActivityPreference(
      commit: commit,
      camperId: selectedCamper!.id,
      principalActivityId: principalActivities[index].$1.id,
      preference: preference,
    );
    await commitRepo.commit(commit);
    preferenceSelectionLoading = false;
    update();
    if (index + 1 < principalActivities.length && principalActivities[index + 1].$2 == null) {
      setFocusedActivityIndex(index + 1);
    }
  }
}
