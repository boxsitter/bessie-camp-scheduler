import 'dart:async';

import 'package:bessie/src/data/roster_repository.dart';
import 'package:bessie/src/data/session_repository.dart';
import 'package:bessie/src/models/cabin.dart';
import 'package:bessie/src/models/camper.dart';
import 'package:bessie/src/models/schedule.dart';

class FakeRosterRepository extends RosterRepository {
  FakeRosterRepository(super.client);

  final List<StreamController<List<Camper>>> streams = [];
  final List<String> watched = [];
  int cancelled = 0;
  final List<(List<String>, bool)> arrivedCalls = [];
  final List<List<String>> deleteCalls = [];

  StreamController<List<Camper>> get latest => streams.last;

  @override
  Stream<List<Camper>> watchCampers(String sessionId) {
    final controller = StreamController<List<Camper>>(onCancel: () => cancelled++);
    streams.add(controller);
    watched.add(sessionId);
    return controller.stream;
  }

  @override
  Future<void> setArrived(Iterable<String> camperIds, bool arrived) async => arrivedCalls.add((camperIds.toList(), arrived));

  @override
  Future<void> deleteCampers(Iterable<String> camperIds) async => deleteCalls.add(camperIds.toList());
}

class FakeSessionRepository extends SessionRepository {
  FakeSessionRepository(super.client);

  final Map<String, Schedule> schedules = {};
  final Map<String, List<Cabin>> cabins = {};

  @override
  Future<Schedule> fetchSchedule(String sessionId) async => schedules[sessionId]!;

  @override
  Future<List<Cabin>> listSessionCabins(String sessionId) async => cabins[sessionId] ?? const [];
}
