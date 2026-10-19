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
  final List<(String, List<CamperImportRow>)> importCalls = [];
  CamperImportResult importResult = const CamperImportResult(inserted: 0, duplicates: 0, unknownCabins: []);
  final List<(List<String>, String?)> cabinCalls = [];
  final List<List<String>> swapCalls = [];
  final List<(List<String>, String)> assignCalls = [];
  final List<(List<String>, String?, String?)> unassignCalls = [];
  final List<List<String>> clearCalls = [];
  final List<({String camperId, List<String> requests, List<String> vetoes})> preferenceCalls = [];

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

  @override
  Future<CamperImportResult> importCampers(String sessionId, List<CamperImportRow> rows) async {
    importCalls.add((sessionId, rows));
    return importResult;
  }

  @override
  Future<void> setCabin(Iterable<String> camperIds, String? cabinId) async => cabinCalls.add((camperIds.toList(), cabinId));

  @override
  Future<void> swapCabins(Iterable<String> camperIds) async => swapCalls.add(camperIds.toList());

  @override
  Future<int> assignCampers(
    Iterable<String> camperIds,
    String scheduledActivityId, {
    bool replaceExisting = true,
    bool enforceCapacity = false,
  }) async {
    assignCalls.add((camperIds.toList(), scheduledActivityId));
    return camperIds.length;
  }

  @override
  Future<int> unassignCampers(Iterable<String> camperIds, {String? blockId, String? scheduledActivityId}) async {
    unassignCalls.add((camperIds.toList(), blockId, scheduledActivityId));
    return camperIds.length;
  }

  @override
  Future<void> clearPreferences(Iterable<String> camperIds) async => clearCalls.add(camperIds.toList());

  @override
  Future<void> setPreferences({
    required String camperId,
    required Iterable<String> requestedActivityIds,
    required Iterable<String> vetoedActivityIds,
  }) async {
    preferenceCalls.add((camperId: camperId, requests: requestedActivityIds.toList(), vetoes: vetoedActivityIds.toList()));
  }
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
