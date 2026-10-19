import 'dart:async';

import 'package:get/get.dart';
import 'package:xterm/core.dart';

import '../../../cli/cli.dart';
import '../../../commands/core_commands.dart';
import '../../../core/errors.dart';
import '../../../core/logging.dart' as logging;
import '../../../data/catalog_repository.dart';
import '../../../data/roster_repository.dart';
import '../../../data/session_repository.dart';
import '../../../services/auth_service.dart';
import '../../../services/backup_service.dart';
import '../../../services/context_service.dart';
import '../../../services/file_service.dart';
import '../../../shared/services/popup_service.dart';
import 'console_style.dart';
import 'console_table.dart';

/// Keys as the terminal reports them to [Terminal.onOutput].
class _Keys {
  static const escape = '\x1B';
  static const cursorUp = ['\x1B[A', '\x1BOA'];
  static const cursorDown = ['\x1B[B', '\x1BOB'];
  static const enter = '\r';
  static const backspace = '\b';
  static const delete = '\u007F';
  static const interrupt = '\x03';
  static const clearScreen = '\x1B[2J\x1B[3J\x1B[H';
}

/// A question waiting for the user to type an answer into the terminal.
class _PendingInput {
  _PendingInput({required this.allowEmpty, required this.masked, this.validator});

  final bool allowEmpty;
  final bool masked;
  final FutureOr<bool> Function(String)? validator;
  final Completer<String> completer = Completer<String>();
}

/// The in-app console: an xterm terminal that runs [EmberCommand]s.
///
/// It is also the [UserInput]/[UserOutput] the commands talk to. Typed
/// questions (`prompt`) are answered in the terminal itself; confirmations,
/// choices and forms open dialogs.
///
/// While a command runs no prompt is shown; the prompt comes back when it
/// finishes.
class ConsoleController extends GetxController implements UserOutput, UserInput {
  ConsoleController({PopupService? popups, Map<String, EmberCommand> Function(ConsoleController console)? commandsBuilder, bool Function()? canUseConsole})
    : _popupsOverride = popups,
      _commandsBuilder = commandsBuilder ?? _defaultCommands,
      _canUseConsole = canUseConsole ?? _signedInUserCanEdit;

  static const _mainPrompt = '> ';

  final PopupService? _popupsOverride;
  final Map<String, EmberCommand> Function(ConsoleController console) _commandsBuilder;
  final bool Function() _canUseConsole;

  late final PopupService _popups = _popupsOverride ?? Get.find<PopupService>();
  late final Map<String, EmberCommand> _commands;

  final Terminal terminal = Terminal(maxLines: 10000);

  /// Every command line entered, oldest first.
  final List<String> history = [];
  int _historyIndex = 0;

  String _inputBuffer = '';
  String _promptText = _mainPrompt;
  bool _promptVisible = false;
  bool _commandRunning = false;
  _PendingInput? _pending;

  static Map<String, EmberCommand> _defaultCommands(ConsoleController console) => CoreCommands.build(
    input: console,
    output: console,
    clearScreen: console._clearScreen,
    auth: Get.find<AuthService>(),
    context: Get.find<ContextService>(),
    catalog: Get.find<CatalogRepository>(),
    sessions: Get.find<SessionRepository>(),
    roster: Get.find<RosterRepository>(),
    backup: Get.find<BackupService>(),
    files: Get.find<FileService>(),
  );

  static bool _signedInUserCanEdit() => Get.find<AuthService>().profile.value?.role.canEditSessionData ?? false;

  @override
  void onInit() {
    super.onInit();
    _commands = _commandsBuilder(this);
    terminal.onOutput = _handleKeyInput;
    terminal.write('Bessie console. Type help to see what you can do.\r\n');
    _showPrompt(_mainPrompt);
  }

  @override
  void onClose() {
    terminal.onOutput = null;
    _pending?.completer.completeError(const InputCancelled());
    _pending = null;
    super.onClose();
  }

  // Running commands ----------------------------------------------------------

  void _clearScreen() => terminal.write(_Keys.clearScreen);

  Future<void> _executeCommand(String line) async {
    final text = line.trim();
    if (text.isEmpty) return;
    if (history.isEmpty || history.last != text) history.add(text);
    _historyIndex = history.length;

    if (!_canUseConsole()) {
      error('The console is only available to directors and admins.');
      return;
    }

    final parsed = CommandParser.parseCommand(text, availableCommands: _commands);
    final command = parsed.command;
    if (parsed.isError || command == null) {
      error(parsed.errorMessage ?? 'That command could not be understood.');
      return;
    }
    if (parsed.helpRequested) {
      log(command.usage);
      return;
    }

    try {
      await command.execute(parsed.results!);
    } on InputCancelled {
      info('Cancelled.');
    } on AppException catch (e, st) {
      logging.log.w('Console command "$text" failed', error: e.cause ?? e, stackTrace: st);
      error(e.message);
    } catch (e, st) {
      logging.log.e('Console command "$text" failed', error: e, stackTrace: st);
      error('"${command.name}" failed.', details: e.toString());
    }
  }

  // Keyboard ------------------------------------------------------------------

  Future<void> _handleKeyInput(String data) async {
    // Terminal replies (cursor position, device attributes) and keys we don't
    // use (arrows left/right, home, ...) arrive as escape sequences.
    if (data.startsWith(_Keys.escape)) {
      if (_pending == null && !_commandRunning) {
        if (_Keys.cursorUp.contains(data)) _navigateHistory(older: true);
        if (_Keys.cursorDown.contains(data)) _navigateHistory(older: false);
      }
      return;
    }

    for (final rune in data.runes) {
      final char = String.fromCharCode(rune);
      switch (char) {
        case _Keys.enter:
          await _handleEnter();
        case _Keys.backspace || _Keys.delete:
          _handleBackspace();
        case _Keys.interrupt:
          _handleInterrupt();
        default:
          if (rune >= 32 && rune != 127) _handleCharacter(char);
      }
    }
  }

  bool get _acceptingInput => _pending != null || !_commandRunning;

  void _handleCharacter(String char) {
    if (!_acceptingInput) return;
    _inputBuffer += char;
    terminal.write(_pending?.masked == true ? '*' : char);
  }

  void _handleBackspace() {
    if (!_acceptingInput || _inputBuffer.isEmpty) return;
    _inputBuffer = _inputBuffer.substring(0, _inputBuffer.length - 1);
    terminal.write('\b \b');
  }

  void _handleInterrupt() {
    if (_commandRunning && _pending == null) return;
    _inputBuffer = '';
    _promptVisible = false;
    terminal.write('^C\r\n');
    final pending = _pending;
    if (pending != null) {
      _pending = null;
      pending.completer.completeError(const InputCancelled());
    } else {
      _showPrompt(_mainPrompt);
    }
  }

  Future<void> _handleEnter() async {
    final pending = _pending;
    if (pending != null) return _submitAnswer(pending);
    if (_commandRunning) return;

    final line = _inputBuffer;
    _inputBuffer = '';
    _promptVisible = false;
    terminal.write('\r\n');
    _commandRunning = true;
    try {
      await _executeCommand(line);
    } finally {
      _commandRunning = false;
      _showPrompt(_mainPrompt);
    }
  }

  Future<void> _submitAnswer(_PendingInput pending) async {
    final answer = _inputBuffer;
    String? problem;
    if (!pending.allowEmpty && answer.trim().isEmpty) {
      problem = 'Input cannot be empty.';
    } else if (pending.validator != null && !await pending.validator!(answer)) {
      problem = 'That is not valid. Please try again.';
    }
    if (problem != null) {
      _inputBuffer = '';
      _emit(ConsoleStyle.error(problem));
      return;
    }

    _pending = null;
    _inputBuffer = '';
    _promptVisible = false;
    terminal.write('\r\n');
    pending.completer.complete(answer);
  }

  void _navigateHistory({required bool older}) {
    if (history.isEmpty) return;
    _historyIndex = (_historyIndex + (older ? -1 : 1)).clamp(0, history.length);
    _replaceInputBuffer(_historyIndex < history.length ? history[_historyIndex] : '');
  }

  void _replaceInputBuffer(String text) {
    _inputBuffer = text;
    terminal.write('\r\x1B[2K$_promptText$text');
  }

  // Terminal output -----------------------------------------------------------

  /// Shows [prompt] and whatever has been typed so far on the current line.
  void _showPrompt(String prompt) {
    _promptText = prompt;
    _promptVisible = true;
    terminal.write('$prompt${_pending?.masked == true ? '*' * _inputBuffer.length : _inputBuffer}');
  }

  /// Writes [text] on its own line(s), keeping a visible prompt (and what is
  /// typed after it) at the bottom.
  void _emit(String text) {
    if (_promptVisible) terminal.write('\r\x1B[2K');
    terminal.write('${text.replaceAll(RegExp(r'\r?\n'), '\r\n')}\r\n');
    if (_promptVisible) _showPrompt(_promptText);
  }

  @override
  void log(String message) => _emit(message);

  @override
  void error(String message, {String? details}) {
    _emit(ConsoleStyle.error('Error: $message'));
    if (details != null && details.isNotEmpty) _emit(ConsoleStyle.dim(details));
  }

  @override
  void warning(String message) => _emit(ConsoleStyle.warning('Warning: $message'));

  @override
  void success(String message) => _emit(ConsoleStyle.success(message));

  @override
  void info(String message) => _emit(ConsoleStyle.info(message));

  @override
  void printEmph(String message) => _emit(ConsoleStyle.emphasis(message));

  @override
  void printDim(String message) => _emit(ConsoleStyle.dim(message));

  @override
  void printHeading(String message) => _emit('${ConsoleStyle.emphasis(message.toUpperCase())}\n${'-' * message.length}');

  @override
  void printProperty(String key, dynamic value) => _emit('${ConsoleStyle.emphasis(key)}: $value');

  @override
  void printList(List<String> items, {String title = 'Items:'}) {
    _emit(items.isEmpty ? '$title (none)' : [title, for (final item in items) '  - $item'].join('\n'));
  }

  @override
  void printTable(List<List<String>> dataRows, {List<String>? headers}) {
    if (dataRows.isEmpty && (headers == null || headers.isEmpty)) {
      _emit('(empty table)');
      return;
    }
    _emit(formatTable(dataRows, headers: headers).join('\n'));
  }

  // Input ---------------------------------------------------------------------

  @override
  Future<String> prompt(String message, {String? defaultValue, bool allowEmpty = false, FutureOr<bool> Function(String)? validator}) =>
      _ask(message, defaultValue: defaultValue, allowEmpty: allowEmpty, validator: validator);

  @override
  Future<String> promptPassword(String message) => _ask(message, masked: true);

  Future<String> _ask(String message, {String? defaultValue, bool allowEmpty = false, bool masked = false, FutureOr<bool> Function(String)? validator}) {
    _pending?.completer.completeError(StateError('Another question was asked before this one was answered.'));
    if (_promptVisible) terminal.write('\r\x1B[2K');

    final pending = _PendingInput(allowEmpty: allowEmpty, masked: masked, validator: validator);
    _pending = pending;
    _inputBuffer = masked ? '' : defaultValue ?? '';
    _showPrompt('$message ');
    return pending.completer.future;
  }

  @override
  Future<bool> confirm(String message, {bool defaultValue = false}) => _popups.showConfirmationDialog(title: 'Confirm', message: message);

  @override
  Future<String> select(String message, {required List<String> options, String? defaultValue}) async {
    final chosen = await _popups.showOptionSelectionDialog(
      title: 'Select',
      message: message,
      options: options,
      defaultSelections: defaultValue == null ? null : [defaultValue],
    );
    if (chosen.isEmpty) throw const InputCancelled();
    return chosen.single;
  }

  @override
  Future<List<String>> multiSelect(String message, {required List<String> options, List<String>? defaultSelection}) {
    return _popups.showOptionSelectionDialog(
      title: 'Select',
      message: message,
      options: options,
      defaultSelections: defaultSelection,
      allowMultipleSelections: true,
    );
  }

  @override
  Future<T> withSpinner<T>({required String inProgressMessage, String? completionMessage, required Future<T> Function() task}) async {
    final result = await _popups.executeWithSpinner(inProgressMessage: inProgressMessage, task: task);
    if (completionMessage != null) success(completionMessage);
    return result;
  }

  @override
  Future<List<dynamic>?> promptForm(String formTitle, List<FormFieldDescriptor> fields) {
    return _popups.showDynamicFormDialog(title: formTitle, fields: fields);
  }
}
