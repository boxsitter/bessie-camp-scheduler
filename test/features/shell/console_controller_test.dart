import 'dart:async';

import 'package:bessie/src/cli/cli.dart';
import 'package:bessie/src/commands/core_commands.dart';
import 'package:bessie/src/core/errors.dart';
import 'package:bessie/src/features/console/controller/console_controller.dart';
import 'package:bessie/src/shared/services/popup_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:xterm/core.dart';

/// A command defined by a closure, to try the console without real services.
class _Command extends EmberCommand<void> {
  _Command(this.name, this._body, UserInput input, UserOutput output) : super(userInput: input, userOutput: output);

  @override
  final String name;
  @override
  String get description => 'A test command.';
  @override
  int get maxPositionalArguments => 2;

  final FutureOr<void> Function(_Command command) _body;

  @override
  FutureOr<void> run() => _body(this);
}

class _FakePopups extends PopupService {
  bool confirmation = true;
  final List<String> asked = [];

  @override
  Future<bool> showConfirmationDialog({String? title, String? message}) async {
    asked.add(message ?? '');
    return confirmation;
  }

  @override
  Future<List<String>> showOptionSelectionDialog({
    required String title,
    required String message,
    required List<String> options,
    List<String>? defaultSelections,
    bool allowMultipleSelections = false,
  }) async => [];
}

void main() {
  late ConsoleController console;
  late _FakePopups popups;
  late bool allowed;
  late Completer<void> release;
  late Terminal terminal;

  ConsoleController createConsole() {
    popups = _FakePopups();
    allowed = true;
    release = Completer<void>();
    console = Get.put(
      ConsoleController(
        popups: popups,
        canUseConsole: () => allowed,
        commandsBuilder:
            (c) => commandRegistry([
              _Command('hello', (cmd) => cmd.userOutput.success('Hello ${cmd.argResults.rest.join(' ')}'.trimRight()), c, c),
              _Command(
                'ask',
                (cmd) async {
                  final name = await cmd.userInput.prompt('Your name:');
                  cmd.userOutput.success('Hi $name');
                },
                c,
                c,
              ),
              _Command(
                'secret',
                (cmd) async {
                  final word = await cmd.userInput.promptPassword('Password:');
                  cmd.userOutput.success('Got ${word.length} characters');
                },
                c,
                c,
              ),
              _Command(
                'confirm',
                (cmd) async {
                  cmd.userOutput.info(await cmd.userInput.confirm('Really?') ? 'confirmed' : 'declined');
                },
                c,
                c,
              ),
              _Command(
                'pick',
                (cmd) async {
                  await cmd.userInput.select('Which?', options: ['a', 'b']);
                },
                c,
                c,
              ),
              _Command('boom', (cmd) => throw StateError('kaboom'), c, c),
              _Command('refuse', (cmd) => throw AppException('You don\'t have permission to do that.'), c, c),
              _Command(
                'slow',
                (cmd) async {
                  cmd.userOutput.info('working');
                  await release.future;
                  cmd.userOutput.info('finished');
                },
                c,
                c,
              ),
              _Command(
                'table',
                (cmd) => cmd.userOutput.printTable(
                  [
                    ['one', '1'],
                    ['two', '2'],
                  ],
                  headers: ['Name', 'N'],
                ),
                c,
                c,
              ),
            ]),
      ),
    );
    terminal = console.terminal;
    return console;
  }

  /// The screen as plain text, without the empty lines below it.
  String screen() => terminal.buffer.getText().trimRight();

  /// The line the cursor is on (the screen drops trailing spaces, so the prompt reads `>`).
  String lastLine() => screen().split('\n').last;

  Future<void> type(String text) async {
    terminal.textInput(text);
    await pumpEventQueue();
  }

  Future<void> enter() async {
    terminal.keyInput(TerminalKey.enter);
    await pumpEventQueue();
  }

  Future<void> run(String line) async {
    await type(line);
    await enter();
  }

  setUp(() => createConsole());
  tearDown(Get.reset);

  test('greets the user and shows a prompt', () {
    expect(screen(), contains('Bessie console'));
    expect(lastLine(), '>');
  });

  test('runs a command and shows its output above a fresh prompt', () async {
    await run('hello world');

    final lines = screen().split('\n');
    expect(lines.last, '>');
    expect(lines[lines.length - 2], 'Hello world');
    expect(lines[lines.length - 3], '> hello world');
  });

  test('shows tables aligned', () async {
    await run('table');

    expect(screen(), contains('Name  N\n----  -\none   1\ntwo   2'));
  });

  test('reports an unknown command and carries on', () async {
    await run('frobnicate');

    expect(screen(), contains('Error: Unknown command "frobnicate"'));
    expect(lastLine(), '>');
  });

  test('reports a bad option', () async {
    await run('hello --bogus');

    expect(screen(), contains('Could not find an option named "--bogus"'));
  });

  test('ignores an empty line', () async {
    await enter();

    expect(lastLine(), '>');
    expect(console.history, isEmpty);
  });

  test('shows a command\'s usage for --help, without running it', () async {
    await run('hello --help');

    expect(screen(), contains('A test command.'));
    expect(screen(), contains('--help'));
    expect(screen(), isNot(contains('Hello')));
  });

  test('prints the error of a failing command instead of throwing it', () async {
    await run('boom');

    expect(screen(), contains('Error: "boom" failed.'));
    expect(screen(), contains('kaboom'));
    expect(lastLine(), '>');
  });

  test('prints the message of an AppException as it is', () async {
    await run('refuse');

    expect(screen(), contains('Error: You don\'t have permission to do that.'));
  });

  test('refuses to run anything for users who may not edit session data', () async {
    allowed = false;
    await run('hello');

    expect(screen(), contains('only available to directors and admins'));
    expect(screen(), isNot(contains('Hello')));
  });

  test('answers a prompt in the terminal', () async {
    await type('ask');
    await enter();
    expect(lastLine(), 'Your name:');

    await run('Ann');

    expect(screen(), contains('Your name: Ann'));
    expect(screen(), contains('Hi Ann'));
    expect(lastLine(), '>');
  });

  test('will not accept an empty answer to a prompt', () async {
    await run('ask');
    await enter();

    expect(screen(), contains('Input cannot be empty.'));
    expect(lastLine(), 'Your name:');

    await run('Bo');
    expect(screen(), contains('Hi Bo'));
  });

  test('does not echo a password', () async {
    await run('secret');
    await run('hunter2');

    expect(screen(), isNot(contains('hunter2')));
    expect(screen(), contains('Password: *******'));
    expect(screen(), contains('Got 7 characters'));
  });

  test('backspace edits the line', () async {
    await type('hellp');
    terminal.keyInput(TerminalKey.backspace);
    await type('o');
    await enter();

    expect(screen(), contains('Hello'));
    expect(console.history, ['hello']);
  });

  test('keys that are not text are not typed into the line', () async {
    await type('hello');
    terminal.keyInput(TerminalKey.arrowLeft);
    terminal.keyInput(TerminalKey.home);
    await pumpEventQueue();
    await enter();

    expect(console.history, ['hello']);
    expect(screen(), isNot(contains('[D')));
  });

  test('the arrow keys step through the history', () async {
    await run('hello one');
    await run('hello two');

    terminal.keyInput(TerminalKey.arrowUp);
    await pumpEventQueue();
    expect(lastLine(), '> hello two');
    terminal.keyInput(TerminalKey.arrowUp);
    await pumpEventQueue();
    expect(lastLine(), '> hello one');
    terminal.keyInput(TerminalKey.arrowDown);
    terminal.keyInput(TerminalKey.arrowDown);
    await pumpEventQueue();
    expect(lastLine(), '>');
  });

  test('asking the same thing twice in a row is remembered once', () async {
    await run('hello');
    await run('hello');

    expect(console.history, ['hello']);
  });

  test('confirmations open a dialog', () async {
    popups.confirmation = false;
    await run('confirm');

    expect(popups.asked, ['Really?']);
    expect(screen(), contains('declined'));
  });

  test('backing out of a choice cancels the command', () async {
    await run('pick');

    expect(screen(), contains('Cancelled.'));
    expect(lastLine(), '>');
  });

  test('Ctrl+C abandons a prompt and the command waiting for it', () async {
    await run('ask');
    terminal.keyInput(TerminalKey.keyC, ctrl: true);
    await pumpEventQueue();

    expect(screen(), contains('^C'));
    expect(screen(), contains('Cancelled.'));
    expect(lastLine(), '>');
  });

  test('Ctrl+C at the prompt throws away what was typed', () async {
    await type('hel');
    terminal.keyInput(TerminalKey.keyC, ctrl: true);
    await pumpEventQueue();
    await enter();

    expect(console.history, isEmpty);
    expect(lastLine(), '>');
  });

  test('typing while a command is running does nothing, and the prompt comes back afterwards', () async {
    await run('slow');
    expect(lastLine(), 'working');

    await type('hello');
    await enter();
    expect(console.history, ['slow']);

    release.complete();
    await pumpEventQueue();
    expect(screen(), contains('finished'));
    expect(lastLine(), '>');
    expect(screen(), isNot(contains('Hello')));
  });

  test('clear wipes the screen', () async {
    // The real registry includes clear; here the built-in one is enough to try the wipe.
    Get.reset();
    final withClear = Get.put(
      ConsoleController(
        popups: _FakePopups(),
        canUseConsole: () => true,
        commandsBuilder:
            (c) => commandRegistry([ClearScreen(userInput: c, userOutput: c, clearScreen: () => c.terminal.write('\x1B[2J\x1B[3J\x1B[H'))]),
      ),
    );
    withClear.terminal.textInput('clear');
    withClear.terminal.keyInput(TerminalKey.enter);
    await pumpEventQueue();

    expect(withClear.terminal.buffer.getText().trim(), '>');
  });
}
