import 'dart:async';

import 'package:args/args.dart';

import 'io/io_interfaces.dart';

export 'package:args/args.dart' show ArgParser, ArgResults;

/// Base class of every console command.
///
/// A command is given the [UserInput] and [UserOutput] to talk to the user
/// through (the console, or a fake in tests) and whatever services it needs
/// through its own constructor. Options and flags are declared on
/// [argParser]; positional arguments are limited by [maxPositionalArguments].
abstract class EmberCommand<T> {
  EmberCommand({required this.userInput, required this.userOutput}) {
    argParser.addFlag('help', abbr: 'h', negatable: false, help: 'Show how to use this command.');
  }

  final UserInput userInput;
  final UserOutput userOutput;
  final ArgParser argParser = ArgParser();

  String get name;
  String get description;

  /// The first sentence of [description], for command listings.
  String get summary => description.split('. ').first.replaceAll(RegExp(r'\.$'), '');

  /// Other names the command answers to.
  List<String> get aliases => const [];

  /// Example invocations, shown by `help <command>`.
  List<String> get examples => const [];

  /// How the positional arguments read in the usage line, e.g. `[name] [date]`.
  String get positionalSyntax => '';

  /// More positional arguments than this are rejected before the command runs.
  int get maxPositionalArguments => 0;

  ArgResults? _argResults;

  /// The parsed flags, options and positional arguments of the current run.
  ArgResults get argResults => _argResults ?? argParser.parse(const []);

  /// Runs the command with already parsed arguments.
  Future<T> execute(ArgResults results) async {
    _argResults = results;
    return await run();
  }

  /// Parses [args] (everything after the command name) and runs the command.
  Future<T> runWithArgs(List<String> args) => execute(argParser.parse(args));

  /// The command's work; read the arguments from [argResults].
  FutureOr<T> run();

  String get usage {
    final syntax = [name, if (argParser.options.length > 1) '[options]', if (positionalSyntax.isNotEmpty) positionalSyntax].join(' ');
    final buffer =
        StringBuffer()
          ..writeln(syntax)
          ..writeln(description)
          ..writeln()
          ..writeln('Options:')
          ..write(argParser.usage);
    if (examples.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln()
        ..writeln('Examples:');
      for (final example in examples) {
        buffer.writeln('  $example');
      }
    }
    return buffer.toString().trimRight();
  }
}
