import 'ember_command.dart';

/// What [CommandParser.parseCommand] made of a line typed in the console.
class ParsedCommandResult {
  const ParsedCommandResult({this.command, this.results, this.errorMessage});

  /// The command to run, null when the line could not be understood.
  final EmberCommand? command;

  /// The parsed flags, options and positional arguments for [command].
  final ArgResults? results;

  /// Why the line could not be understood, ready to show to the user.
  final String? errorMessage;

  bool get isError => errorMessage != null;

  /// The positional arguments (everything that is not a flag or an option).
  List<String> get arguments => results?.rest ?? const [];

  /// The flags and options that were given explicitly, by name.
  Map<String, Object?> get flagsAndOptions {
    final parsed = results;
    if (parsed == null) return const {};
    return {
      for (final name in parsed.options)
        if (parsed.wasParsed(name)) name: parsed[name],
    };
  }

  bool get helpRequested => results?['help'] == true;
}

/// Turns a raw line like `mksesh "Session 3" 07/06 --no-select` into a command
/// and its arguments.
class CommandParser {
  const CommandParser._();

  static ParsedCommandResult parseCommand(String rawInput, {required Map<String, EmberCommand> availableCommands}) {
    final List<String> tokens;
    try {
      tokens = tokenize(rawInput);
    } on FormatException catch (e) {
      return ParsedCommandResult(errorMessage: e.message);
    }
    if (tokens.isEmpty) return const ParsedCommandResult(errorMessage: 'No command entered.');

    final name = tokens.first;
    final command = availableCommands[name] ?? availableCommands[name.toLowerCase()];
    if (command == null) {
      return ParsedCommandResult(errorMessage: 'Unknown command "$name". Type help to see what is available.');
    }

    final ArgResults results;
    try {
      results = command.argParser.parse(tokens.skip(1));
    } on FormatException catch (e) {
      return ParsedCommandResult(command: command, errorMessage: '${e.message}. Try "${command.name} --help".');
    }

    if (results.rest.length > command.maxPositionalArguments) {
      final unexpected = results.rest.skip(command.maxPositionalArguments).join(' ');
      return ParsedCommandResult(command: command, errorMessage: 'Unexpected argument "$unexpected". Try "${command.name} --help".');
    }
    return ParsedCommandResult(command: command, results: results);
  }

  /// Splits [input] on whitespace. Single or double quotes keep their content
  /// together (`"Session 3"`), and a backslash escapes the next character.
  ///
  /// Throws a [FormatException] for a quote that is never closed.
  static List<String> tokenize(String input) {
    final tokens = <String>[];
    final current = StringBuffer();
    var inToken = false;
    String? quote;

    void endToken() {
      if (inToken) tokens.add(current.toString());
      current.clear();
      inToken = false;
    }

    final chars = input.split('');
    for (var i = 0; i < chars.length; i++) {
      final char = chars[i];
      if (quote != null) {
        if (char == quote) {
          quote = null;
        } else if (char == r'\' && quote == '"' && i + 1 < chars.length) {
          current.write(chars[++i]);
        } else {
          current.write(char);
        }
      } else if (char == '"' || char == "'") {
        quote = char;
        inToken = true;
      } else if (char == r'\' && i + 1 < chars.length) {
        current.write(chars[++i]);
        inToken = true;
      } else if (char.trim().isEmpty) {
        endToken();
      } else {
        current.write(char);
        inToken = true;
      }
    }
    if (quote != null) throw const FormatException('Missing closing quote');
    endToken();
    return tokens;
  }
}
