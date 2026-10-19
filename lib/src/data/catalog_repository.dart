import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/errors.dart';
import '../models/activity.dart';
import '../models/cabin.dart';
import '../models/organization.dart';
import '../models/camp_session.dart';

/// The organization hierarchy and a branch's catalog of activities and cabins.
class CatalogRepository {
  CatalogRepository(this._client);

  final SupabaseClient _client;

  // Structure -----------------------------------------------------------------

  Future<Organization?> fetchOrganization() => guarded(() async {
    final row = await _client.from('organizations').select().limit(1).maybeSingle();
    return row == null ? null : Organization.fromRow(row);
  });

  Future<List<Branch>> listBranches() => guarded(() async {
    final rows = await _client.from('branches').select().order('name');
    return rows.map(Branch.fromRow).toList();
  });

  Future<List<Season>> listSeasons(String branchId) => guarded(() async {
    final rows = await _client.from('seasons').select().eq('branch_id', branchId).order('starts_on', ascending: false);
    return rows.map(Season.fromRow).toList();
  });

  Future<List<CampSession>> listSessions(String seasonId) => guarded(() async {
    final rows = await _client.from('sessions').select().eq('season_id', seasonId).order('starts_on');
    return rows.map(CampSession.fromRow).toList();
  });

  // Activities ----------------------------------------------------------------

  Future<List<Activity>> listActivities(String branchId) => guarded(() async {
    final rows = await _client.from('activities').select().eq('branch_id', branchId).order('name');
    return rows.map(Activity.fromRow).toList();
  });

  Future<Activity> createActivity(Activity activity) => guarded(() async {
    final row = await _client.from('activities').insert(activity.toInsertRow()).select().single();
    return Activity.fromRow(row);
  });

  Future<Activity> updateActivity(Activity activity) => guarded(() async {
    final row = await _client.from('activities').update(activity.toInsertRow()).eq('id', activity.id).select().single();
    return Activity.fromRow(row);
  });

  /// Fails if the activity is still scheduled somewhere.
  Future<void> deleteActivity(String id) => guarded(() async {
    ensureAffected(await _client.from('activities').delete().eq('id', id).select('id'), 1);
  });

  // Cabins --------------------------------------------------------------------

  Future<List<Cabin>> listCabins(String branchId) => guarded(() async {
    final rows = await _client.from('cabins').select().eq('branch_id', branchId).order('position').order('name');
    return rows.map(Cabin.fromRow).toList();
  });

  Future<Cabin> createCabin({
    required String branchId,
    required String name,
    String? displayName,
    String village = '',
    required int capacity,
    int position = 0,
  }) => guarded(() async {
    final row = await _client
        .from('cabins')
        .insert({
          'branch_id': branchId,
          'name': name,
          'display_name': displayName,
          'village': village,
          'capacity': capacity,
          'position': position,
        })
        .select()
        .single();
    return Cabin.fromRow(row);
  });

  Future<Cabin> updateCabin(Cabin cabin) => guarded(() async {
    final row = await _client
        .from('cabins')
        .update({
          'name': cabin.name,
          'display_name': cabin.displayName,
          'village': cabin.village,
          'capacity': cabin.capacity,
          'position': cabin.position,
        })
        .eq('id', cabin.id)
        .select()
        .single();
    return Cabin.fromRow(row);
  });

  Future<void> deleteCabin(String id) => guarded(() async {
    ensureAffected(await _client.from('cabins').delete().eq('id', id).select('id'), 1);
  });
}
