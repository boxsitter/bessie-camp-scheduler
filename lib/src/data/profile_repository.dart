import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/errors.dart';
import '../models/staff_profile.dart';

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  /// The signed-in user's profile, or null if they have none (not staff) or
  /// have been deactivated.
  Future<StaffProfile?> fetchMine() => guarded(() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    final row = await _client.from('profiles').select().eq('id', userId).maybeSingle();
    if (row == null) return null;
    final profile = StaffProfile.fromRow(row);
    return profile.active ? profile : null;
  });

  Future<List<StaffProfile>> listColleagues() => guarded(() async {
    final rows = await _client.from('profiles').select().order('last_name');
    return rows.map(StaffProfile.fromRow).toList();
  });

  /// Merges [changes] into the signed-in user's stored UI preferences.
  Future<void> updatePreferences(Map<String, dynamic> current, Map<String, dynamic> changes) => guarded(() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client.from('profiles').update({'preferences': {...current, ...changes}}).eq('id', userId);
  });
}
