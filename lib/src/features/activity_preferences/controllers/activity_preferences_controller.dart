import 'dart:async';

import 'package:flutter/foundation.dart' show mapEquals;
import 'package:get/get.dart';

import '../../../core/errors.dart';
import '../../../core/logging.dart';
import '../../../data/roster_repository.dart';
import '../../../data/session_repository.dart';
import '../../../models/activity.dart';
import '../../../models/cabin.dart';
import '../../../models/camp_session.dart';
import '../../../models/camper.dart';
import '../../../models/enums.dart';
import '../../../services/context_service.dart';
import '../../../shared/mixins/route_aware_controller_mixin.dart';
import '../../../shared/services/popup_service.dart';
import '../../../shared/services/toast.dart';
import '../../../shared/widgets/header/controllers/menu_bar_controller.dart';
import '../models/cabin_group.dart';
import '../models/preference_board.dart';

/// Collects each camper's activity requests and vetoes.
///
/// A counselor picks a cabin, then a camper, then drags activities into
/// "Yes please" / "No thanks". Edits are kept as drafts and saved shortly
/// after the last change, and right away when switching camper, cabin or page.
/// Drafts are never dropped: a save that is still running when the camper is
/// edited again is followed by another save of the newer draft, and a save the
/// server refuses (e.g. over the limits) is reported and the camper goes back
/// to what is stored.
class ActivityPreferencesController extends GetxController with RouteAwareControllerMixin {
  final ContextService _context = Get.find<ContextService>();
  final SessionRepository _sessions = Get.find<SessionRepository>();
  final RosterRepository _roster = Get.find<RosterRepository>();
  final PopupService _popups = Get.find<PopupService>();
  final MenuBarController _menuBar = Get.find<MenuBarController>();

  /// How long after the last edit the draft is saved.
  static const autosaveDelay = Duration(milliseconds: 1500);

  // Loaded data (for the current session) -------------------------------------

  bool isLoading = false;
  String? loadError;

  List<Cabin> _cabins = const [];
  List<Activity> _rankable = const [];
  PreferenceLimits? _limits;

  /// By id; the server's view, plus the preferences we saved ourselves.
  Map<String, Camper> _campers = {};
  List<CabinGroup>? _groups;

  bool _loaded = false;
  bool _stale = false;

  /// Whether the page is on screen (or about to be), so data should be live.
  bool _pageActive = false;
  bool _streamErrorShown = false;
  int _generation = 0;
  StreamSubscription<List<Camper>>? _campersSubscription;
  Worker? _sessionWorker;

  // Selection -----------------------------------------------------------------

  bool showingCabins = true;
  bool campersPaneOpen = true;
  String? _selectedGroupKey;
  String? _selectedCamperId;
  ActivityCategory? _selectedCategory;
  bool _skillsMode = false;

  /// The selected camper's preferences as being edited.
  PreferenceBoard? board;
  String? _boardCamperId;

  // Drafts --------------------------------------------------------------------

  /// Edits not yet sent to the server: camper id -> everything chosen.
  final Map<String, Map<String, PreferenceKind>> _dirty = {};

  /// Edits being sent right now.
  final Map<String, Map<String, PreferenceKind>> _inFlight = {};
  Timer? _autosaveTimer;
  Future<bool>? _flushing;

  @override
  void onInit() {
    super.onInit();
    _sessionWorker = ever(_context.session, (_) => _onSessionChanged());
  }

  @override
  void onClose() {
    _autosaveTimer?.cancel();
    _sessionWorker?.dispose();
    unawaited(_campersSubscription?.cancel());
    _campersSubscription = null;
    // Best effort: the drafts are still worth saving after the page is gone.
    unawaited(flush());
    super.onClose();
  }

  // Derived state for the views -----------------------------------------------

  List<CabinGroup> get cabinGroups => _groups ??= groupCampersByCabin(_cabins, _campers.values);

  CabinGroup? get selectedGroup => cabinGroups.firstWhereOrNull((g) => g.key == _selectedGroupKey);

  String? get selectedCabinTitle => selectedGroup?.title;

  List<Camper> get campersInSelectedCabin => selectedGroup?.campers ?? const [];

  Camper? get selectedCamper => _selectedCamperId == null ? null : _campers[_selectedCamperId];

  bool get hasCampers => _campers.isNotEmpty;

  /// Whether the session offers any activity for campers to rank.
  bool get hasActivities => _rankable.isNotEmpty;
  bool get hasSession => _context.session.value != null;

  /// Whether the camper is being saved or about to be.
  bool isPending(String camperId) => _dirty.containsKey(camperId) || _inFlight.containsKey(camperId);

  bool get hasUnsavedChanges => _dirty.isNotEmpty;
  bool get isSaving => _inFlight.isNotEmpty;

  /// Whether to offer the Skills Recs / Standard Activities switch.
  bool get canSwitchMode => (board?.hasSkillsActivities ?? false) && (board?.hasStandardActivities ?? false);

  /// Whether the library shows skills recs rather than standard activities.
  bool get skillsMode {
    final current = board;
    if (current == null || !current.hasSkillsActivities) return false;
    return !current.hasStandardActivities || _skillsMode;
  }

  List<ActivityCategory> get categories => board?.standardCategories ?? const [];

  ActivityCategory? get selectedCategory {
    final available = categories;
    if (available.isEmpty) return null;
    return available.contains(_selectedCategory) ? _selectedCategory : available.first;
  }

  /// The activities the camper is open to, for the current tab.
  List<Activity> get libraryActivities =>
      board?.neutral(skillsRec: skillsMode, category: skillsMode ? null : selectedCategory) ?? const [];

  List<Activity> chosenActivities(PreferenceKind kind) => board?.chosen(kind, skillsRec: skillsMode) ?? const [];

  int remaining(PreferenceKind kind) => board?.remaining(kind, skillsRec: skillsMode) ?? 0;

  // Lifecycle -----------------------------------------------------------------

  @override
  void onNavigateTo(String to, String? from) {
    _pageActive = true;
    unawaited(_load());
  }

  @override
  void onNavigateFrom(String from, String to) {
    _pageActive = false;
    unawaited(flush());
    // The page is not visible: stop listening until it is opened again.
    unawaited(_campersSubscription?.cancel());
    _campersSubscription = null;
    _stale = true;
  }

  /// Loads the data if the page is shown without having been navigated to.
  /// Safe to call from `build`/`initState`.
  void ensureLoaded() {
    _pageActive = true;
    scheduleMicrotask(() {
      if (!isClosed && !isLoading && (!_loaded || _stale)) unawaited(_load());
    });
  }

  /// Saves pending edits, then reads everything again.
  Future<void> reload() async {
    await flush();
    await _load(keepSelection: true);
  }

  void _onSessionChanged() {
    // Drafts belong to campers of the previous session and are still valid
    // to save, whichever session is selected now.
    unawaited(flush());
    if (_pageActive) {
      unawaited(_load());
    } else {
      _stale = true;
      _clearData();
      _clearSelection();
      _refreshUi();
    }
  }

  Future<void> _load({bool keepSelection = false}) async {
    final generation = ++_generation;
    final session = _context.session.value;
    unawaited(_campersSubscription?.cancel());
    _campersSubscription = null;
    _loaded = false;
    _stale = false;
    loadError = null;
    if (!keepSelection) _clearSelection();

    if (session == null) {
      _clearData();
      isLoading = false;
      _refreshUi();
      return;
    }

    isLoading = true;
    _refreshUi();
    try {
      final cabinsFuture = _sessions.listSessionCabins(session.id);
      final scheduleFuture = _sessions.fetchSchedule(session.id);
      final firstCampers = Completer<void>();
      _campersSubscription = _roster
          .watchCampers(session.id)
          .listen(
            (campers) {
              if (generation != _generation) return;
              _onCampers(campers);
              if (!firstCampers.isCompleted) firstCampers.complete();
            },
            onError: (Object error, StackTrace stackTrace) {
              if (generation != _generation) return;
              if (!firstCampers.isCompleted) {
                firstCampers.completeError(error, stackTrace);
              } else if (!_streamErrorShown) {
                _streamErrorShown = true;
                Toast.failure(error, stackTrace);
              }
            },
          );

      await Future.wait<Object?>([cabinsFuture, scheduleFuture, firstCampers.future]);
      if (generation != _generation) return;

      final schedule = await scheduleFuture;
      _cabins = await cabinsFuture;
      _rankable = schedule.offeredActivities.where((a) => !a.isHidden && a.preferenceRequired).toList();
      _limits = session.limits;
      _groups = null;
      _loaded = true;
      isLoading = false;
      // The activities and limits may have changed: build the board again.
      board = null;
      _boardCamperId = null;
      _reconcileSelection();
      _refreshUi();
    } catch (e, st) {
      if (generation != _generation) return;
      unawaited(_campersSubscription?.cancel());
      _campersSubscription = null;
      _clearData();
      loadError = AppException.from(e, st).message;
      isLoading = false;
      Toast.failure(e, st);
      _refreshUi();
    }
  }

  void _onCampers(List<Camper> campers) {
    _campers = {for (final c in campers) c.id: c};
    _groups = null;
    _streamErrorShown = false;
    if (_loaded) {
      _reconcileSelection();
      _refreshUi();
    }
  }

  void _clearData() {
    _cabins = const [];
    _rankable = const [];
    _limits = null;
    _campers = {};
    _groups = null;
  }

  void _clearSelection() {
    showingCabins = true;
    campersPaneOpen = true;
    _selectedGroupKey = null;
    _selectedCamperId = null;
    _selectedCategory = null;
    _skillsMode = false;
    board = null;
    _boardCamperId = null;
  }

  /// Keeps the selection pointing at things that still exist.
  void _reconcileSelection() {
    final group = selectedGroup;
    if (_selectedGroupKey != null && group == null) {
      _clearSelection();
      return;
    }
    if (group != null && !group.campers.any((c) => c.id == _selectedCamperId)) {
      _selectedCamperId = group.campers.first.id;
    }
    _syncBoard();
  }

  // Selection actions ---------------------------------------------------------

  void selectCabinGroup(CabinGroup group) {
    if (group.campers.isEmpty) return;
    unawaited(flush());
    _selectedGroupKey = group.key;
    _selectedCamperId = group.campers.first.id;
    showingCabins = false;
    campersPaneOpen = true;
    _selectedCategory = null;
    _skillsMode = false;
    _menuBar.setHideSidebar(true);
    _syncBoard();
    update();
  }

  void selectCamper(Camper camper) {
    if (camper.id == _selectedCamperId) return;
    unawaited(flush());
    _selectedCamperId = camper.id;
    _selectedCategory = null;
    _skillsMode = false;
    _syncBoard();
    update();
  }

  /// Switches between the cabins overview and the selected cabin.
  void toggleCabins() {
    if (selectedGroup == null) return;
    if (!showingCabins) unawaited(flush());
    showingCabins = !showingCabins;
    update();
  }

  void toggleCampersPane() {
    if (showingCabins) return;
    campersPaneOpen = !campersPaneOpen;
    update();
  }

  void selectCategory(ActivityCategory category) {
    _selectedCategory = category;
    _skillsMode = false;
    update();
  }

  void setSkillsMode(bool value) {
    _skillsMode = value;
    update();
  }

  Future<void> showActivityInfo(Activity activity) async {
    await _popups.showActivityInfo(activity);
  }

  // Editing -------------------------------------------------------------------

  /// A dragged activity was picked up: show the tab it belongs to, so it can
  /// be dropped back where it came from.
  void onDragStarted(Activity activity) {
    if (activity.isSkillsRec || activity.category == selectedCategory) return;
    _selectedCategory = activity.category;
    update();
  }

  /// Moves [activity] to [kind] (back to neutral when null) for the selected
  /// camper, unless that would exceed the session's limits.
  void place(Activity activity, PreferenceKind? kind) {
    final camper = selectedCamper;
    final current = board;
    if (camper == null || current == null) return;

    final placement = current.place(activity, kind);
    if (placement.isRejected) {
      Toast.warning(placement.rejection!);
      return;
    }
    if (!placement.changed) return;

    board = placement.board;
    _dirty[camper.id] = placement.board.choices;
    _scheduleAutosave();
    update();
  }

  /// Saves the selected camper's preferences as they are, which also marks
  /// them as done (e.g. a camper who is happy with anything).
  Future<void> markSelectedDone() async {
    final camper = selectedCamper;
    final current = board;
    if (camper == null || current == null) return;
    _dirty[camper.id] = current.choices;
    update();
    await save();
  }

  /// Rebuilds the board when the selected camper (or what is stored/being
  /// saved for them) changed. Pending drafts win over stored data.
  void _syncBoard() {
    final camper = selectedCamper;
    final limits = _limits;
    if (camper == null || limits == null) {
      board = null;
      _boardCamperId = null;
      return;
    }
    final fresh = PreferenceBoard(
      activities: _rankable,
      limits: limits,
      choices: _dirty[camper.id] ?? _inFlight[camper.id] ?? camper.preferences,
    );
    final current = board;
    if (current != null && _boardCamperId == camper.id && mapEquals(current.choices, fresh.choices)) return;
    board = fresh;
    _boardCamperId = camper.id;
  }

  // Saving --------------------------------------------------------------------

  void _scheduleAutosave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(autosaveDelay, () => unawaited(flush()));
  }

  /// The save button: saves everything pending and says so.
  Future<void> save() async {
    if (_dirty.isEmpty && _inFlight.isEmpty) return;
    if (await flush()) Toast.success('Preferences saved.');
  }

  /// Saves every pending draft, one camper at a time, and completes when
  /// nothing is pending any more. Returns whether everything was saved;
  /// failures have already been shown to the user.
  Future<bool> flush() {
    _autosaveTimer?.cancel();
    if (_dirty.isEmpty && _flushing == null) return Future.value(true);
    return _flushing ??= _saveDrafts().whenComplete(() {
      _flushing = null;
      // An edit may have slipped in as the last save finished.
      if (_dirty.isNotEmpty && !isClosed) _scheduleAutosave();
    });
  }

  Future<bool> _saveDrafts() async {
    var allSaved = true;
    while (_dirty.isNotEmpty) {
      final camperId = _dirty.keys.first;
      final choices = _dirty.remove(camperId)!;
      _inFlight[camperId] = choices;
      _refreshUi();
      try {
        await _roster.setPreferences(
          camperId: camperId,
          requestedActivityIds: _idsOf(choices, PreferenceKind.request),
          vetoedActivityIds: _idsOf(choices, PreferenceKind.veto),
        );
        _recordSaved(camperId, choices);
      } catch (e, st) {
        allSaved = false;
        _reportSaveFailure(camperId, e, st);
      } finally {
        _inFlight.remove(camperId);
      }
      // With the draft gone, the camper shows what is stored again (after a
      // failure) or what was just saved.
      _syncBoard();
      _refreshUi();
    }
    return allSaved;
  }

  List<String> _idsOf(Map<String, PreferenceKind> choices, PreferenceKind kind) => [
    for (final e in choices.entries)
      if (e.value == kind) e.key,
  ];

  void _recordSaved(String camperId, Map<String, PreferenceKind> choices) {
    final camper = _campers[camperId];
    if (camper == null) return;
    _campers[camperId] = camper.copyWith(preferences: choices, preferencesSubmittedAt: DateTime.now());
    _groups = null;
  }

  void _reportSaveFailure(String camperId, Object error, StackTrace stackTrace) {
    final exception = AppException.from(error, stackTrace);
    log.e('Saving preferences failed', error: exception.cause ?? exception, stackTrace: stackTrace);
    final name = _campers[camperId]?.displayTitle;
    Toast.error(exception.message, title: name == null ? 'Couldn\'t save preferences' : 'Couldn\'t save $name\'s preferences');
  }

  void _refreshUi() {
    if (!isClosed) update();
  }
}
