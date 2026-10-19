import 'dart:async';

import 'package:bessie/src/core/errors.dart';
import 'package:bessie/src/data/auth_repository.dart';
import 'package:bessie/src/data/catalog_repository.dart';
import 'package:bessie/src/data/profile_repository.dart';
import 'package:bessie/src/data/roster_repository.dart';
import 'package:bessie/src/data/session_repository.dart';
import 'package:bessie/src/features/schedule/schedule_grid.dart';
import 'package:bessie/src/features/schedule/schedule_page_controller.dart';
import 'package:bessie/src/models/camp_session.dart';
import 'package:bessie/src/models/camper.dart';
import 'package:bessie/src/models/schedule.dart';
import 'package:bessie/src/services/auth_service.dart';
import 'package:bessie/src/services/context_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'fixtures.dart';

class FakeRosterRepository extends RosterRepository {
  FakeRosterRepository(super.client);

  List<Camper> campers = [];
  final updates = StreamController<List<Camper>>.broadcast(sync: true);
  final watched = <String>[];

  @override
  Stream<List<Camper>> watchCampers(String sessionId) {
    watched.add(sessionId);
    return Stream.multi((controller) {
      controller.add(campers);
      final subscription = updates.stream.listen(controller.add);
      controller.onCancel = subscription.cancel;
    });
  }

  Future<void> emit(List<Camper> next) async {
    campers = next;
    updates.add(next);
    await pumpEventQueue();
  }
}

class FakeSessionRepository extends SessionRepository {
  FakeSessionRepository(super.client, this.schedule);

  Schedule schedule;
  Object? failWith;
  final requests = <String>[];

  @override
  Future<Schedule> fetchSchedule(String sessionId) async {
    requests.add(sessionId);
    if (failWith != null) throw AppException.from(failWith!);
    return schedule;
  }
}

SupabaseClient newClient() =>
    SupabaseClient('http://127.0.0.1:1', 'anon', authOptions: const AuthClientOptions(autoRefreshToken: false));

CampSession campSession(String id) => CampSession(
  id: id,
  seasonId: 'season',
  name: 'Session $id',
  startsOn: DateTime(2026, 7, 6),
  limits: const PreferenceLimits(maxRequests: 3, maxVetoes: 2, maxSkillsRequests: 2, maxSkillsVetoes: 1),
);

void main() {
  final monday = day(0);
  final archery = activity('archery', name: 'Archery', capacity: 1);
  final morning = block('morning', monday, title: 'Choice 1');
  final schedule = scheduleOf(
    days: [monday],
    blocks: [morning],
    scheduled: [scheduled('s-archery', morning, archery)],
    activities: [archery],
  );

  late FakeRosterRepository roster;
  late FakeSessionRepository sessions;
  late ContextService context;
  late SchedulePageController controller;

  setUp(() {
    Get.reset();
    final client = newClient();
    roster = FakeRosterRepository(client)..campers = [camper('a', assignments: {'morning': 's-archery'})];
    sessions = FakeSessionRepository(client, schedule);
    context = ContextService(
      CatalogRepository(client),
      ProfileRepository(client),
      AuthService(AuthRepository(client), ProfileRepository(client)),
    )..session.value = campSession('s1');

    Get.put<RosterRepository>(roster);
    Get.put<SessionRepository>(sessions);
    Get.put<ContextService>(context);
    controller = Get.put(SchedulePageController());
  });

  tearDown(Get.reset);

  Future<void> openPage() async {
    controller.onNavigateTo('/schedule-page', null);
    await pumpEventQueue();
  }

  ActivitySlot onlySlot() => controller.grid!.days.single.blocks.single.slots.single;

  test('loads the session\'s schedule with enrollment from the roster', () async {
    await openPage();

    expect(controller.isLoading, isFalse);
    expect(controller.loadError, isNull);
    expect(controller.sessionName, 'Session s1');
    expect(onlySlot().enrollmentLabel, '1/1');
    expect(sessions.requests, ['s1']);
  });

  test('follows the roster while the page is open', () async {
    await openPage();
    expect(onlySlot().isOverCapacity, isFalse);

    await roster.emit([
      camper('a', assignments: {'morning': 's-archery'}),
      camper('b', assignments: {'morning': 's-archery'}),
    ]);

    expect(onlySlot().enrollmentLabel, '2/1');
    expect(onlySlot().isOverCapacity, isTrue);
    expect(controller.grid!.overCapacityCount, 1);
  });

  test('stops following the roster when the page is left, and reloads on return', () async {
    await openPage();
    expect(roster.updates.hasListener, isTrue);

    controller.onNavigateFrom('/schedule-page', '/');
    await pumpEventQueue();
    expect(roster.updates.hasListener, isFalse);

    await openPage();
    expect(roster.updates.hasListener, isTrue);
    expect(sessions.requests, ['s1', 's1']);
  });

  test('reloads when the session changes while the page is open', () async {
    await openPage();
    roster.campers = [];

    context.session.value = campSession('s2');
    await pumpEventQueue();

    expect(sessions.requests, ['s1', 's2']);
    expect(controller.sessionName, 'Session s2');
    expect(onlySlot().enrollmentLabel, '0/1');
  });

  test('waits for the page to be opened after the session changed in the background', () async {
    await openPage();
    controller.onNavigateFrom('/schedule-page', '/');

    context.session.value = campSession('s2');
    await pumpEventQueue();
    expect(sessions.requests, ['s1']);
    expect(controller.grid, isNull);

    controller.ensureLoaded();
    await pumpEventQueue();
    expect(sessions.requests, ['s1', 's2']);
    expect(controller.grid, isNotNull);
  });

  test('ensureLoaded loads once when shown without navigation', () async {
    controller.ensureLoaded();
    controller.ensureLoaded();
    await pumpEventQueue();

    expect(sessions.requests, ['s1']);
    expect(controller.grid, isNotNull);

    controller.ensureLoaded();
    await pumpEventQueue();
    expect(sessions.requests, ['s1']);
  });

  test('has nothing to show without a session', () async {
    context.session.value = null;
    await openPage();

    expect(controller.hasSession, isFalse);
    expect(controller.grid, isNull);
    expect(controller.isLoading, isFalse);
    expect(sessions.requests, isEmpty);
  });

  test('reports a failure to load', () async {
    sessions.failWith = PostgrestException(message: 'boom', code: 'XX000');
    await openPage();

    expect(controller.isLoading, isFalse);
    expect(controller.loadError, 'The server rejected that request.');
    expect(controller.grid, isNull);

    sessions.failWith = null;
    await controller.reload();
    expect(controller.loadError, isNull);
    expect(controller.grid, isNotNull);
  });
}
