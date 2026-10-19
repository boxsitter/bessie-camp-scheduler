import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../data/roster_repository.dart';
import '../../../data/session_repository.dart';
import '../../../models/cabin.dart';
import '../../../models/camper.dart';
import '../../../models/enums.dart';
import '../../../models/schedule.dart';
import '../../../services/assignment_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/context_service.dart';
import '../../../shared/mixins/route_aware_controller_mixin.dart';
import '../../../shared/services/toast.dart';
import '../models/activity_hints.dart';
import '../models/roster_column.dart';
import '../models/roster_context.dart';
import '../models/roster_selection.dart';
import '../models/roster_table_style.dart';
import '../models/roster_view.dart';
import '../models/table_layout.dart';
import 'roster_actions.dart';

/// State of the Rosters page: the session's live roster and schedule, how the
/// table is arranged, which campers are selected, and the actions on them.
///
/// The roster is only watched while the page is on screen.
class RostersController extends GetxController with RouteAwareControllerMixin {
  final ContextService _context = Get.find<ContextService>();
  final AuthService _auth = Get.find<AuthService>();
  final RosterRepository _roster = Get.find<RosterRepository>();
  final SessionRepository _sessions = Get.find<SessionRepository>();
  late final RosterActions _actions = RosterActions();

  // Data ----------------------------------------------------------------------

  List<Camper> campers = const [];
  RosterContext rosterContext = RosterContext.empty();

  /// What the last smart assign did; kept so its evaluation can be downloaded.
  AssignmentRunReport? lastRunReport;

  bool _rosterLoaded = false;
  bool _structureLoaded = false;
  StreamSubscription<List<Camper>>? _rosterSubscription;
  String? _watchedSessionId;
  int _generation = 0;
  bool _active = false;
  Worker? _sessionWorker;

  Schedule get schedule => rosterContext.schedule;
  RosterView get view => RosterView(rosterContext);

  bool get hasSession => _context.isLoaded;
  bool get loading => hasSession && !(_rosterLoaded && _structureLoaded);

  /// Whether the signed-in user may change session data.
  bool get canEdit => _auth.profile.value?.role.canEditSessionData ?? false;

  // Table configuration -------------------------------------------------------

  List<RosterColumn> columns = [...RosterColumns.defaults];
  RosterColumn sortBy = RosterColumns.lastName;
  SortDirection sortDirection = SortDirection.asc;
  RosterColumn? groupBy;
  RosterTableStyle style = const RosterTableStyle();
  bool expandedByDefault = false;
  bool showAssignmentRepetition = false;
  bool showPreferenceColors = false;

  /// Group key -> whether the user expanded (true) or collapsed (false) it.
  final Map<String, bool> _expanded = {};

  bool get isGrouped => groupBy != null;
  bool get hasBlockColumns => columns.any((column) => column is BlockColumn);

  List<FieldColumn> get hiddenFieldColumns => [
    for (final column in RosterColumns.allFields)
      if (!columns.contains(column)) column,
  ];

  List<BlockColumn> get hiddenBlockColumns => [
    for (final block in schedule.blocks)
      if (!columns.contains(BlockColumn(block))) BlockColumn(block),
  ];

  TableLayout layoutFor(double maxWidth) => TableLayout.fit(columns, maxWidth);

  // Search --------------------------------------------------------------------

  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();
  Timer? _searchDebounce;

  bool get noMatches => searchQuery.trim().isNotEmpty && filteredCampers.isEmpty;

  // Derived data, rebuilt lazily after any change ---------------------------

  List<RosterGroup>? _groups;
  Map<String, int>? _enrollment;

  /// The roster as shown: searched, sorted and grouped.
  List<RosterGroup> get groups =>
      _groups ??= view.arrange(campers, query: searchQuery, sortBy: sortBy, direction: sortDirection, groupBy: groupBy);

  /// The campers that match the search, in table order.
  List<Camper> get filteredCampers => [for (final group in groups) ...group.campers];

  /// Scheduled activity id -> campers in it.
  Map<String, int> get enrollment => _enrollment ??= ActivityHints.enrollment(campers);

  void _refresh() {
    _groups = null;
    _enrollment = null;
    update();
  }

  // Selection -----------------------------------------------------------------

  /// Selected camper ids; they survive the roster being re-emitted.
  final Set<String> selectedIds = {};

  bool get hasSelection => selectedIds.isNotEmpty;
  bool get isSingleSelected => selectedIds.length == 1;
  List<Camper> get selectedCampers => [
    for (final camper in campers)
      if (selectedIds.contains(camper.id)) camper,
  ];
  Camper? get singleSelected => isSingleSelected ? selectedCampers.firstOrNull : null;

  bool isSelected(Camper camper) => selectedIds.contains(camper.id);

  /// Checkbox state of [group]: true when all of it is selected, null when some is.
  bool? groupSelectionState(RosterGroup group) => RosterSelection.stateOf(group.camperIds, selectedIds);

  bool get allVisibleSelected =>
      filteredCampers.isNotEmpty && RosterSelection.stateOf(filteredCampers.map((c) => c.id), selectedIds) == true;

  void toggleSelection(Camper camper) {
    if (!selectedIds.remove(camper.id)) selectedIds.add(camper.id);
    update();
  }

  void toggleSelectAll() {
    final visible = filteredCampers.map((c) => c.id);
    if (selectedIds.isEmpty) {
      selectedIds.addAll(visible);
    } else {
      selectedIds.removeAll(visible);
    }
    update();
  }

  void toggleSelectGroup(RosterGroup group) {
    if (group.camperIds.any(selectedIds.contains)) {
      selectedIds.removeAll(group.camperIds);
    } else {
      selectedIds.addAll(group.camperIds);
    }
    update();
  }

  /// Selects what is shown and unselected, and unselects the rest of what is shown.
  void invertSelection() {
    final visible = filteredCampers.map((c) => c.id).toList();
    final inverted = RosterSelection.invert(visible, selectedIds);
    selectedIds
      ..removeAll(visible)
      ..addAll(inverted);
    update();
  }

  void clearSelection() {
    selectedIds.clear();
    update();
  }

  // Lifecycle -----------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();
    _sessionWorker = ever(_context.session, (_) => _onSessionChanged());
  }

  @override
  void onClose() {
    _sessionWorker?.dispose();
    _searchDebounce?.cancel();
    _stopWatching();
    searchController.dispose();
    super.onClose();
  }

  @override
  void onNavigateTo(String to, String? from) => activate();

  @override
  void onNavigateFrom(String from, String to) {
    _active = false;
    _stopWatching();
  }

  /// Starts watching the session's roster; harmless when already watching.
  void activate() {
    _active = true;
    unawaited(_start());
  }

  Future<void> _start() async {
    if (!_context.isLoaded) {
      update();
      return;
    }
    final sessionId = _context.sessionId;
    if (_rosterSubscription != null && _watchedSessionId == sessionId) return;

    // Whatever was loaded before is shown until the fresh data arrives; it is
    // only discarded when the session changes (see _onSessionChanged).
    _stopWatching();
    final generation = ++_generation;
    _watchedSessionId = sessionId;

    _rosterSubscription = _roster.watchCampers(sessionId).listen(_onCampers, onError: _onWatchError);

    final structure = await attempt(
      () => Future.wait<Object>([_sessions.fetchSchedule(sessionId), _sessions.listSessionCabins(sessionId)]),
    );
    if (generation != _generation) return;

    if (structure != null) {
      rosterContext = RosterContext(
        schedule: structure[0] as Schedule,
        cabinsById: {for (final cabin in structure[1] as List<Cabin>) cabin.id: cabin},
      );
    }
    _remapColumns();
    _structureLoaded = true;
    _refresh();
  }

  void _stopWatching() {
    _generation++;
    unawaited(_rosterSubscription?.cancel());
    _rosterSubscription = null;
    _watchedSessionId = null;
  }

  void _onCampers(List<Camper> latest) {
    campers = latest;
    selectedIds.retainAll({for (final camper in latest) camper.id});
    _rosterLoaded = true;
    _refresh();
  }

  void _onWatchError(Object error, StackTrace stackTrace) {
    Toast.failure(error, stackTrace);
    _rosterLoaded = true;
    update();
  }

  /// Forgets everything that belongs to the previous session.
  void _onSessionChanged() {
    _stopWatching();
    campers = const [];
    rosterContext = RosterContext.empty();
    selectedIds.clear();
    selectedBlockId = null;
    selectedScheduledId = null;
    lastRunReport = null;
    _expanded.clear();
    _rosterLoaded = false;
    _structureLoaded = false;
    _refresh();
    if (_active) unawaited(_start());
  }

  /// Points block columns (and the sort and group column) at the loaded
  /// schedule's blocks.
  void _remapColumns() {
    columns = RosterColumns.remapToSchedule(columns, schedule);
    sortBy = RosterColumns.remap(sortBy, schedule) ?? RosterColumns.lastName;
    final grouping = groupBy;
    if (grouping != null) groupBy = RosterColumns.remap(grouping, schedule);
  }

  // Search --------------------------------------------------------------------

  void setSearchQuery(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 100), () {
      searchQuery = query;
      _refresh();
    });
  }

  // Columns, sorting and grouping ---------------------------------------------

  void setColumnOrder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    columns.insert(newIndex, columns.removeAt(oldIndex));
    update();
  }

  void addColumn(RosterColumn column) {
    if (columns.contains(column)) return;
    columns.add(column);
    update();
  }

  void removeColumn(RosterColumn column) {
    if (columns.remove(column)) update();
  }

  /// Sorts by [column]; choosing the column that is already sorted by flips the direction.
  void setSortBy(RosterColumn column) {
    if (sortBy == column) {
      sortDirection = sortDirection == SortDirection.asc ? SortDirection.desc : SortDirection.asc;
    } else {
      sortBy = column;
      sortDirection = SortDirection.asc;
    }
    _refresh();
  }

  /// Groups by [column]; choosing the column that is already grouped by ungroups.
  void setGroupBy(RosterColumn column) {
    groupBy = groupBy == column ? null : column;
    _refresh();
  }

  bool isGroupExpanded(RosterGroup group) => _expanded[group.key] ?? (expandedByDefault || groups.length == 1);

  void toggleGroupExpanded(RosterGroup group) {
    _expanded[group.key] = !isGroupExpanded(group);
    update();
  }

  // View toggles --------------------------------------------------------------

  bool columnConfigOpened = false;
  bool activitySwitcherOpened = false;

  void toggleColumnConfig() {
    columnConfigOpened = !columnConfigOpened;
    activitySwitcherOpened = false;
    update();
  }

  void toggleActivitySwitcher() {
    activitySwitcherOpened = !activitySwitcherOpened;
    columnConfigOpened = false;
    update();
  }

  void toggleAlternateRowColors() => _style(style.copyWith(alternateRowColors: !style.alternateRowColors));
  void toggleHighContrast() => _style(style.copyWith(highContrast: !style.highContrast));
  void toggleRowSeparators() => _style(style.copyWith(rowSeparators: !style.rowSeparators));
  void toggleColumnSeparators() => _style(style.copyWith(columnSeparators: !style.columnSeparators));
  void toggleCompact() => _style(style.copyWith(compact: !style.compact));

  void _style(RosterTableStyle next) {
    style = next;
    update();
  }

  void toggleExpandedByDefault() {
    expandedByDefault = !expandedByDefault;
    _expanded.clear();
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

  // Activity switcher ---------------------------------------------------------

  String? selectedBlockId;
  String? selectedScheduledId;

  Block? get selectedBlock => selectedBlockId == null ? null : schedule.blockById(selectedBlockId!);
  ScheduledActivity? get selectedScheduled => selectedScheduledId == null ? null : schedule.scheduledActivityById(selectedScheduledId!);

  /// The activities offered in the selected block, by name.
  List<ScheduledActivity> get selectedBlockActivities {
    final block = selectedBlock;
    if (block == null) return const [];
    return schedule.scheduledIn(block.id)..sort((a, b) => activityName(a).toLowerCase().compareTo(activityName(b).toLowerCase()));
  }

  void selectBlock(Block block) {
    selectedBlockId = selectedBlockId == block.id ? null : block.id;
    selectedScheduledId = null;
    update();
  }

  void selectScheduled(ScheduledActivity scheduled) {
    selectedScheduledId = selectedScheduledId == scheduled.id ? null : scheduled.id;
    update();
  }

  String activityName(ScheduledActivity scheduled) => schedule.activityOf(scheduled)?.name ?? 'Unknown activity';

  Seats seatsOf(ScheduledActivity scheduled) => ActivityHints.seats(
    scheduled: scheduled,
    capacity: schedule.activityOf(scheduled)?.capacity ?? 0,
    selected: selectedCampers,
    enrollment: enrollment,
  );

  /// How the selected camper fits [scheduled], when preference colors are on
  /// and exactly one camper is selected.
  PreferenceHint? preferenceHintFor(ScheduledActivity scheduled) {
    final camper = singleSelected;
    if (!showPreferenceColors || camper == null) return null;
    return ActivityHints.preferenceHint(camper, scheduled, schedule);
  }

  /// For the repetition view of a block column.
  RepetitionLevel? repetitionOf(Camper camper, RosterColumn column) {
    if (!showAssignmentRepetition || column is! BlockColumn) return null;
    return ActivityHints.repetition(camper, column.block.id, schedule);
  }

  /// What the activity switcher would do to [camper] if committed, or null when nothing.
  ({String? from, String to})? plannedChange(Camper camper) {
    final target = selectedScheduled;
    if (target == null) return null;
    final currentId = camper.assignments[target.blockId];
    if (currentId == target.id) return null;
    final current = currentId == null ? null : schedule.scheduledActivityById(currentId);
    return (from: current == null ? null : activityName(current), to: activityName(target));
  }

  // Actions -------------------------------------------------------------------

  final RxBool importing = false.obs;

  /// True while the activity switcher's assignment is being stored.
  bool assigning = false;

  bool get canAssignToSelectedActivity => canEdit && hasSelection && selectedScheduled != null;
  bool get canUnassignFromSelectedBlock => canEdit && hasSelection && selectedBlock != null;

  /// Asks for a roster file and imports it. True when it was imported.
  Future<bool> importCsv() async {
    if (!canEdit || importing.value || !_context.isLoaded) return false;
    importing.value = true;
    try {
      return await _actions.importCsv(_context.sessionId);
    } finally {
      importing.value = false;
    }
  }

  Future<void> exportCsv() => _actions.exportCsv(groups: groups, columns: columns, view: view, grouped: isGrouped);

  Future<void> exportBackup() async {
    if (!hasSelection || !_context.isLoaded) return;
    await _actions.exportBackup(sessionId: _context.sessionId, campers: selectedCampers, schedule: schedule);
  }

  Future<void> exportEvaluationReport() async {
    final report = lastRunReport;
    if (report == null) return;
    await _actions.exportEvaluationReport(report, campers);
  }

  Future<void> deleteSelected() async {
    if (!canEdit || !hasSelection) return;
    if (await _actions.deleteCampers(selectedCampers)) clearSelection();
  }

  Future<void> toggleArrived() async {
    if (!canEdit || !hasSelection) return;
    await _actions.toggleArrived(selectedCampers);
  }

  Future<void> setCabin() async {
    if (!canEdit || !hasSelection) return;
    await _actions.setCabin(selectedCampers, rosterContext.cabinsById.values.toList());
  }

  Future<void> swapCabinsOfSelected() async {
    if (!canEdit || !hasSelection) return;
    await _actions.swapCabins(selectedCampers);
  }

  Future<void> assignSelected() async {
    final target = selectedScheduled;
    if (!canAssignToSelectedActivity || target == null || assigning) return;
    assigning = true;
    update();
    try {
      await _actions.assign(campers: selectedCampers, target: target, activityName: activityName(target), seats: seatsOf(target));
    } finally {
      assigning = false;
      update();
    }
  }

  Future<void> unassignSelectedFromActivity() async {
    final target = selectedScheduled;
    if (!canAssignToSelectedActivity || target == null) return;
    await _actions.unassignFromActivity(selectedCampers, target, activityName(target));
  }

  Future<void> unassignSelectedFromBlock() async {
    final block = selectedBlock;
    if (!canUnassignFromSelectedBlock || block == null) return;
    await _actions.unassignFromBlock(selectedCampers, block);
  }

  Future<void> unassignSelectedFromAll() async {
    if (!canEdit || !hasSelection) return;
    await _actions.unassignFromAll(selectedCampers);
  }

  Future<void> smartAssignAll() => _smartAssign(selected: null);

  Future<void> smartAssignSelected() async {
    if (!hasSelection) return;
    await _smartAssign(selected: selectedCampers);
  }

  Future<void> _smartAssign({required List<Camper>? selected}) async {
    if (!canEdit || !_context.isLoaded) return;
    final report = await _actions.smartAssign(sessionId: _context.sessionId, schedule: schedule, everyone: campers, selected: selected);
    if (report == null) return;
    lastRunReport = report;
    update();
  }

  /// Testing aid: gives the selected campers random preferences.
  Future<void> rankRandomSelected() async {
    if (!canEdit || !hasSelection || !_context.isLoaded) return;
    await _actions.rankRandom(campers: selectedCampers, schedule: schedule, limits: _context.currentSession.limits);
  }

  Future<void> clearPreferencesOfSelected() async {
    if (!canEdit || !hasSelection) return;
    await _actions.clearPreferences(selectedCampers);
  }
}
