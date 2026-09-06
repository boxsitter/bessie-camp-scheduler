import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bessie/src/shared/services/popup_service.dart';
import 'package:bessie/src/features/rosters/controllers/table_widths.dart';
import 'package:bessie/src/cli/cli.dart';
import 'package:bessie/src/ember_core.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../shared/constants/colors.dart';
import '../../../shared/mixins/route_aware_controller_mixin.dart';
import '../../console/controller/console_controller.dart';

class RostersController extends GetxController with RouteAwareControllerMixin {
  // Dependencies
  final ContextService contextService = Get.find<ContextService>();
  final CabinService cabinsService = Get.find<CabinService>();
  final RosterService rosterService = Get.find<RosterService>();
  final ActivityPreferenceService preferenceService = Get.find<ActivityPreferenceService>();
  final AssignmentService assignmentService = Get.find<AssignmentService>();
  final CommitRepository commitRepo = Get.find<CommitRepository>();
  final PullRepository pullRepo = Get.find<PullRepository>();
  final ScheduleService scheduleService = Get.find<ScheduleService>();
  final PopupService popupService = Get.find<PopupService>();
  final IOService exportService = Get.find<IOService>();

  // State Variables
  // --- Core Data ---
  List<Rosterable> roster = [];
  Set<Rosterable> selectedItems = {};
  List<AMABlock> _amas = [];
  Map<PrincipalActivityId, PrincipalActivity> principalActivities = {};
  List<ActivityDependent> activityDependents = [];
  Map<String, bool> _isRosterGroupTitleExpanded = {};

  // --- Search & Filtering ---
  String searchQuery = '';
  final searchController = TextEditingController();

  // --- UI State Flags ---
  bool initializing = true;
  bool importingCampers = false;
  bool populatingActivities = false;
  bool assigningCamper = false;
  bool columnConfigOpened = false;
  bool activitySwitcherOpened = false;

  // --- Table Configuration ---
  final List<RosterField> fields = [RosterField.fullName, RosterField.gender, RosterField.age, RosterField.cabinName];
  RosterField sortByField = RosterField.lastName;
  SortDirection sortDirection = SortDirection.asc;
  RosterField? groupByField;

  // --- View Settings ---
  bool alternateRowColors = true;
  bool highContrast = false;
  bool rowSeparators = false;
  bool columnSeparators = false;
  bool compact = true;
  bool expandedByDefault = false;
  bool safeAssign = true;
  bool showAssignmentRepetition = false;
  bool showPreferenceColors = false;

  // --- Activity Switcher State ---
  AMABlock? selectedAma;
  ActivityDependent? selectedActivity;

  // Private Internal State
  Timer? _debounce;
  StreamSubscription<Map<String, Camper>>? _campersSubscription;
  static const double _checkboxColumnWidth = 50.0;

  // Computed Properties (Getters)
  List<AMABlock> get amas {
    _amas.sort((a, b) => a.start.compareTo(b.start));
    return _amas;
  }

  List<Rosterable> getFilteredRoster() {
    if (searchQuery.isEmpty) {
      return roster;
    } else {
      return roster.where((item) {
        final fullName = item.getFieldAsString(RosterField.fullName).toLowerCase();
        final nickname = item.getFieldAsString(RosterField.firstName).toLowerCase();
        return fullName.contains(searchQuery.toLowerCase()) || nickname.contains(searchQuery.toLowerCase());
      }).toList();
    }
  }

  int get count => getFilteredRoster().length;

  List<RosterField> availableFields(bool returnAmas) {
    if (returnAmas) {
      return amas.where((ama) => !fields.contains(ama)).toList();
    }
    return RosterField.values.where((field) => !fields.contains(field)).toList();
  }

  List<RosterGroup> get rosterGroups {
    if (groupByField == null) {
      return [
        RosterGroup(
          title: 'All Campers',
          items: getFilteredRoster(),
        )
      ];
    }

    final Map<String, List<Rosterable>> groupsMap = {};
    for (final item in getFilteredRoster()) {
      final groupKey = item.getFieldAsString(groupByField!);
      groupsMap.putIfAbsent(groupKey, () => []).add(item);
    }

    final List<RosterGroup> groups = groupsMap.entries.map((entry) {
      return RosterGroup(
        title: entry.key.isEmpty ? 'Unspecified' : entry.key,
        groupByField: groupByField!,
        items: entry.value,
      );
    }).toList();

    groups.sort((a, b) => a.title.compareTo(b.title));
    return groups;
  }

  // Lifecycle Methods
  @override
  Future<void> onInit() async {
    update();
    super.onInit();
    Debug.logInfo('RostersController initialized. Starting listener.');


    update();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }

  @override
  Future<void> onNavigateTo(String to, String? from) async {
    Debug.logInfo('RostersController navigated to.');
    initializing = true;
    await rosterService.camperStream.then((stream) {
      _campersSubscription?.cancel();
      _campersSubscription = stream.listen((camperMap) {
        roster = camperMap.values.toList();
        sort(sortByField);
        update();
      });
    });
    await populateActivities();
    initializing = false;
  }

  @override
  void onNavigateFrom(String to, String? from) {
    _campersSubscription?.cancel();
    Debug.logInfo('RostersController navigated from.');
  }

  // Public Methods
  Future<void> populateActivities() async {
    populatingActivities = true;
    update();
    final List<dynamic> activityData = (await scheduleService.getActivityData());
    _amas = (activityData[0] as Set<AMABlock>).toList();
    principalActivities = (activityData[2] as Map<PrincipalActivityId, PrincipalActivity>);
    activityDependents = (activityData[1] as Set<ActivityDependent>).toList();
    populatingActivities = false;
    update();
  }

  // --- Search ---

  void setSearchQuery(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 50), () {
      searchQuery = query;
      update();
    });
  }

  // --- Column, Sorting, & Grouping ---

  void setColumnOrder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = fields.removeAt(oldIndex);
    fields.insert(newIndex, item);
    update();
  }

  void addVisibleColumn(RosterField field) {
    if (!fields.contains(field)) {
      fields.add(field);
      update();
    }
  }

  void removeVisibleColumn(RosterField field) {
    if (fields.contains(field)) {
      fields.remove(field);
      update();
    }
  }

  void sort(RosterField field) {
    roster.sort((a, b) {
      final aValue = a.getFieldAsString(field);
      final bValue = b.getFieldAsString(field);
      final compare = aValue.compareTo(bValue);
      return sortDirection == SortDirection.asc ? compare : -compare;
    });

    update();
  }

  void setSortBy(RosterField field) {
    if (sortByField != field) {
      sortDirection = SortDirection.asc;
    } else {
      sortDirection = sortDirection == SortDirection.desc ? SortDirection.asc : SortDirection.desc;
    }
    sortByField = field;
    sort(field);
    update();
  }

  void setGroupBy(RosterField? field) {
    groupByField = (groupByField == field) ? null : field;
    update();
  }

  void toggleGroupExpanded(RosterGroup group) {
    bool? expansionState = _isRosterGroupTitleExpanded[group.title];
    if (expansionState == null) {
      _isRosterGroupTitleExpanded[group.title] = !expandedByDefault;
    } else {
      _isRosterGroupTitleExpanded[group.title] = !expansionState;
    }
    update();
  }

  bool isGroupExpanded(RosterGroup group) {
    if (rosterGroups.length == 1) {
      return true;
    }
    return _isRosterGroupTitleExpanded[group.title] == null ? expandedByDefault : _isRosterGroupTitleExpanded[group.title]!;
  }

  // --- Selection ---

  void toggleRowSelection(Rosterable rosterable) {
    selectedItems.contains(rosterable) ? selectedItems.remove(rosterable) : selectedItems.add(rosterable);
    update();
  }

  void toggleSelectAll() {
    if (selectedItems.isEmpty) {
      selectedItems.addAll(getFilteredRoster());
    } else {
      selectedItems.removeAll(getFilteredRoster());
    }
    update();
  }

  void toggleSelectGroup(RosterGroup group) {
    if (selectedItems.intersection(group.items.toSet()).isEmpty) {
      selectedItems.addAll(group.items);
    } else {
      selectedItems.removeAll(group.items);
    }
    update();
  }

  void invertSelection() {
    selectedItems = roster.toSet().difference(selectedItems);
    update();
  }

  bool isNothingSelected() => selectedItems.isEmpty;
  bool isSingleSelected() => selectedItems.length == 1;
  bool isMultiSelected() => selectedItems.length > 1;

  // --- UI & View Toggles ---

  void toggleSecondaryPage(int page) {
    if (page == 1) {
      columnConfigOpened = !columnConfigOpened;
      activitySwitcherOpened = false;
    } else if (page == 2) {
      activitySwitcherOpened = !activitySwitcherOpened;
      columnConfigOpened = false;
    }
    update();
  }

  void toggleAlternateRowColors() {
    alternateRowColors = !alternateRowColors;
    update();
  }

  void toggleHighContrast() {
    highContrast = !highContrast;
    update();
  }

  void toggleRowSeparators() {
    rowSeparators = !rowSeparators;
    update();
  }

  void toggleColumnSeparators() {
    columnSeparators = !columnSeparators;
    update();
  }

  void toggleCompact() {
    compact = !compact;
    update();
  }

  void toggleAssignmentRepetition() {
    showAssignmentRepetition = !showAssignmentRepetition;
    update();
  }

  void togglePreferenceColors() {
    showPreferenceColors = !showPreferenceColors;
    update();
  }

  // --- Activity Switcher Actions ---

  // Activity Switcher Actions
  void setSelectedAma(Titled block) {
    if (block is AMABlock) {
      selectedAma = (selectedAma == block) ? null : block;
      selectedActivity = null;
      update();
    }
  }

  void setSelectedActivity(ActivityDependent activity) {
    selectedActivity = (selectedActivity == activity) ? null : activity;
    update();
  }

  // Core User Actions
  Future<void> importCsv() async {
    importingCampers = true;
    update();

    try {
      await commitRepo.commit(await rosterService.importFromCsv());
    } on Exception catch (e, st) {
      Error.throwWithStackTrace(Debug.parseException(e), st);
    } finally {
      importingCampers = false;
      Get.back();
      update();
    }
  }

  Future<void> exportCamperBackup() async {
    if (selectedItems.isEmpty) {
      Get.snackbar('No Campers Selected', 'Please select at least one camper to back up.');
      return;
    }

    // 1. Get the JSON string from the service
    final String jsonBackup = await rosterService.backupSelectedCampers(selectedItems.map((rosterable) => rosterable.id).toSet());

    // 2. Convert the string to bytes (UTF-8)
    final Uint8List bytes = utf8.encode(jsonBackup);

    // 3. Use file_saver to open the save dialog
    final String fileName = 'camper_backup_${DateTime.now().toIso8601String()}.json';
    await FileSaver.instance.saveFile(name: fileName, bytes: bytes, ext: 'json', mimeType: MimeType.json);
  }

  // Updated method for RostersController
  Future<void> exportAsCsv() async {
    final String csvData = exportService.exportToCsv(
      groups: rosterGroups,
      columns: fields,
      activityDependents: activityDependents,
      principalActivities: principalActivities,
      selectedItems: roster.toSet(),
    );

    final Uint8List bytes = utf8.encode(csvData);
    final String fileName = 'roster_export_${DateTime.now().toIso8601String()}';
    await FileSaver.instance.saveFile(
      name: fileName,
      bytes: bytes,
      ext: 'csv',
      mimeType: MimeType.csv,
    );
  }

  Future<void> deleteSelected() async {
    try {
      Commit commit = Commit(
          disarmRequirementsLevel: 1,
          confirmationMessage:
              'Once deleted, campers cannot be restored. Their activity assignments and preferences for this session will be gone. Are you sure you want to proceed?');
      commit.addObjectsToDelete(selectedItems);
      await commitRepo.commit(commit);
    } finally {
      selectedItems.clear();
      update();
    }
  }

  Future<void> assignSelected() async {
    if (selectedItems.isEmpty || selectedAma == null || selectedActivity == null) {
      Debug.logWarning('Can\'t assign selected campers');
      return;
    }
    assigningCamper = true;
    update();
    Commit commit = Commit(disarmRequirementsLevel: 0);
    for (Rosterable rosterable in selectedItems) {
      if (rosterable is Camper) {
        await rosterService.assignCamperToActivity(commit, rosterable.id, selectedActivity!.id, false);
      }
    }
    await commitRepo.commit(commit);
    await populateActivities();
    assigningCamper = false;
    update();
  }

  Future<void> unassignSelectedFromActivity() async {
    if (selectedItems.isEmpty || selectedActivity == null) {
      Debug.logWarning('Can\'t unassign selected campers');
      return;
    }
    try {
      Commit commit = Commit(disarmRequirementsLevel: 0);
      for (Rosterable rosterable in selectedItems) {
        if (rosterable is Camper && rosterable.activityAssignmentRefs.containsValue(selectedActivity!.id)) {
          await rosterService.removeCamperFromActivity(commit, rosterable.id, selectedActivity!.id);
        }
      }
      await commitRepo.commit(commit);
      await populateActivities();
    } catch (e, st) {
      Error.throwWithStackTrace(Debug.parseException(e), st);
    } finally {
      update();
    }
  }

  Future<void> unassignSelectedFromAma() async {
    if (selectedItems.isEmpty || selectedAma == null) {
      Debug.logWarning('Can\'t unassign selected campers');
      return;
    }
    try {
      Commit commit = Commit(disarmRequirementsLevel: 0);
      for (Rosterable rosterable in selectedItems) {
        if (rosterable is Camper && rosterable.activityAssignmentRefs.containsKey(selectedAma!.id)) {
          await rosterService.unassignCamperFromAmaBlock(commit, rosterable.id, selectedAma!.id);
        }
      }
      await commitRepo.commit(commit);
      await populateActivities();
    } catch (e, st) {
      Error.throwWithStackTrace(Debug.parseException(e), st);
    } finally {
      update();
    }
  }

  Future<void> unassignSelectedFromAll() async {
    if (selectedItems.isEmpty) {
      Debug.logWarning('Can\'t unassign selected campers');
      return;
    }
    Commit commit = Commit(
        disarmRequirementsLevel: 1,
        confirmationMessage:
            'Are you sure you want to unassign the selected campers from all of their activities? This action cannot be undone.');

    await rosterService.removeAllActivitiesFromCampers(
        commit,
      selectedItems.map((e) => e.id).toSet(),
      amas.toSet(),
      activityDependents.toSet(),
    );
    await commitRepo.commit(commit);
    await populateActivities();
    update();
  }

  Future<void> rankRandomSelected() async {
    if (selectedItems.isEmpty) {
      Debug.logWarning('Can\'t rank selected campers');
      return;
    }
    try {
      Commit commit = Commit(
          disarmRequirementsLevel: 1,
          confirmationMessage: 'Are you sure you want to overwrite these activity preferences? This action cannot be undone.');
      for (Rosterable rosterable in selectedItems) {
        if (rosterable is Camper) {
          await preferenceService.rankRandom(commit, rosterable.id);
        }
      }
      await commitRepo.commit(commit);
      await populateActivities();
    } catch (e, st) {
      Error.throwWithStackTrace(Debug.parseException(e), st);
    } finally {
      update(); // Update UI to clear selections
    }
  }

  Future<void> clearPrefsSelected() async {
    if (selectedItems.isEmpty) {
      Debug.logWarning('Can\'t clear selected campers\' preferences');
      return;
    }
    try {
      Commit commit = Commit(
          disarmRequirementsLevel: 1,
          confirmationMessage: 'Are you sure you want to remove these activity preferences? This action cannot be undone.');
      for (Rosterable rosterable in selectedItems) {
        if (rosterable is Camper) {
          await preferenceService.clearPreference(commit, rosterable.id);
        }
      }
      await commitRepo.commit(commit);
      await populateActivities();
    } catch (e, st) {
      Error.throwWithStackTrace(Debug.parseException(e), st);
    } finally {
      update();
    }
  }

  Future<void> smartAssignAll() async {
    try {
      Commit commit = Commit(
          disarmRequirementsLevel: 1,
          confirmationMessage: 'Are you sure you want to commit these assignments? This action cannot be undone.');
      bool allCampersRanked = await rosterService.allCampersRanked();
      if (allCampersRanked == false) {
        bool? confirmResult = await popupService.showConfirmationDialog(
            title: 'Confirm',
            message: 'Some campers have not finished indicating their preferences yet. '
                'Their preference for these activities will be treated as neutral which could cause fully random assignments. Are you sure you want to proceed?');
        if (confirmResult != true) {
          return;
        }
      }
      Debug.logInfo('Auto assignment starting', userMessage: 'This process could take some time, please wait');
      await assignmentService.runAlgorithm(
        commit,
        roster.map((e) => e.id).toSet(),
        _amas.map((e) => e.id).toSet(),
      );
      await commitRepo.commit(commit);
      await populateActivities();
      Debug.logSuccess('Auto assignment complete', userMessage: 'Auto assignment complete!');
    } catch (e, st) {
      Error.throwWithStackTrace(Debug.parseException(e), st);
    } finally {
      update();
    }
  }

  Future<void> smartAssignSelected() async {
    if (selectedItems.isEmpty) {
      Debug.logWarning('Can\'t assign selected campers');
      return;
    }
    try {
      Commit commit = Commit(
          disarmRequirementsLevel: 1,
          confirmationMessage: 'Are you sure you want to commit selected camper assignments? This action cannot be undone.');
      bool selectedCampersRanked = await rosterService.selectedCampersRanked(selectedItems.map((r) => r.id).toSet());
      if (selectedCampersRanked == false) {
        bool? confirmResult = await popupService.showConfirmationDialog(
            title: 'Confirm',
            message: 'Some selected campers have not finished indicating their preferences yet. '
                'Their preference for these activities will be treated as neutral which could cause fully random assignments. Are you sure you want to proceed?');
        if (confirmResult != true) {
          return;
        }
      }
      Debug.logInfo('Auto assignment starting', userMessage: 'This process could take some time, please wait');
      final List<FormFieldDescriptor> formFieldDescriptors2 = [
        MultiSelectFormFieldDescriptor(
          optionLabelBuilder: (value) => value,
          options: amas.map((e) => e.displayTitle).toList(),
          isRequired: false,
          label: 'Periods',
        ),
      ];
      final prompt2Output = await Get.find<ConsoleController>().promptForm('Select Activities', formFieldDescriptors2);
      if (prompt2Output == null) {
        return;
      }

      List<AMABlock> selectedBlocks = [];
      final selectedBlockNames = prompt2Output[0] as List<String>?;
      if (selectedBlockNames != null) {
        selectedBlocks.addAll(amas.where((element) => selectedBlockNames.contains(element.displayTitle)));
      }
      await assignmentService.runAlgorithm(
        commit,
        selectedItems.map((e) => e.id).toSet(),
        selectedBlocks.map((e) => e.id).toSet(),
      );
      await commitRepo.commit(commit);
      await populateActivities();
      Debug.logSuccess('Auto assignment complete', userMessage: 'Auto assignment complete!');
    } catch (e, st) {
      Error.throwWithStackTrace(Debug.parseException(e), st);
    } finally {
      update();
    }
  }

  Future<void> swapCabinsOfSelected() async {
    // 1. --- VALIDATION ---
    // A. Ensure items are selected.
    if (selectedItems.isEmpty) {
      Debug.logWarning('No campers selected');
      return;
    }

    final List<Camper> selectedCampers = [];
    final Set<CabinId> cabinIds = {};

    // B. Ensure all selected items are campers and are in a cabin.
    for (final item in selectedItems) {
      if (item is! Camper) {
        Debug.logWarning('Invalid Selection');
        return;
      }
      if (item.cabinRef == null) {
        Debug.logWarning('Invalid Selection');
        return;
      }
      selectedCampers.add(item);
      cabinIds.add(item.cabinRef!);
    }

    // C. Ensure there are exactly two cabins among the selected campers.
    if (cabinIds.length != 2) {
      Debug.logWarning('Invalid Selection');
      return;
    }

    // 2. --- PREPARATION ---
    assigningCamper = true;
    update();

    // Keep track of original selection to re-select after roster refresh
    final originalSelectedIds = selectedItems.map((e) => e.id).toSet();

    // Group campers by their respective cabins.
    final cabin1Id = cabinIds.first;
    final cabin2Id = cabinIds.last;
    final List<Camper> campersInCabin1 = selectedCampers.where((c) => c.cabinRef == cabin1Id).toList();
    final List<Camper> campersInCabin2 = selectedCampers.where((c) => c.cabinRef == cabin2Id).toList();

    final commit = Commit(disarmRequirementsLevel: 0);

    // 3. --- EXECUTION ---
    // Add campers from cabin 1 to cabin 2. The service handles the removal.
    for (final camper in campersInCabin1) {
      await cabinsService.addCamperToCabin(commit, cabin2Id, camper.id);
    }
    // Add campers from cabin 2 to cabin 1.
    for (final camper in campersInCabin2) {
      await cabinsService.addCamperToCabin(commit, cabin1Id, camper.id);
    }

    await commitRepo.commit(commit);
    Debug.logSuccess('Swap Successful!');

    // 4. --- STATE REFRESH ---
    update();
    selectedItems.clear();
    for (final rosterable in roster) {
      if (originalSelectedIds.contains(rosterable.id)) {
        selectedItems.add(rosterable);
      }
    }
    assigningCamper = false;
    update();
  }

  Future<void> toggleArrived() async {
    if (selectedItems.isEmpty) {
      Debug.logWarning('No campers selected to toggle arrival status.');
      return;
    }
    Commit commit = Commit(disarmRequirementsLevel: 0);
    for (final rosterable in selectedItems) {
      if (rosterable is Camper) {
        // Treat null as false, and toggle the boolean value.
        rosterable.arrived = !(rosterable.arrived ?? false);
        commit.addObjectToPush(rosterable);
      }
    }
    await commitRepo.commit(commit);
    update(); // It is good practice to call update() after a state change.
  }

  Future<void> setCabin() async{
    if (selectedItems.isEmpty) {
      Debug.logWarning('No campers selected to set cabin.');
      return;
    }
    Commit commit = Commit(disarmRequirementsLevel: 0);
    Set<CabinDependent> cabinDependents = await cabinsService.cabinDependents;
    final List<FormFieldDescriptor> formFieldDescriptors1 = [
      SelectFormFieldDescriptor(
        optionLabelBuilder: (value) => value,
        options: cabinDependents.map((e) => e.id).toList(),
        isRequired: true,
        label: 'Activity Periods',
      ),
    ];
    final prompt1Output = (await Get.find<ConsoleController>().promptForm('Select Cabin', formFieldDescriptors1))?.first;
    if (prompt1Output == null) {
      return;
    }
    CabinDependent cabinDependent = cabinDependents.firstWhere((element) => element.id == prompt1Output as String);

    for (final rosterable in selectedItems) {
      if (rosterable is Camper) {
        await cabinsService.addCamperToCabin(commit, cabinDependent.id, rosterable.id);
      }
    }
    commitRepo.commit(commit);
  }

  // Helper & Utility Methods
  /// Pure calculation to determine table and column widths based on available space.
  TableWidths calculateTableWidths(double maxWidth, double indentWidth) {
    if (fields.isEmpty) {
      return TableWidths(adjustedDataWidths: [], actualTableWidth: _checkboxColumnWidth);
    }

    final List<double> defaultDataWidths = fields.map((field) => field.defaultWidth).toList();
    final double minDataWidthSum = defaultDataWidths.reduce((a, b) => a + b);
    final double totalMinWidth = minDataWidthSum + _checkboxColumnWidth;

    List<double> adjustedDataWidths = List.from(defaultDataWidths);
    double actualTableWidth;

    if (maxWidth >= totalMinWidth) {
      final double excessSpace = maxWidth - totalMinWidth;
      adjustedDataWidths[adjustedDataWidths.length - 1] += excessSpace;
      actualTableWidth = maxWidth;
    } else {
      actualTableWidth = totalMinWidth;
    }

    if (groupByField != null) {
      actualTableWidth += indentWidth;
    }

    return TableWidths(adjustedDataWidths: adjustedDataWidths, actualTableWidth: actualTableWidth);
  }

  String getActivityDependentName(Rosterable rosterItem, RosterField field) {
    if (populatingActivities) {
      return 'loading...';
    }

    String activityDependentId = rosterItem.getFieldAsString(field);
    if (activityDependentId.isEmpty) {
      return 'Unassigned';
    }

    final activityDependent = activityDependents.firstWhereOrNull((dep) => dep.id == activityDependentId);
    if (activityDependent == null) {
      return 'Error (not found)';
    }

    final principalActivity = principalActivities[activityDependent.principalPar];
    return principalActivity?.name ?? 'Error (no principal)';
  }

  List<Color?> getRepetitionColors(Rosterable rosterItem) {
    if (!showAssignmentRepetition || rosterItem is! Camper) {
      return List.filled(fields.length, null);
    }

    final camper = rosterItem;
    final Map<PrincipalActivityId, int> counts = {};

    // Count principal activities
    for (final activityDependentId in camper.activityAssignmentRefs.values) {
      if (activityDependentId != null) {
        final dependent = activityDependents.firstWhereOrNull((d) => d.id == activityDependentId);
        if (dependent != null) {
          counts[dependent.principalPar] = (counts[dependent.principalPar] ?? 0) + 1;
        }
      }
    }

    final List<Color?> colors = [];
    for (final field in fields) {
      if (field is AMABlock) {
        final activityDependentId = camper.activityAssignmentRefs[field.dataId];
        if (activityDependentId != null) {
          final dependent = activityDependents.firstWhereOrNull((d) => d.id == activityDependentId);
          if (dependent != null) {
            final count = counts[dependent.principalPar] ?? 0;
            if (count == 1) {
              colors.add(BessColors.green.withOpacity(0.5));
            } else if (count == 2) {
              colors.add(BessColors.yellow.withOpacity(0.5));
            } else if (count >= 3) {
              colors.add(BessColors.red.withOpacity(0.5));
            } else {
              colors.add(null);
            }
          } else {
            colors.add(null);
          }
        } else {
          colors.add(null);
        }
      } else {
        colors.add(null);
      }
    }
    return colors;
  }

  Color? getActivityPreferenceColor(ActivityDependent activity) {
    if (!showPreferenceColors || !isSingleSelected()) {
      return null;
    }

    final camper = selectedItems.first as Camper;

    // --- CHANGED LINES ---
    final principalActivityId = activity.principalPar;
    int assignmentCount = 0;

    for (final assignedActivityId in camper.activityAssignmentRefs.values) {
      if (assignedActivityId != null) {
        final dependent = activityDependents.firstWhereOrNull((d) => d.id == assignedActivityId);
        if (dependent != null && dependent.principalPar == principalActivityId) {
          assignmentCount++;
        }
      }
    }

    if (assignmentCount >= 2) {
      return BessColors.red;
    }
    // --- END CHANGED LINES ---

    final preference = camper.preferenceRefs[activity.principalPar];

    if (preference == 1.0) {
      return BessColors.green;
    } else if (preference == 0.0) {
      return BessColors.red;
    } else if (preference == 0.5 || preference == null) {
      return BessColors.yellow;
    }

    return null;
  }

  List<String> getRowDataFromItem(Rosterable rosterItem) {
    final List<String> rowData = [];
    for (final field in fields) {
      if (field is AMABlock) {
        rowData.add(getActivityDependentName(rosterItem, field));
      } else {
        rowData.add(rosterItem.getFieldAsString(field));
      }
    }
    return rowData;
  }
}
