import 'dart:async';

import 'package:bessie/src/core/errors.dart';
import 'package:bessie/src/data/roster_repository.dart';
import 'package:bessie/src/data/session_repository.dart';
import 'package:bessie/src/models/camp_session.dart';
import 'package:bessie/src/models/camper.dart';
import 'package:bessie/src/models/schedule.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

SupabaseClient newClient() => SupabaseClient('http://127.0.0.1:1', 'anon', authOptions: const AuthClientOptions(autoRefreshToken: false));

CampSession campSession(String id) => CampSession(
  id: id,
  seasonId: 'season',
  name: 'Session $id',
  startsOn: DateTime(2026, 7, 6),
  limits: const PreferenceLimits(maxRequests: 3, maxVetoes: 2, maxSkillsRequests: 2, maxSkillsVetoes: 1),
);
