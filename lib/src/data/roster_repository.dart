import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/errors.dart';
import '../core/logging.dart';
import '../models/camper.dart';

/// A new assignment produced by an auto-assignment run.
class NewAssignment {
  const NewAssignment({required this.camperId, required this.scheduledActivityId});

  final String camperId;
  final String scheduledActivityId;

  Map<String, dynamic> toJson() => {'camper_id': camperId, 'scheduled_activity_id': scheduledActivityId};
}

/// Campers, their cabins, preferences and activity assignments.
class RosterRepository {
  RosterRepository(this._client);

  final SupabaseClient _client;

  static const _camperSelect = '*, assignments(block_id, scheduled_activity_id), camper_preferences(activity_id, kind)';

  // Reading -------------------------------------------------------------------

  Future<List<Camper>> fetchCampers(String sessionId) => guarded(() async {
    final rows = await _client.from('campers').select(_camperSelect).eq('session_id', sessionId).order('last_name').order('first_name');
    return rows.map(Camper.fromRow).toList();
  });

  /// The session's campers, kept current: emits the roster immediately and
  /// again whenever a camper, assignment or preference changes (from anyone).
  Stream<List<Camper>> watchCampers(String sessionId) {
    late final StreamController<List<Camper>> controller;
    RealtimeChannel? channel;
    Timer? debounce;
    var refreshing = false;
    var refreshAgain = false;

    Future<void> refresh() async {
      if (controller.isClosed) return;
      if (refreshing) {
        refreshAgain = true;
        return;
      }
      refreshing = true;
      try {
        do {
          refreshAgain = false;
          final campers = await fetchCampers(sessionId);
          if (!controller.isClosed) controller.add(campers);
        } while (refreshAgain);
      } catch (e, st) {
        log.w('Failed to refresh roster', error: e, stackTrace: st);
        if (!controller.isClosed) controller.addError(e, st);
      } finally {
        refreshing = false;
      }
    }

    void scheduleRefresh() {
      debounce?.cancel();
      debounce = Timer(const Duration(milliseconds: 150), refresh);
    }

    controller = StreamController<List<Camper>>(
      onListen: () {
        final filter = PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'session_id', value: sessionId);
        var ch = _client.channel('roster:$sessionId:${DateTime.now().microsecondsSinceEpoch}');
        for (final table in const ['campers', 'assignments', 'camper_preferences']) {
          ch = ch.onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: table,
            filter: filter,
            callback: (_) => scheduleRefresh(),
          );
        }
        // Fetch right away so the roster shows even if realtime is blocked, and
        // again once the channel has joined (and after any reconnect) so no
        // change can slip between the first fetch and the join.
        refresh();
        channel = ch.subscribe((status, error) {
          switch (status) {
            case RealtimeSubscribeStatus.subscribed:
              refresh();
            case RealtimeSubscribeStatus.channelError:
            case RealtimeSubscribeStatus.timedOut:
              log.w('Roster realtime channel $status', error: error);
            case RealtimeSubscribeStatus.closed:
              break;
          }
        });
      },
      onCancel: () async {
        debounce?.cancel();
        final ch = channel;
        if (ch != null) await _client.removeChannel(ch);
      },
    );
    return controller.stream;
  }

  // Campers -------------------------------------------------------------------

  Future<CamperImportResult> importCampers(String sessionId, List<CamperImportRow> rows) => guarded(() async {
    final result = await _client.rpc('import_campers', params: {
      'p_session_id': sessionId,
      'p_rows': rows.map((r) => r.toJson()).toList(),
    });
    return CamperImportResult.fromJson(result as Map<String, dynamic>);
  });

  Future<void> setArrived(Iterable<String> camperIds, bool arrived) => guarded(() async {
    final ids = camperIds.toList();
    ensureAffected(await _client.from('campers').update({'arrived': arrived}).inFilter('id', ids).select('id'), ids.length);
  });

  Future<void> setCanSwim(Iterable<String> camperIds, bool canSwim) => guarded(() async {
    final ids = camperIds.toList();
    ensureAffected(await _client.from('campers').update({'can_swim': canSwim}).inFilter('id', ids).select('id'), ids.length);
  });

  /// Moves campers into [cabinId], or out of any cabin when it is null.
  Future<void> setCabin(Iterable<String> camperIds, String? cabinId) => guarded(() async {
    final ids = camperIds.toList();
    ensureAffected(await _client.from('campers').update({'cabin_id': cabinId}).inFilter('id', ids).select('id'), ids.length);
  });

  /// Sends each camper to the other cabin; the selection must span exactly two.
  Future<void> swapCabins(Iterable<String> camperIds) => guarded(() async {
    await _client.rpc('swap_camper_cabins', params: {'p_camper_ids': camperIds.toList()});
  });

  Future<void> deleteCampers(Iterable<String> camperIds) => guarded(() async {
    final ids = camperIds.toList();
    ensureAffected(await _client.from('campers').delete().inFilter('id', ids).select('id'), ids.length);
  });

  // Preferences ---------------------------------------------------------------

  /// Replaces a camper's requests and vetoes. The database enforces the
  /// session's limits.
  Future<void> setPreferences({
    required String camperId,
    required Iterable<String> requestedActivityIds,
    required Iterable<String> vetoedActivityIds,
  }) => guarded(() async {
    await _client.rpc('set_camper_preferences', params: {
      'p_camper_id': camperId,
      'p_requests': requestedActivityIds.toList(),
      'p_vetoes': vetoedActivityIds.toList(),
    });
  });

  Future<void> clearPreferences(Iterable<String> camperIds) => guarded(() async {
    await _client.rpc('clear_camper_preferences', params: {'p_camper_ids': camperIds.toList()});
  });

  // Assignments ---------------------------------------------------------------

  /// Puts campers into a scheduled activity, moving them if they are already
  /// in another activity that block. Returns how many assignments changed.
  Future<int> assignCampers(
    Iterable<String> camperIds,
    String scheduledActivityId, {
    bool replaceExisting = true,
    bool enforceCapacity = false,
  }) => guarded(() async {
    final changed = await _client.rpc('assign_campers', params: {
      'p_camper_ids': camperIds.toList(),
      'p_scheduled_activity_id': scheduledActivityId,
      'p_replace_existing': replaceExisting,
      'p_enforce_capacity': enforceCapacity,
    });
    return changed as int;
  });

  /// Removes assignments: from one scheduled activity, from one block, or
  /// (with neither filter) from everything. Returns how many were removed.
  Future<int> unassignCampers(Iterable<String> camperIds, {String? blockId, String? scheduledActivityId}) => guarded(() async {
    final removed = await _client.rpc('unassign_campers', params: {
      'p_camper_ids': camperIds.toList(),
      'p_block_id': blockId,
      'p_scheduled_activity_id': scheduledActivityId,
    });
    return removed as int;
  });

  /// Stores an auto-assignment run atomically. Campers who already have an
  /// assignment for a block keep it. Returns how many assignments were added.
  Future<int> applyAssignments({
    required String sessionId,
    required List<NewAssignment> assignments,
    Map<String, double> satisfaction = const {},
  }) => guarded(() async {
    final inserted = await _client.rpc('apply_assignments', params: {
      'p_session_id': sessionId,
      'p_assignments': assignments.map((a) => a.toJson()).toList(),
      'p_satisfaction': [
        for (final e in satisfaction.entries) {'camper_id': e.key, 'score': e.value},
      ],
    });
    return inserted as int;
  });

  Future<void> resetAssignments(String sessionId, {bool clearPreferences = false}) => guarded(() async {
    await _client.rpc('reset_session_assignments', params: {'p_session_id': sessionId, 'p_clear_preferences': clearPreferences});
  });
}
