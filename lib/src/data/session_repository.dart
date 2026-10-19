import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/errors.dart';
import '../models/activity.dart';
import '../models/cabin.dart';
import '../models/row_codec.dart';
import '../models/schedule.dart';
import '../models/camp_session.dart';

/// The structure of one session: its cabins and its schedule.
class SessionRepository {
  SessionRepository(this._client);

  final SupabaseClient _client;

  Future<CampSession> fetchSession(String sessionId) => guarded(() async {
    final row = await _client.from('sessions').select().eq('id', sessionId).single();
    return CampSession.fromRow(row);
  });

  /// Creates a session with its schedule days, the branch's template blocks
  /// and (optionally) every cabin in the branch.
  Future<CampSession> createSession({
    required String seasonId,
    required String name,
    required DateTime startsOn,
    int maxRequests = 3,
    int maxVetoes = 2,
    int maxSkillsRequests = 2,
    int maxSkillsVetoes = 1,
    bool registerAllCabins = true,
  }) => guarded(() async {
    final row = await _client.rpc('create_session', params: {
      'p_season_id': seasonId,
      'p_name': name,
      'p_starts_on': formatDbDate(startsOn),
      'p_max_requests': maxRequests,
      'p_max_vetoes': maxVetoes,
      'p_max_skills_requests': maxSkillsRequests,
      'p_max_skills_vetoes': maxSkillsVetoes,
      'p_register_all_cabins': registerAllCabins,
    });
    return CampSession.fromRow(row as Map<String, dynamic>);
  });

  Future<void> updateLimits(String sessionId, PreferenceLimits limits) => guarded(() async {
    await _client.from('sessions').update({
      'max_requests': limits.maxRequests,
      'max_vetoes': limits.maxVetoes,
      'max_skills_requests': limits.maxSkillsRequests,
      'max_skills_vetoes': limits.maxSkillsVetoes,
    }).eq('id', sessionId);
  });

  // Schedule ------------------------------------------------------------------

  Future<Schedule> fetchSchedule(String sessionId) => guarded(() async {
    final results = await Future.wait([
      _client.from('schedule_days').select().eq('session_id', sessionId),
      _client.from('blocks').select().eq('session_id', sessionId),
      _client.from('scheduled_activities').select('*, activities(*)').eq('session_id', sessionId),
    ]);

    final days = results[0].map(ScheduleDay.fromRow).toList();
    final daysById = {for (final d in days) d.id: d};
    final blocks = results[1].map((row) => Block.fromRow(row, daysById[row['day_id']]!)).toList();

    final scheduled = <ScheduledActivity>[];
    final activities = <String, Activity>{};
    for (final row in results[2]) {
      scheduled.add(ScheduledActivity.fromRow(row));
      final activity = Activity.fromRow(row['activities'] as Map<String, dynamic>);
      activities[activity.id] = activity;
    }

    return Schedule(days: days, blocks: blocks, scheduledActivities: scheduled, activitiesById: activities);
  });

  Future<Block> addBlock({
    required String sessionId,
    required String dayId,
    required String title,
    required Duration startTime,
    required Duration endTime,
    bool isSkillsRec = false,
  }) => guarded(() async {
    final row = await _client
        .from('blocks')
        .insert({
          'session_id': sessionId,
          'day_id': dayId,
          'title': title,
          'start_time': formatDbTime(startTime),
          'end_time': formatDbTime(endTime),
          'is_skills_rec': isSkillsRec,
        })
        .select()
        .single();
    final day = await _client.from('schedule_days').select().eq('id', dayId).single();
    return Block.fromRow(row, ScheduleDay.fromRow(day));
  });

  Future<void> deleteBlock(String blockId) => guarded(() async {
    ensureAffected(await _client.from('blocks').delete().eq('id', blockId).select('id'), 1);
  });

  /// Offers [activityIds] during [blockId]; activities already offered are left alone.
  Future<void> scheduleActivities({
    required String sessionId,
    required String blockId,
    required Iterable<String> activityIds,
  }) => guarded(() async {
    final rows = [
      for (final id in activityIds) {'session_id': sessionId, 'block_id': blockId, 'activity_id': id},
    ];
    if (rows.isEmpty) return;
    await _client.from('scheduled_activities').upsert(rows, onConflict: 'block_id,activity_id', ignoreDuplicates: true);
  });

  /// Stops offering activities. Campers assigned to them lose just that assignment.
  Future<void> unscheduleActivities(Iterable<String> scheduledActivityIds) => guarded(() async {
    final ids = scheduledActivityIds.toList();
    if (ids.isEmpty) return;
    ensureAffected(await _client.from('scheduled_activities').delete().inFilter('id', ids).select('id'), ids.length);
  });

  // Cabins --------------------------------------------------------------------

  Future<List<Cabin>> listSessionCabins(String sessionId) => guarded(() async {
    final rows = await _client.from('session_cabins').select('cabins(*)').eq('session_id', sessionId);
    final cabins = rows.map((row) => Cabin.fromRow(row['cabins'] as Map<String, dynamic>)).toList();
    cabins.sort((a, b) => a.position != b.position ? a.position.compareTo(b.position) : a.name.compareTo(b.name));
    return cabins;
  });

  /// Makes the session's cabins exactly [cabinIds]. Campers in a removed cabin
  /// stay on the roster without a cabin.
  Future<void> setSessionCabins(String sessionId, Iterable<String> cabinIds) => guarded(() async {
    await _client.rpc('register_session_cabins', params: {'p_session_id': sessionId, 'p_cabin_ids': cabinIds.toList()});
  });
}
