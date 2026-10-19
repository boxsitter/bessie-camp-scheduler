import 'dart:async';

import 'package:collection/collection.dart';
import 'package:get/get.dart';

import '../../core/errors.dart';
import '../../data/catalog_repository.dart';
import '../../data/roster_repository.dart';
import '../../data/session_repository.dart';
import '../../models/activity.dart';
import '../../models/cabin.dart';
import '../../models/camp_session.dart';
import '../../models/camper.dart';
import '../../models/schedule.dart';
import '../../services/auth_service.dart';
import '../../services/context_service.dart';
import '../../shared/mixins/route_aware_controller_mixin.dart';
import '../../shared/services/popup_service.dart';
import '../../shared/services/toast.dart';
import '../branch_manager/catalog_logic.dart';
import '../branch_manager/widgets/form_widgets.dart';
import 'session_setup_logic.dart';
import 'widgets/add_activities_dialog.dart';
import 'widgets/new_session_dialog.dart';

/// Sets up the current session: its cabins, preference limits and schedule,
/// and creates new sessions.
class SessionManagerController extends GetxController with RouteAwareControllerMixin {
  final ContextService _context = Get.find<ContextService>();
  final AuthService _auth = Get.find<AuthService>();
  final CatalogRepository _catalog = Get.find<CatalogRepository>();
  final SessionRepository _sessions = Get.find<SessionRepository>();
  final RosterRepository _roster = Get.find<RosterRepository>();
  final PopupService _popups = Get.find<PopupService>();

  /// What was read for the current session; null until it has loaded.
  final Rxn<SessionSetup> setup = Rxn<SessionSetup>();
  final RxBool isLoading = false.obs;
  final RxnString loadError = RxnString();

  /// True while a change is being written, so buttons can wait their turn.
  final RxBool isSaving = false.obs;

  /// The cabins ticked in the cabin list (saved or not), by id.
  final RxSet<String> selectedCabinIds = <String>{}.obs;

  /// The preference limits shown in the steppers (saved or not).
  final Rx<LimitsDraft> limitsDraft = LimitsDraft.defaults.obs;

  Worker? _sessionWorker;
  int _generation = 0;

  /// Only root, directors and admins change session data; the database
  /// enforces it too.
  bool get canEdit => _auth.profile.value?.role.canEditSessionData ?? false;

  /// Whether the current season has any session at all.
  bool get hasSession => _context.session.value != null;

  String? get seasonName => _context.season.value?.name;

  @override
  void onInit() {
    super.onInit();
    _sessionWorker = ever(_context.session, _onSessionChanged);
    unawaited(reload());
  }

  @override
  void onClose() {
    _sessionWorker?.dispose();
    super.onClose();
  }

  @override
  void onNavigateTo(String to, String? from) {
    unawaited(reload());
  }

  void _onSessionChanged(CampSession? session) {
    // Never show one session's data under another's name.
    if (session?.id != setup.value?.session.id) {
      setup.value = null;
      loadError.value = null;
    }
    unawaited(reload());
  }

  /// Reads the current session again. Saved changes stay on screen meanwhile;
  /// only a first load or a session switch shows a spinner.
  Future<void> reload() async {
    final session = _context.session.value;
    final branch = _context.branch.value;
    if (session == null || branch == null) {
      _generation++;
      setup.value = null;
      loadError.value = null;
      isLoading.value = false;
      return;
    }

    final generation = ++_generation;
    if (setup.value == null) isLoading.value = true;
    try {
      final loaded = await Future.wait<Object>([
        _catalog.listCabins(branch.id),
        _sessions.listSessionCabins(session.id),
        _sessions.fetchSchedule(session.id),
        _roster.fetchCampers(session.id),
        _catalog.listActivities(branch.id),
      ]);
      if (generation != _generation) return;
      _apply(
        SessionSetup(
          session: session,
          cabins: loaded[0] as List<Cabin>,
          registeredCabinIds: [for (final cabin in loaded[1] as List<Cabin>) cabin.id],
          schedule: loaded[2] as Schedule,
          campers: loaded[3] as List<Camper>,
          activities: loaded[4] as List<Activity>,
        ),
      );
      loadError.value = null;
    } catch (e, st) {
      if (generation != _generation) return;
      Toast.failure(e, st);
      loadError.value = AppException.from(e, st).message;
    } finally {
      if (generation == _generation) isLoading.value = false;
    }
  }

  /// Shows [next], keeping what the user has changed but not saved yet when
  /// it is still the same session.
  void _apply(SessionSetup next) {
    final previous = setup.value;
    final sameSession = previous != null && previous.session.id == next.session.id;

    final cabinsEdited = sameSession && !const SetEquality<String>().equals(selectedCabinIds, previous.registeredCabinIds);
    if (cabinsEdited) {
      selectedCabinIds.removeWhere((id) => !next.branchCabinIds.contains(id));
    } else {
      selectedCabinIds.assignAll(next.registeredCabinIds);
    }

    final limitsEdited = sameSession && limitsDraft.value != LimitsDraft.fromLimits(previous.session.limits);
    if (!limitsEdited) limitsDraft.value = LimitsDraft.fromLimits(next.session.limits);

    setup.value = next;
  }

  // Cabins ----------------------------------------------------------------------

  void toggleCabin(String cabinId) {
    if (!selectedCabinIds.remove(cabinId)) selectedCabinIds.add(cabinId);
  }

  void setCabinsSelected(Iterable<String> cabinIds, bool selected) {
    if (selected) {
      selectedCabinIds.addAll(cabinIds);
    } else {
      selectedCabinIds.removeAll(cabinIds);
    }
  }

  void resetCabins() {
    final current = setup.value;
    if (current != null) selectedCabinIds.assignAll(current.registeredCabinIds);
  }

  /// Makes the session use exactly the ticked cabins, after confirming when
  /// that would leave campers without a cabin.
  Future<void> saveCabins() async {
    final current = setup.value;
    if (current == null || !_ensureCanEdit()) return;
    final sessionId = current.session.id;
    final selected = selectedCabinIds.toSet();

    // Count against the roster as it is now, not as it was when the page loaded.
    final campers = await attempt(() => _roster.fetchCampers(sessionId));
    if (campers == null) return;
    final change = diffCabinSelection(registered: current.registeredCabinIds, selected: selected, campersByCabin: camperCountsByCabin(campers));
    if (change.isEmpty) return;

    if (change.campersLeftWithoutCabin > 0) {
      final confirmed = await _popups.showConfirmationDialog(
        title: 'Remove ${pluralize(change.removed.length, 'cabin')}?',
        message: '${pluralize(change.campersLeftWithoutCabin, 'camper')} will be left without a cabin. They stay on the roster and can be placed in another cabin.',
      );
      if (!confirmed) return;
    }

    await _write(() async {
      await _sessions.setSessionCabins(sessionId, selected);
      await reload();
      Toast.success('Cabins saved.');
    });
  }

  // Preference limits -----------------------------------------------------------

  void setLimits(LimitsDraft limits) => limitsDraft.value = limits;

  void resetLimits() {
    final current = setup.value;
    if (current != null) limitsDraft.value = LimitsDraft.fromLimits(current.session.limits);
  }

  Future<void> saveLimits() async {
    final current = setup.value;
    if (current == null || !_ensureCanEdit()) return;
    await _write(() async {
      await _sessions.updateLimits(current.session.id, limitsDraft.value.toLimits());
      // Everything else reads the limits from the context's session, which
      // announces the change to every page.
      await _context.refreshSessions();
      Toast.success('Preference limits saved.');
    });
  }

  // Schedule --------------------------------------------------------------------

  /// Asks which activities to offer during [block] and schedules them.
  Future<void> addActivities(Block block) async {
    final current = setup.value;
    if (current == null || !_ensureCanEdit()) return;

    final groups = addableActivityGroups(
      block: block,
      catalog: current.activities,
      offeredActivityIds: [for (final scheduled in current.schedule.scheduledIn(block.id)) scheduled.activityId],
    );
    if (groups.isEmpty) {
      Toast.info(
        current.activities.isEmpty
            ? 'The branch has no activities yet. Add some on the branch catalog page.'
            : 'Every activity is already offered during ${block.displayTitle}.',
      );
      return;
    }

    final chosen = await showFormDialog<List<String>>(AddActivitiesDialog(block: block, groups: groups));
    if (chosen == null || chosen.isEmpty) return;
    await scheduleActivities(block, chosen);
  }

  /// Offers the activities [activityIds] during [block].
  Future<void> scheduleActivities(Block block, List<String> activityIds) async {
    final current = setup.value;
    if (current == null || !_ensureCanEdit()) return;
    await _write(() async {
      await _sessions.scheduleActivities(sessionId: current.session.id, blockId: block.id, activityIds: activityIds);
      await reload();
      Toast.success('Added ${pluralize(activityIds.length, 'activity', 'activities')} to ${block.displayTitle}.');
    });
  }

  /// Stops offering [scheduled] during [block], after confirming and saying
  /// how many campers lose the assignment.
  Future<void> removeActivity(Block block, ScheduledActivity scheduled) async {
    final current = setup.value;
    if (current == null || !_ensureCanEdit()) return;
    final activity = current.schedule.activityOf(scheduled);
    final name = activity?.name ?? 'this activity';

    final campers = await attempt(() => _roster.fetchCampers(current.session.id));
    if (campers == null) return;
    final enrolled = enrollmentCounts(campers)[scheduled.id] ?? 0;

    final consequences = enrolled == 0 ? 'No campers are assigned to it.' : '${pluralize(enrolled, 'camper')} assigned to it will lose that assignment.';
    final doubleBlock = (activity?.doubleSchedule ?? false) ? ' It is a double block activity: remove it from the neighboring block too.' : '';
    final confirmed = await _popups.showConfirmationDialog(
      title: 'Remove $name?',
      message: '$name will no longer be offered during ${block.displayTitle}. $consequences$doubleBlock',
    );
    if (!confirmed) return;

    await _write(() async {
      await _sessions.unscheduleActivities([scheduled.id]);
      await reload();
      Toast.success('Removed $name from ${block.displayTitle}.');
    });
  }

  // New session -----------------------------------------------------------------

  Future<void> openNewSession() {
    if (!_ensureCanEdit()) return Future.value();
    final season = _context.season.value;
    final current = _context.session.value;
    return showFormDialog<bool>(
      NewSessionDialog(
        existingNames: [for (final session in _context.sessions) session.name],
        season: season,
        initialStart: suggestedSessionStart(sessions: _context.sessions, season: season, today: DateTime.now()),
        initialLimits: current == null ? LimitsDraft.defaults : LimitsDraft.fromLimits(current.limits),
        onSubmit: createSession,
      ),
    );
  }

  /// Creates the session and switches to it. Throws an [AppException] when the
  /// database refuses (for example a duplicate name).
  Future<void> createSession(NewSessionRequest request) async {
    final created = await _sessions.createSession(
      seasonId: _context.seasonId,
      name: request.name,
      startsOn: request.startsOn,
      maxRequests: request.limits.maxRequests,
      maxVetoes: request.limits.maxVetoes,
      maxSkillsRequests: request.limits.maxSkillsRequests,
      maxSkillsVetoes: request.limits.maxSkillsVetoes,
      registerAllCabins: request.registerAllCabins,
    );
    Toast.success('Created "${created.name}".');
    // The session exists now, so a failure to switch to it is not the dialog's.
    try {
      await _context.adoptNewSession(created);
    } catch (e, st) {
      Toast.failure(e, st);
    }
  }

  // Helpers ---------------------------------------------------------------------

  /// Runs a write with [isSaving] set, reporting a failure as a toast.
  Future<void> _write(Future<void> Function() action) async {
    if (isSaving.value) return;
    isSaving.value = true;
    try {
      await action();
    } catch (e, st) {
      Toast.failure(e, st);
    } finally {
      isSaving.value = false;
    }
  }

  bool _ensureCanEdit() {
    if (canEdit) return true;
    Toast.warning('Only directors and admins can change session data.');
    return false;
  }
}
