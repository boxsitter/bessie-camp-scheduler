import 'package:bessie/src/data/auth_repository.dart';
import 'package:bessie/src/data/catalog_repository.dart';
import 'package:bessie/src/data/profile_repository.dart';
import 'package:bessie/src/data/roster_repository.dart';
import 'package:bessie/src/data/session_repository.dart';
import 'package:bessie/src/models/activity.dart';
import 'package:bessie/src/models/camp_session.dart';
import 'package:bessie/src/models/camper.dart';
import 'package:bessie/src/models/enums.dart';
import 'package:bessie/src/models/organization.dart';
import 'package:bessie/src/models/schedule.dart';
import 'package:bessie/src/models/staff_profile.dart';
import 'package:bessie/src/services/auth_service.dart';
import 'package:bessie/src/services/context_service.dart';
import 'package:bessie/src/services/file_service.dart';
import 'package:file_saver/file_saver.dart' show MimeType;
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A Supabase client that never connects anywhere; the fakes below override
/// every method that would use it.
SupabaseClient unconnectedClient() =>
    SupabaseClient('http://127.0.0.1:1', 'test-anon-key', authOptions: const AuthClientOptions(autoRefreshToken: false));

const limits = PreferenceLimits(maxRequests: 3, maxVetoes: 2, maxSkillsRequests: 2, maxSkillsVetoes: 1);

CampSession campSession(String id, String name, DateTime startsOn, {String seasonId = 'season-1'}) =>
    CampSession(id: id, seasonId: seasonId, name: name, startsOn: startsOn, limits: limits);

StaffProfile staffProfile({StaffRole role = StaffRole.admin, String first = 'Ada', String last = 'Lovelace', String? preferred}) =>
    StaffProfile(
      id: 'user-1',
      organizationId: 'org-1',
      firstName: first,
      lastName: last,
      preferredName: preferred,
      role: role,
      active: true,
      preferences: {},
    );

Camper camper(String id, String first, {Map<String, String> assignments = const {}}) => Camper(
  id: id,
  sessionId: 'session-1',
  firstName: first,
  preferredName: null,
  lastName: 'Camper',
  gender: null,
  birthdate: DateTime(2014, 5, 1),
  note: '',
  cabinId: null,
  ultracampId: null,
  arrived: false,
  canSwim: true,
  satisfactionIndex: null,
  preferencesSubmittedAt: null,
  assignments: assignments,
);

Activity activity(String id, String name, {bool isSkillsRec = false}) => Activity(
  id: id,
  branchId: 'branch-1',
  name: name,
  description: '',
  capacity: 10,
  category: ActivityCategory.other,
  isSkillsRec: isSkillsRec,
  doubleSchedule: false,
  maxAssignments: null,
  isHidden: false,
  preferenceRequired: false,
);

/// A block on [date] from [startHour]:00 to [startHour + 1]:00.
Block block(String id, String title, DateTime date, {int dayIndex = 0, int startHour = 10, bool isSkillsRec = false}) => Block(
  id: id,
  sessionId: 'session-1',
  dayId: 'day-$dayIndex',
  title: title,
  date: date,
  dayIndex: dayIndex,
  startTime: Duration(hours: startHour),
  endTime: Duration(hours: startHour + 1),
  isSkillsRec: isSkillsRec,
);

class FakeCatalogRepository extends CatalogRepository {
  FakeCatalogRepository({this.sessions = const [], this.activities = const [], this.seasons = const [], this.branches = const []})
    : super(unconnectedClient());

  List<CampSession> sessions;
  List<Activity> activities;
  List<Season> seasons;
  List<Branch> branches;

  @override
  Future<List<CampSession>> listSessions(String seasonId) async => List.of(sessions);

  @override
  Future<List<Activity>> listActivities(String branchId) async => List.of(activities);

  @override
  Future<List<Season>> listSeasons(String branchId) async => List.of(seasons);

  @override
  Future<List<Branch>> listBranches() async => List.of(branches);
}

class FakeSessionRepository extends SessionRepository {
  FakeSessionRepository({this.schedule, this.catalog}) : super(unconnectedClient());

  Schedule? schedule;

  /// When set, newly created sessions are added to it, like the database would.
  FakeCatalogRepository? catalog;

  final List<({String seasonId, String name, DateTime startsOn})> created = [];
  final List<({String blockId, List<String> activityIds})> scheduled = [];
  final List<List<String>> unscheduled = [];

  @override
  Future<CampSession> createSession({
    required String seasonId,
    required String name,
    required DateTime startsOn,
    int maxRequests = 3,
    int maxVetoes = 2,
    int maxSkillsRequests = 2,
    int maxSkillsVetoes = 1,
    bool registerAllCabins = true,
  }) async {
    created.add((seasonId: seasonId, name: name, startsOn: startsOn));
    final session = campSession('new-${created.length}', name, startsOn, seasonId: seasonId);
    catalog?.sessions = [...catalog!.sessions, session];
    return session;
  }

  @override
  Future<Schedule> fetchSchedule(String sessionId) async =>
      schedule ?? Schedule(days: [], blocks: [], scheduledActivities: [], activitiesById: {});

  @override
  Future<void> scheduleActivities({required String sessionId, required String blockId, required Iterable<String> activityIds}) async {
    scheduled.add((blockId: blockId, activityIds: activityIds.toList()));
  }

  @override
  Future<void> unscheduleActivities(Iterable<String> scheduledActivityIds) async {
    unscheduled.add(scheduledActivityIds.toList());
  }
}

class FakeRosterRepository extends RosterRepository {
  FakeRosterRepository({this.campers = const []}) : super(unconnectedClient());

  List<Camper> campers;
  final List<({String sessionId, bool clearPreferences})> resets = [];

  @override
  Future<List<Camper>> fetchCampers(String sessionId) async => campers;

  @override
  Future<void> resetAssignments(String sessionId, {bool clearPreferences = false}) async {
    resets.add((sessionId: sessionId, clearPreferences: clearPreferences));
  }
}

class FakeFileService extends FileService {
  FakeFileService();

  final List<({String name, String extension, String contents})> saved = [];

  @override
  Future<void> saveText({required String name, required String extension, required String contents, required MimeType mimeType}) async {
    saved.add((name: name, extension: extension, contents: contents));
  }
}

/// Real [AuthService] and [ContextService] objects that never touch the network.
class TestWorld {
  TestWorld({List<CampSession> sessions = const [], StaffProfile? profile}) : catalog = FakeCatalogRepository(sessions: sessions) {
    final client = unconnectedClient();
    auth = AuthService(AuthRepository(client), ProfileRepository(client));
    context = ContextService(catalog, ProfileRepository(client), auth);
    auth.profile.value = profile;
  }

  final FakeCatalogRepository catalog;
  late final AuthService auth;
  late final ContextService context;

  /// Puts the context in a 2026 season with [sessions] and the first one selected.
  void loadSeason({String name = 'Summer 2026', DateTime? startsOn, DateTime? endsOn}) {
    context.organization.value = const Organization(id: 'org-1', name: 'Camp Bessie');
    context.branch.value = const Branch(id: 'branch-1', organizationId: 'org-1', name: 'Main Branch');
    context.season.value = Season(
      id: 'season-1',
      branchId: 'branch-1',
      name: name,
      startsOn: startsOn ?? DateTime(2026, 6, 1),
      endsOn: endsOn ?? DateTime(2026, 8, 30),
    );
    context.sessions.assignAll(catalog.sessions);
    context.session.value = catalog.sessions.firstOrNull;
  }
}
