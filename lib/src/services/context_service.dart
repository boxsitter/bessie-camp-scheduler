import 'package:get/get.dart';

import '../core/errors.dart';
import '../core/logging.dart';
import '../data/catalog_repository.dart';
import '../data/profile_repository.dart';
import '../models/camp_session.dart';
import '../models/organization.dart';
import 'auth_service.dart';

/// Where the user is working: which organization, branch, season and session.
///
/// Everything session-scoped (rosters, schedule, preferences) reads
/// [session]; screens react to [session] changing to reload.
class ContextService extends GetxService {
  ContextService(this._catalog, this._profiles, this._auth);

  final CatalogRepository _catalog;
  final ProfileRepository _profiles;
  final AuthService _auth;

  static const _lastSessionKey = 'last_session_id';

  final Rxn<Organization> organization = Rxn<Organization>();
  final Rxn<Branch> branch = Rxn<Branch>();
  final Rxn<Season> season = Rxn<Season>();
  final Rxn<CampSession> session = Rxn<CampSession>();

  /// The sessions of the current season, oldest first.
  final RxList<CampSession> sessions = <CampSession>[].obs;

  bool get isLoaded => session.value != null;

  String get sessionId => _require(session.value, 'session').id;
  String get branchId => _require(branch.value, 'branch').id;
  String get seasonId => _require(season.value, 'season').id;
  CampSession get currentSession => _require(session.value, 'session');

  T _require<T>(T? value, String what) {
    if (value == null) throw StateError('No $what is selected yet. Has the context been loaded?');
    return value;
  }

  /// Resolves the organization, branch, season and session to start in.
  ///
  /// Bessie runs one camp per deployment, so the organization and branch are
  /// the first ones visible to the user. The season is the one containing
  /// today (or the most recent), and the session is the one the user used last
  /// or, failing that, the one closest to today.
  Future<void> load({DateTime? today}) async {
    final now = today ?? DateTime.now();
    final org = await _catalog.fetchOrganization();
    if (org == null) throw AppException('Your organization could not be found.');
    final branches = await _catalog.listBranches();
    if (branches.isEmpty) throw AppException('Your organization has no branches yet.');
    final seasons = await _catalog.listSeasons(branches.first.id);
    if (seasons.isEmpty) throw AppException('This branch has no seasons yet. Create one to get started.');

    organization.value = org;
    branch.value = branches.first;
    season.value = pickSeason(seasons, now);
    await _loadSessions(preferredId: _auth.profile.value?.preferences[_lastSessionKey] as String?, today: now);
  }

  Future<void> _loadSessions({String? preferredId, DateTime? today}) async {
    final loaded = await _catalog.listSessions(seasonId);
    sessions.assignAll(loaded);
    if (loaded.isEmpty) {
      session.value = null;
      return;
    }
    session.value = loaded.firstWhereOrNull((s) => s.id == preferredId) ?? pickSession(loaded, today ?? DateTime.now());
  }

  /// Re-reads the sessions of the season (e.g. after creating one).
  Future<void> refreshSessions() => _loadSessions(preferredId: session.value?.id);

  Future<void> switchSession(String sessionId) async {
    final target = sessions.firstWhereOrNull((s) => s.id == sessionId);
    if (target == null) throw AppException('That session no longer exists.');
    session.value = target;
    await _rememberSession(target.id);
  }

  /// Selects a session that was just created and remembers it.
  Future<void> adoptNewSession(CampSession created) async {
    await _loadSessions(preferredId: created.id);
    await _rememberSession(created.id);
  }

  Future<void> _rememberSession(String id) async {
    final profile = _auth.profile.value;
    if (profile == null) return;
    try {
      await _profiles.updatePreferences(profile.preferences, {_lastSessionKey: id});
      profile.preferences[_lastSessionKey] = id;
    } catch (e, st) {
      log.w('Could not remember the selected session', error: e, stackTrace: st);
    }
  }

  void clear() {
    organization.value = null;
    branch.value = null;
    season.value = null;
    session.value = null;
    sessions.clear();
  }

  /// The season containing [today], else the latest one that has started,
  /// else the earliest upcoming one. [seasons] must be newest first.
  static Season pickSeason(List<Season> seasons, DateTime today) {
    final day = DateTime(today.year, today.month, today.day);
    return seasons.firstWhereOrNull((s) => s.contains(day)) ?? seasons.firstWhereOrNull((s) => !s.startsOn.isAfter(day)) ?? seasons.last;
  }

  /// The most recent session that has started, else the soonest upcoming one.
  static CampSession pickSession(List<CampSession> sessions, DateTime today) {
    final day = DateTime(today.year, today.month, today.day);
    final started = sessions.where((s) => !s.startsOn.isAfter(day)).toList();
    if (started.isNotEmpty) return started.reduce((a, b) => a.startsOn.isAfter(b.startsOn) ? a : b);
    return sessions.reduce((a, b) => a.startsOn.isBefore(b.startsOn) ? a : b);
  }
}
