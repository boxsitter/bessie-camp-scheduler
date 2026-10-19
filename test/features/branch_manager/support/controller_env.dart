import 'package:bessie/src/data/auth_repository.dart';
import 'package:bessie/src/data/catalog_repository.dart';
import 'package:bessie/src/data/profile_repository.dart';
import 'package:bessie/src/data/roster_repository.dart';
import 'package:bessie/src/data/session_repository.dart';
import 'package:bessie/src/models/camp_session.dart';
import 'package:bessie/src/services/auth_service.dart';
import 'package:bessie/src/services/context_service.dart';
import 'package:bessie/src/shared/services/popup_service.dart';
import 'package:collection/collection.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../support/local_supabase.dart';

/// Answers confirmations without showing them, and remembers what was asked.
class FakePopupService extends PopupService {
  bool answer = true;
  final List<({String? title, String? message})> confirmations = [];

  @override
  Future<bool> showConfirmationDialog({String? title, String? message}) async {
    confirmations.add((title: title, message: message));
    return answer;
  }
}

/// The real services wired to the local Supabase stack as one of the demo
/// accounts, the way the app wires them after sign-in, plus clean-up of
/// everything a test creates (names start with [prefix]).
class ControllerEnv {
  ControllerEnv._(
    this.client,
    this.auth,
    this.context,
    this.catalog,
    this.sessions,
    this.roster,
    this.profiles,
    this.popups,
    this._originalPreferences,
  );

  static const prefix = 'zz test';

  final SupabaseClient client;
  final AuthService auth;
  final ContextService context;
  final CatalogRepository catalog;
  final SessionRepository sessions;
  final RosterRepository roster;
  final ProfileRepository profiles;
  final FakePopupService popups;
  final Map<String, dynamic> _originalPreferences;

  /// One signed-in client per account for the whole test file: the auth
  /// server limits sign-ins (and every test needs one).
  static final Map<String, SupabaseClient> _clients = {};

  /// Signs the accounts out; call from `tearDownAll`.
  static Future<void> closeClients() async {
    for (final client in _clients.values) {
      await client.dispose();
    }
    _clients.clear();
  }

  static Future<ControllerEnv> open(String email) async {
    Get.reset();
    final client = _clients[email] ??= await signedInClient(email);
    final profiles = Get.put(ProfileRepository(client));
    final catalog = Get.put(CatalogRepository(client));
    final sessions = Get.put(SessionRepository(client));
    final roster = Get.put(RosterRepository(client));
    final auth = await Get.put(AuthService(AuthRepository(client), profiles)).init();
    final context = Get.put(ContextService(catalog, profiles, auth));
    final popups = FakePopupService();
    Get.put<PopupService>(popups);
    await context.load();
    return ControllerEnv._(client, auth, context, catalog, sessions, roster, profiles, popups, Map.of(auth.currentProfile.preferences));
  }

  static String uniqueName([String label = '']) => '$prefix $label ${DateTime.now().microsecondsSinceEpoch}'.replaceAll('  ', ' ');

  /// A throwaway session (with the weekly blocks and every cabin) that becomes
  /// the current one without being remembered as the user's last session.
  Future<CampSession> createTestSession() async {
    final created = await sessions.createSession(seasonId: context.seasonId, name: uniqueName('session'), startsOn: DateTime(2031, 6, 2));
    await context.refreshSessions();
    context.session.value = context.sessions.firstWhere((s) => s.id == created.id);
    return created;
  }

  /// Removes everything the test created and restores the account's settings.
  Future<void> dispose() async {
    await client.from('sessions').delete().like('name', '$prefix%');
    await client.from('activities').delete().like('name', '$prefix%');
    await client.from('cabins').delete().like('name', '$prefix%');
    if (auth.profile.value != null && !const MapEquality<String, dynamic>().equals(auth.currentProfile.preferences, _originalPreferences)) {
      await profiles.updatePreferences(_originalPreferences, const {});
      // The merge above rewrites the stored map to exactly the original.
    }
    Get.reset();
  }
}
