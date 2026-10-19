import 'package:collection/collection.dart';

import '../cli/cli.dart';
import '../data/catalog_repository.dart';
import '../models/camp_session.dart';
import '../models/row_codec.dart';
import '../services/auth_service.dart';
import '../services/context_service.dart';

/// `con`: where the user is working right now.
class ViewContext extends EmberCommand<void> {
  ViewContext({required super.userInput, required super.userOutput, required ContextService context}) : _context = context;

  final ContextService _context;

  @override
  final String name = 'con';
  @override
  final String description = 'Shows the organization, branch, season and session you are working in.';

  @override
  void run() {
    final season = _context.season.value;
    final session = _context.session.value;
    userOutput
      ..printProperty('Organization', _context.organization.value?.name ?? 'none')
      ..printProperty('Branch', _context.branch.value?.name ?? 'none')
      ..printProperty('Season', season == null ? 'none' : '${season.name} (${formatDbDate(season.startsOn)} to ${formatDbDate(season.endsOn)})')
      ..printProperty('Session', session == null ? 'none' : '${session.name} (starts ${formatDbDate(session.startsOn)})');
  }
}

/// `whoami`: the signed-in account.
class WhoAmI extends EmberCommand<void> {
  WhoAmI({required super.userInput, required super.userOutput, required AuthService auth, required ContextService context})
    : _auth = auth,
      _context = context;

  final AuthService _auth;
  final ContextService _context;

  @override
  final String name = 'whoami';
  @override
  final String description = 'Shows who you are signed in as.';

  @override
  void run() {
    final profile = _auth.profile.value;
    if (profile == null) {
      userOutput.error('Nobody is signed in.');
      return;
    }
    userOutput
      ..printProperty('Name', profile.fullName)
      ..printProperty('Role', profile.role.title)
      ..printProperty('Organization', _context.organization.value?.name ?? 'unknown');
  }
}

/// `brns`: the branches of the organization.
class ListBranches extends EmberCommand<void> {
  ListBranches({required super.userInput, required super.userOutput, required ContextService context, required CatalogRepository catalog})
    : _context = context,
      _catalog = catalog;

  final ContextService _context;
  final CatalogRepository _catalog;

  @override
  final String name = 'brns';
  @override
  final String description = 'Lists the branches of your organization.';

  @override
  Future<void> run() async {
    final branches = await _catalog.listBranches();
    final currentId = _context.branch.value?.id;
    userOutput.printTable([
      for (final branch in branches) [branch.name, branch.id == currentId ? 'yes' : ''],
    ], headers: ['Branch', 'Current']);
  }
}

/// `seas`: the seasons of the current branch.
class ListSeasons extends EmberCommand<void> {
  ListSeasons({required super.userInput, required super.userOutput, required ContextService context, required CatalogRepository catalog})
    : _context = context,
      _catalog = catalog;

  final ContextService _context;
  final CatalogRepository _catalog;

  @override
  final String name = 'seas';
  @override
  final String description = 'Lists the seasons of the current branch.';

  @override
  Future<void> run() async {
    final seasons = await _catalog.listSeasons(_context.branchId);
    final currentId = _context.season.value?.id;
    userOutput.printTable([
      for (final season in seasons) [season.name, formatDbDate(season.startsOn), formatDbDate(season.endsOn), season.id == currentId ? 'yes' : ''],
    ], headers: ['Season', 'Starts', 'Ends', 'Current']);
  }
}

/// `sess`: the sessions of the current season.
class ListSessions extends EmberCommand<void> {
  ListSessions({required super.userInput, required super.userOutput, required ContextService context}) : _context = context;

  final ContextService _context;

  @override
  final String name = 'sess';
  @override
  final String description = 'Lists the sessions of the current season.';

  @override
  void run() {
    final sessions = _context.sessions;
    if (sessions.isEmpty) {
      userOutput.info('This season has no sessions yet. Create one with mksesh.');
      return;
    }
    final currentId = _context.session.value?.id;
    userOutput.printTable([
      for (final session in sessions) [session.name, formatDbDate(session.startsOn), session.id == currentId ? 'yes' : ''],
    ], headers: ['Session', 'Starts', 'Current']);
  }
}

/// `sw`: switch to another session of the season.
class SwitchSession extends EmberCommand<void> {
  SwitchSession({required super.userInput, required super.userOutput, required ContextService context}) : _context = context;

  final ContextService _context;

  @override
  final String name = 'sw';
  @override
  List<String> get aliases => const ['migcon'];
  @override
  final String description = 'Switches to another session of the season. Pick from a list, or give its name.';
  @override
  String get positionalSyntax => '[session name]';
  @override
  int get maxPositionalArguments => 1;
  @override
  List<String> get examples => const ['sw', 'sw "Session 2"'];

  @override
  Future<void> run() async {
    final sessions = _context.sessions.toList();
    if (sessions.isEmpty) {
      userOutput.error('This season has no sessions yet. Create one with mksesh.');
      return;
    }

    final CampSession target;
    final wanted = argResults.rest.firstOrNull;
    if (wanted != null) {
      final match = sessions.firstWhereOrNull((s) => s.name.toLowerCase() == wanted.toLowerCase());
      if (match == null) {
        userOutput.error('There is no session called "$wanted". Use sess to see them.');
        return;
      }
      target = match;
    } else {
      final answers = await userInput.promptForm('Switch session', [
        SelectFormFieldDescriptor<CampSession>(
          label: 'Session',
          options: sessions,
          optionLabelBuilder: (value) => (value as CampSession).name,
          defaultValue: sessions.firstWhereOrNull((s) => s.id == _context.session.value?.id),
        ),
      ]);
      if (answers == null || answers.first == null) {
        userOutput.info('Cancelled.');
        return;
      }
      target = answers.first as CampSession;
    }

    if (target.id == _context.session.value?.id) {
      userOutput.info('You are already working in ${target.name}.');
      return;
    }
    await _context.switchSession(target.id);
    userOutput.success('Switched to ${target.name}.');
  }
}
