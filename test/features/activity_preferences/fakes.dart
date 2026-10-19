import 'dart:async';

import 'package:bessie/src/core/errors.dart';
import 'package:bessie/src/data/roster_repository.dart';
import 'package:bessie/src/data/session_repository.dart';
import 'package:bessie/src/models/cabin.dart';
import 'package:bessie/src/models/camper.dart';
import 'package:bessie/src/models/schedule.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A save as the roster repository received it.
class SavedPreferences {
  SavedPreferences(this.camperId, this.requested, this.vetoed, this.gate);

  final String camperId;
  final Set<String> requested;
  final Set<String> vetoed;

  /// Complete it to let the save finish; complete with an error to fail it.
  final Completer<void> gate;
}

class FakeRosterRepository extends RosterRepository {
  FakeRosterRepository(super.client);

  List<Camper> campers = [];
  final updates = StreamController<List<Camper>>.broadcast(sync: true);
  final saves = <SavedPreferences>[];
  final watched = <String>[];

  /// When true, saves finish by themselves; otherwise the test completes each gate.
  bool autoComplete = true;

  /// Campers whose saves are refused, with the error thrown for them.
  final failing = <String, Object>{};

  @override
  Stream<List<Camper>> watchCampers(String sessionId) {
    watched.add(sessionId);
    return Stream.multi((controller) {
      controller.add(campers);
      final subscription = updates.stream.listen(controller.add);
      controller.onCancel = subscription.cancel;
    });
  }

  @override
  Future<void> setPreferences({
    required String camperId,
    required Iterable<String> requestedActivityIds,
    required Iterable<String> vetoedActivityIds,
  }) async {
    final save = SavedPreferences(camperId, requestedActivityIds.toSet(), vetoedActivityIds.toSet(), Completer<void>());
    saves.add(save);
    final refusal = failing[camperId];
    if (refusal != null) throw refusal;
    if (autoComplete) save.gate.complete();
    await save.gate.future;
  }

  Future<void> emit(List<Camper> next) async {
    campers = next;
    updates.add(next);
    await pumpEventQueue();
  }
}

class FakeSessionRepository extends SessionRepository {
  FakeSessionRepository(super.client, {required this.cabins, required this.schedule});

  final List<Cabin> cabins;
  Schedule schedule;
  final scheduleRequests = <String>[];

  /// When set, reads fail with this (as the data layer would report it).
  Object? failWith;

  @override
  Future<List<Cabin>> listSessionCabins(String sessionId) async {
    if (failWith != null) throw AppException.from(failWith!);
    return cabins;
  }

  @override
  Future<Schedule> fetchSchedule(String sessionId) async {
    scheduleRequests.add(sessionId);
    if (failWith != null) throw AppException.from(failWith!);
    return schedule;
  }
}

/// A client that is never used: the repositories under test are fakes.
SupabaseClient newClient() =>
    SupabaseClient('http://127.0.0.1:1', 'anon', authOptions: const AuthClientOptions(autoRefreshToken: false));
