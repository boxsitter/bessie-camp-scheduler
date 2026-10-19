import '../cli/cli.dart';
import '../data/catalog_repository.dart';
import '../data/roster_repository.dart';
import '../data/session_repository.dart';
import '../services/auth_service.dart';
import '../services/backup_service.dart';
import '../services/context_service.dart';
import '../services/file_service.dart';
import 'assignment_commands.dart';
import 'context_commands.dart';
import 'session_commands.dart';

/// Indexes [commands] by name and by every alias.
Map<String, EmberCommand> commandRegistry(Iterable<EmberCommand> commands) => {
  for (final command in commands) ...{command.name: command, for (final alias in command.aliases) alias: command},
};

/// The console's command set.
class CoreCommands {
  const CoreCommands._();

  /// Builds every command, wired to [input]/[output] and the services it needs.
  static Map<String, EmberCommand> build({
    required UserInput input,
    required UserOutput output,
    required void Function() clearScreen,
    required AuthService auth,
    required ContextService context,
    required CatalogRepository catalog,
    required SessionRepository sessions,
    required RosterRepository roster,
    required BackupService backup,
    required FileService files,
  }) {
    final registry = commandRegistry([
      ViewContext(userInput: input, userOutput: output, context: context),
      WhoAmI(userInput: input, userOutput: output, auth: auth, context: context),
      ListBranches(userInput: input, userOutput: output, context: context, catalog: catalog),
      ListSeasons(userInput: input, userOutput: output, context: context, catalog: catalog),
      ListSessions(userInput: input, userOutput: output, context: context),
      SwitchSession(userInput: input, userOutput: output, context: context),
      MakeSession(userInput: input, userOutput: output, context: context, sessions: sessions),
      AddActivities(userInput: input, userOutput: output, context: context, sessions: sessions, catalog: catalog),
      RemoveActivities(userInput: input, userOutput: output, context: context, sessions: sessions),
      BackupActivityAssignments(
        userInput: input,
        userOutput: output,
        context: context,
        sessions: sessions,
        roster: roster,
        backup: backup,
        files: files,
      ),
      ResetActivityAssignments(userInput: input, userOutput: output, context: context, roster: roster),
      ClearScreen(userInput: input, userOutput: output, clearScreen: clearScreen),
    ]);
    // Help describes the registry it lives in, so it is added last.
    registry['help'] = HelpCommand(userInput: input, userOutput: output, registry: registry);
    return registry;
  }
}

/// `clear`: wipe the terminal.
class ClearScreen extends EmberCommand<void> {
  ClearScreen({required super.userInput, required super.userOutput, required void Function() clearScreen}) : _clearScreen = clearScreen;

  final void Function() _clearScreen;

  @override
  final String name = 'clear';
  @override
  final String description = 'Clears the screen.';

  @override
  void run() => _clearScreen();
}

/// `help`: list the commands, or explain one.
class HelpCommand extends EmberCommand<void> {
  HelpCommand({required super.userInput, required super.userOutput, required Map<String, EmberCommand> registry}) : _registry = registry;

  final Map<String, EmberCommand> _registry;

  @override
  final String name = 'help';
  @override
  final String description = 'Lists the commands, or explains one of them.';
  @override
  String get positionalSyntax => '[command]';
  @override
  int get maxPositionalArguments => 1;
  @override
  List<String> get examples => const ['help', 'help mksesh'];

  @override
  void run() {
    final wanted = argResults.rest.firstOrNull;
    if (wanted != null) {
      final command = _registry[wanted];
      if (command == null) {
        userOutput.error('There is no command called "$wanted". Type help to list them.');
        return;
      }
      userOutput.log(command.usage);
      return;
    }

    final commands = _registry.values.toSet().toList()..sort((a, b) => a.name.compareTo(b.name));
    userOutput.printTable(
      [
        for (final command in commands) [command.name, command.aliases.join(', '), command.summary],
      ],
      headers: ['Command', 'Also', 'What it does'],
    );
    userOutput.printDim('Type "help <command>" for details, or "<command> --help".');
  }
}
