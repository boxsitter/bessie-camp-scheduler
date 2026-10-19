import 'dart:async';

import 'package:get/get.dart';

import '../../core/errors.dart';
import '../../data/roster_repository.dart';
import '../../data/session_repository.dart';
import '../../models/camper.dart';
import '../../models/schedule.dart';
import '../../services/context_service.dart';
import '../../shared/mixins/route_aware_controller_mixin.dart';
import '../../shared/services/toast.dart';
import 'schedule_grid.dart';

/// Loads the current session's schedule and enrollment for the printable
/// weekly schedule page. Enrollment follows the roster live while the page is
/// open; the schedule itself is read each time the page is opened (or the
/// session changes).
class SchedulePageController extends GetxController with RouteAwareControllerMixin {
  final ContextService _context = Get.find<ContextService>();
  final SessionRepository _sessions = Get.find<SessionRepository>();
  final RosterRepository _roster = Get.find<RosterRepository>();

  bool isLoading = false;
  String? loadError;

  /// Null until loaded (and when no session is selected).
  ScheduleGrid? grid;

  /// The session the grid belongs to.
  String? sessionName;

  Schedule? _schedule;
  List<Camper> _campers = const [];
  bool _loaded = false;
  bool _stale = false;
  bool _pageActive = false;
  bool _streamErrorShown = false;
  int _generation = 0;
  StreamSubscription<List<Camper>>? _campersSubscription;
  Worker? _sessionWorker;

  @override
  void onInit() {
    super.onInit();
    _sessionWorker = ever(_context.session, (_) => _onSessionChanged());
  }

  @override
  void onClose() {
    _sessionWorker?.dispose();
    unawaited(_campersSubscription?.cancel());
    _campersSubscription = null;
    super.onClose();
  }

  bool get hasSession => _context.session.value != null;

  @override
  void onNavigateTo(String to, String? from) {
    _pageActive = true;
    unawaited(_load());
  }

  @override
  void onNavigateFrom(String from, String to) {
    _pageActive = false;
    // Not visible: stop following the roster until the page is opened again.
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

  Future<void> reload() => _load();

  void _onSessionChanged() {
    if (_pageActive) {
      unawaited(_load());
      return;
    }
    // Not on screen: forget everything; the page loads when it is opened.
    unawaited(_campersSubscription?.cancel());
    _campersSubscription = null;
    _generation++;
    _stale = true;
    _schedule = null;
    _campers = const [];
    grid = null;
    sessionName = _context.session.value?.name;
    isLoading = false;
    _refreshUi();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    final session = _context.session.value;
    unawaited(_campersSubscription?.cancel());
    _campersSubscription = null;
    _loaded = false;
    _stale = false;
    loadError = null;
    sessionName = session?.name;

    if (session == null) {
      _schedule = null;
      _campers = const [];
      grid = null;
      isLoading = false;
      _refreshUi();
      return;
    }

    isLoading = true;
    _refreshUi();
    try {
      final scheduleFuture = _sessions.fetchSchedule(session.id);
      final firstCampers = Completer<void>();
      _campersSubscription = _roster
          .watchCampers(session.id)
          .listen(
            (campers) {
              if (generation != _generation) return;
              _streamErrorShown = false;
              _campers = campers;
              if (!firstCampers.isCompleted) {
                firstCampers.complete();
              } else {
                _rebuildGrid();
              }
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

      await Future.wait<Object?>([scheduleFuture, firstCampers.future]);
      if (generation != _generation) return;

      _schedule = await scheduleFuture;
      grid = ScheduleGrid.build(_schedule!, _campers);
      _loaded = true;
      isLoading = false;
      _refreshUi();
    } catch (e, st) {
      if (generation != _generation) return;
      unawaited(_campersSubscription?.cancel());
      _campersSubscription = null;
      loadError = AppException.from(e, st).message;
      isLoading = false;
      Toast.failure(e, st);
      _refreshUi();
    }
  }

  void _rebuildGrid() {
    final schedule = _schedule;
    if (!_loaded || schedule == null) return;
    grid = ScheduleGrid.build(schedule, _campers);
    _refreshUi();
  }

  void _refreshUi() {
    if (!isClosed) update();
  }
}
