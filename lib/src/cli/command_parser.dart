// Required for FutureOr if EmberCommand uses it.

// Assuming EmberCommand is defined in a path accessible like this.
// You might need to adjust the import path based on your project structure.
// From your uploaded ember_command.dart, it seems it's part of 'ember_cli_utils'.
import 'package:bessie/src/cli/cli.dart';

/// A class to hold the result of parsing a command string.
class ParsedCommandResult<T> {
  final EmberCommand<T>? command;
  final List<String> arguments; // For now, will be empty
  final Map<String, dynamic> flagsAndOptions; // For now, will be empty
  String? errorMessage; // Mutable to allow setting it on error

  ParsedCommandResult({
    this.command,
    List<String>? arguments,
    Map<String, dynamic>? flagsAndOptions,
    this.errorMessage,
  })  : arguments = arguments ?? [],
        flagsAndOptions = flagsAndOptions ?? {};
}

/// A utility class for parsing raw command strings.
class CommandParser {
  /// Parses a raw command string to identify the command, arguments, and options.
  ///
  /// Args:
  ///   [rawInput]: The raw string input from the user.
  ///   [availableCommands]: A map of command names to their corresponding EmberCommand instances.
  ///   [currentErrorMessage]: A reference to a string that can be updated with an error message.
  ///                          This approach is a bit unusual; typically, the method would return
  ///                          an error or throw an exception. Using a mutable updatable string
  ///                          as an output parameter for errors as requested.
  ///   [initialArgs]: An empty list, as per requirements (to be populated later).
  ///   [initialFlagsAndOptions]: An empty map, as per requirements (to be populated later).
  ///
  /// Returns:
  ///   A [ParsedCommandResult] containing the identified command and placeholders for
  ///   arguments and flags/options. If parsing fails (e.g., invalid format, unknown command),
  ///   the `command` field in the result will be null, and `currentErrorMessage` will be set.
  static ParsedCommandResult parseCommand(
      String rawInput, {
        required Map<String, EmberCommand> availableCommands,
        required Function(String) setErrorMessage, // Callback to set error message
        required List<String> initialArgs, // Will be returned as is, for now
        required Map<String, dynamic>
        initialFlagsAndOptions, // Will be returned as is, for now
      }) {
    final trimmedInput = rawInput.trim();
    if (trimmedInput.isEmpty) {
      setErrorMessage('Error: No command entered.');
      return ParsedCommandResult(
        arguments: initialArgs,
        flagsAndOptions: initialFlagsAndOptions,
        errorMessage: 'Error: No command entered.',
      );
    }

    // For now, we only expect a single word for the command name.
    // No argument or option parsing is implemented yet.
    final parts = trimmedInput.split(' ');
    final commandName = parts.first;

    // TODO: Implement parsing for arguments, flags, and options from `parts.sublist(1)`.
    // For now, args, flags, and options are returned empty as per requirements.
    final List<String> arguments = List.from(initialArgs); // Use a copy
    final Map<String, dynamic> flagsAndOptions =
    Map.from(initialFlagsAndOptions); // Use a copy

    if (parts.length > 1) {
      // User entered more than just the command name.
      // For now, we are not parsing args/options/flags.
      // Depending on future requirements, this could be an error or parts[0]
      // could be the command and the rest are unparsed.
      // As per "command correct format (a single word)", we'll treat additional parts
      // as an error *for now* if we're strict about "single word" meaning only the command.
      // However, typical CLIs have command followed by args.
      // Let's assume for this phase, only the first word is the command.
      // The TODO above will handle parts.sublist(1).
    }

    if (commandName.contains(RegExp(r'\s'))) {
      // This check is technically redundant if parts.first is used after splitting by space.
      // However, if the input itself was just "cmd name" (with a space in the command itself),
      // this would be an invalid command name format.
      setErrorMessage('Error: Command name should be a single word.');
      return ParsedCommandResult(
        arguments: arguments,
        flagsAndOptions: flagsAndOptions,
        errorMessage: 'Error: Command name should be a single word.',
      );
    }

    final matchedCommand = availableCommands[commandName];

    if (matchedCommand == null) {
      setErrorMessage('Error: Unknown command "$commandName".');
      return ParsedCommandResult(
        arguments: arguments,
        flagsAndOptions: flagsAndOptions,
        errorMessage: 'Error: Unknown command "$commandName".',
      );
    }

    // If everything is fine, return the command.
    // Error message remains null (or its initial state).
    return ParsedCommandResult(
      command: matchedCommand,
      arguments: arguments, // Empty for now
      flagsAndOptions: flagsAndOptions, // Empty for now
    );
  }
}