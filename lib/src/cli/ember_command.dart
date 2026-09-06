import 'dart:async';

import 'package:args/command_runner.dart';

import 'io/io_interfaces.dart';
export 'package:args/src/arg_parser.dart';
export 'package:args/src/arg_results.dart';

/// Abstract base class for all CLI commands.
/// It extends `Command` from `package:args` to leverage its argument parsing
/// and command-running capabilities.
abstract class EmberCommand<T> extends Command<T> {
  /// The name of the command.
  @override
  String get name;

  /// A description of the command that is short and to the point.
  @override
  String get description;

  /// (Optional) A longer, more detailed description of the command.
  /// Used by the help command.
  String get invocationDetails => invocation;

  /// (Optional) Example usages of the command.
  List<String> get examples => [];

  final UserInput userInput;
  final UserOutput userOutput;

  EmberCommand({required this.userInput, required this.userOutput}) {
    // Common arguments for all commands could be added here if needed
    // argParser.addFlag('verbose', abbr: 'v', help: 'Enable verbose logging.', negatable: false);
  }

  // Subclasses will override run() to implement their specific logic.
  @override
  FutureOr<T> run();
}