import 'package:bessie/src/data/auth_repository.dart';
import 'package:bessie/src/data/catalog_repository.dart';
import 'package:bessie/src/data/profile_repository.dart';
import 'package:bessie/src/data/roster_repository.dart';
import 'package:bessie/src/data/session_repository.dart';
import 'package:bessie/src/models/enums.dart';
import 'package:bessie/src/models/schedule.dart';
import 'package:bessie/src/services/auth_service.dart';
import 'package:bessie/src/services/context_service.dart';
import 'package:bessie/src/shared/services/popup_service.dart';
import 'package:bessie/src/shared/widgets/header/controllers/menu_bar_controller.dart';
import 'package:get/get.dart';

import 'fakes.dart';
import 'fixtures.dart';

/// A session with two cabins (Oak: Amy and Bo; Fox: Cy), a block offering a
/// handful of activities, and the fakes standing in for the database, all
/// registered with GetX the way the app does after sign-in (minus the
/// preferences controller itself).
class PreferencesEnvironment {
  final archery = activity('archery', name: 'Archery', category: ActivityCategory.sportsAndAthletics);
  final pottery = activity('pottery', name: 'Pottery');
  final drama = activity('drama', name: 'Drama');
  final tieDye = activity('tiedye', name: 'Tie-Dye');
  final kayak = activity('kayak', name: 'Kayaking', category: ActivityCategory.waterfront);
  final swimSkills = activity('swimskills', name: 'Swim Skills', skills: true);
  final swimTest = activity('swimtest', name: 'Swim Test', hidden: true);
  final teenSkills = activity('teen', name: 'Teen Skills', skills: true, preferenceRequired: false);

  late FakeRosterRepository roster;
  late FakeSessionRepository sessions;
  late ContextService context;

  Schedule buildSchedule() {
    final day = ScheduleDay(id: 'day', sessionId: 's1', dayIndex: 0, date: DateTime(2026, 7, 6));
    final block = Block(
      id: 'block',
      sessionId: 's1',
      dayId: 'day',
      title: 'Choice',
      date: day.date,
      dayIndex: 0,
      startTime: const Duration(hours: 10),
      endTime: const Duration(hours: 11),
      isSkillsRec: false,
    );
    final everything = [archery, pottery, drama, tieDye, kayak, swimSkills, swimTest, teenSkills];
    return Schedule(
      days: [day],
      blocks: [block],
      scheduledActivities: [
        for (final a in everything) ScheduledActivity(id: 'sa-${a.id}', sessionId: 's1', blockId: 'block', activityId: a.id),
      ],
      activitiesById: {for (final a in everything) a.id: a},
    );
  }

  /// Starts from a clean GetX and registers fresh fakes.
  void register() {
    Get.reset();
    final client = newClient();
    roster = FakeRosterRepository(client)
      ..campers = [
        camper('amy', first: 'Amy', last: 'Adams', cabinId: 'oak'),
        camper(
          'bo',
          first: 'Bo',
          last: 'Brown',
          cabinId: 'oak',
          preferences: {'pottery': PreferenceKind.request},
          submittedAt: DateTime(2026, 7, 1),
        ),
        camper('cy', first: 'Cy', last: 'Clark', cabinId: 'fox'),
      ];
    sessions = FakeSessionRepository(
      client,
      cabins: [cabin('oak', name: 'Oak', position: 1), cabin('fox', name: 'Fox', position: 2)],
      schedule: buildSchedule(),
    );
    context = ContextService(
      CatalogRepository(client),
      ProfileRepository(client),
      AuthService(AuthRepository(client), ProfileRepository(client)),
    )..session.value = campSession('s1');

    Get.put<RosterRepository>(roster);
    Get.put<SessionRepository>(sessions);
    Get.put<ContextService>(context);
    Get.put(PopupService());
    Get.put(MenuBarController());
  }
}
