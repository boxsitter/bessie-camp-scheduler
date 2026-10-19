import 'package:bessie/src/cli/cli.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_io.dart';

class _TestCommand extends EmberCommand<void> {
  _TestCommand(FakeIo io, {this.name = 'demo', this.aliases = const [], this.maxPositionalArguments = 2})
    : super(userInput: io, userOutput: io) {
    argParser
      ..addFlag('all', abbr: 'a', negatable: false)
      ..addFlag('verbose', abbr: 'v', negatable: false)
      ..addOption('name', abbr: 'n');
  }

  @override
  final String name;
  @override
  final List<String> aliases;
  @override
  final int maxPositionalArguments;
  @override
  String get description => 'Does a demonstration. It has two sentences.';

  @override
  void run() {}
}

void main() {
  final io = FakeIo();
  final demo = _TestCommand(io, aliases: ['dm']);
  final other = _TestCommand(io, name: 'other', maxPositionalArguments: 0);
  final commands = {demo.name: demo, 'dm': demo, other.name: other};

  ParsedCommandResult parse(String line) => CommandParser.parseCommand(line, availableCommands: commands);

  group('tokenize', () {
    test('splits on whitespace', () {
      expect(CommandParser.tokenize('  a   b\tc '), ['a', 'b', 'c']);
    });

    test('keeps quoted text together, with either kind of quote', () {
      expect(CommandParser.tokenize('mksesh "Session 3" \'07 06\''), ['mksesh', 'Session 3', '07 06']);
    });

    test('joins quoted text to what touches it', () {
      expect(CommandParser.tokenize('--name="Bob Smith"'), ['--name=Bob Smith']);
    });

    test('an empty quoted string is a token', () {
      expect(CommandParser.tokenize('a "" b'), ['a', '', 'b']);
    });

    test('a backslash escapes the next character', () {
      expect(CommandParser.tokenize(r'say hello\ world "a \"quoted\" word"'), ['say', 'hello world', 'a "quoted" word']);
    });

    test('an unclosed quote is an error', () {
      expect(() => CommandParser.tokenize('mksesh "oops'), throwsFormatException);
    });

    test('nothing yields no tokens', () {
      expect(CommandParser.tokenize('   '), isEmpty);
    });
  });

  group('parseCommand', () {
    test('finds a command by name or alias', () {
      expect(parse('demo').command, same(demo));
      expect(parse('dm').command, same(demo));
      expect(parse('demo').isError, isFalse);
    });

    test('is not case sensitive about the command name', () {
      expect(parse('DEMO').command, same(demo));
    });

    test('collects positional arguments', () {
      final result = parse('demo one "two words"');
      expect(result.arguments, ['one', 'two words']);
      expect(result.flagsAndOptions, isEmpty);
    });

    test('reads flags, abbreviations and options', () {
      final result = parse('demo -a --verbose --name Ann extra');
      expect(result.flagsAndOptions, {'all': true, 'verbose': true, 'name': 'Ann'});
      expect(result.arguments, ['extra']);
      expect(result.results!['all'], isTrue);
    });

    test('reads --option=value and abbreviations stuck together', () {
      final result = parse('demo -av --name=Bo');
      expect(result.flagsAndOptions, {'all': true, 'verbose': true, 'name': 'Bo'});
    });

    test('flags that were not given are not listed, but read as false', () {
      final result = parse('demo');
      expect(result.flagsAndOptions, isEmpty);
      expect(result.results!['all'], isFalse);
    });

    test('recognizes a request for help', () {
      expect(parse('demo --help').helpRequested, isTrue);
      expect(parse('demo -h').helpRequested, isTrue);
      expect(parse('demo').helpRequested, isFalse);
    });

    test('rejects an empty line', () {
      expect(parse('   ').errorMessage, 'No command entered.');
      expect(parse('').command, isNull);
    });

    test('rejects an unknown command, naming it', () {
      final result = parse('nope now');
      expect(result.command, isNull);
      expect(result.errorMessage, contains('"nope"'));
    });

    test('rejects an unknown option and points at help', () {
      final result = parse('demo --bogus');
      expect(result.isError, isTrue);
      expect(result.errorMessage, contains('bogus'));
      expect(result.errorMessage, contains('demo --help'));
      expect(result.command, same(demo));
    });

    test('rejects an option without its value', () {
      expect(parse('demo --name').isError, isTrue);
    });

    test('rejects more positional arguments than the command takes', () {
      expect(parse('demo a b c').errorMessage, contains('Unexpected argument "c"'));
      expect(parse('other a').errorMessage, contains('Unexpected argument "a"'));
      expect(parse('other').isError, isFalse);
    });

    test('rejects an unclosed quote', () {
      expect(parse('demo "oops').errorMessage, contains('closing quote'));
    });
  });

  group('EmberCommand', () {
    test('summary is the first sentence of the description', () {
      expect(demo.summary, 'Does a demonstration');
    });

    test('usage lists the options', () {
      expect(demo.usage, contains('demo [options]'));
      expect(demo.usage, contains('--verbose'));
      expect(demo.usage, contains('--help'));
    });

    test('runWithArgs parses and exposes the arguments', () async {
      await demo.runWithArgs(['-a', 'x']);
      expect(demo.argResults['all'], isTrue);
      expect(demo.argResults.rest, ['x']);
    });
  });
}
