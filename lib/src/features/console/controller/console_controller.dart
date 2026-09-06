import 'dart:async';

import 'package:ansicolor/ansicolor.dart';
import 'package:bessie/src/shared/services/popup_service.dart';
import 'package:bessie/src/cli/cli.dart';
import 'package:bessie/src/ember_core.dart';
import 'package:get/get.dart';
import 'package:xterm/core.dart';

// Constants for ANSI escape codes
class _AnsiCodes {
  static const String cursorUp = '\x1B[A';
  static const String cursorDown = '\x1B[B';
  static const String clearScreen = '\x1B[2J\x1B[H';
  static const String backspace = '\b';
  static const String delete = '\u007F';
  static const String enter = '\r';
}

class ConsoleController extends GetxController implements UserOutput, UserInput {
  PopupService popupService = Get.find<PopupService>();

  late final Terminal terminal;
  final List<String> history = [];
  int historyIndex = -1;

  // Refined prompt text handling
  final String _mainCommandPrompt = '> '; // Your default main command prompt
  String _currentPromptText = '> ';      // Holds the text of the prompt currently visually forming the line
  String? _activeInputPromptMessage;     // Stores the specific message for an active UserInput.prompt()

  String inputBuffer = '';

  bool _isAwaitingPromptInput = false;
  Completer<String>? _promptCompleter;
  FutureOr<bool> Function(String)? _currentPromptValidator;
  bool _currentPromptAllowEmpty = false;

  final AnsiPen _penError = AnsiPen()..red(bold: true);
  final AnsiPen _penWarning = AnsiPen()..yellow();
  final AnsiPen _penSuccess = AnsiPen()..green();
  final AnsiPen _penInfo = AnsiPen()..blue();
  final AnsiPen _penEmph = AnsiPen()..cyan(bold: true);
  final AnsiPen _penDim = AnsiPen()..gray(level: 0.5);

  @override
  void onInit() {
    super.onInit();
    _currentPromptText = _mainCommandPrompt; // Initialize with the main command prompt
    terminal = Terminal(
      maxLines: 10000,
      onOutput: _handleKeyInput, // Unified input handler
    );
    writePrimaryPrompt();
  }

  void writePrimaryPrompt() {
    terminal.write('\r\n$_mainCommandPrompt');
    _currentPromptText = _mainCommandPrompt; // Update current visual prompt text
  }

  void _writeTemporaryPrompt(String message) {
    terminal.write('\r${' ' * (_currentPromptText.length + inputBuffer.length)}\r');
    terminal.write('$message ');
    _currentPromptText = message + " "; // Update current visual prompt text to the temporary one
  }

  Future<void> _executeCommand(String command) async {
    if (command.isEmpty) return;

      history.add(command);
      historyIndex = history.length;

    try {
      if (command == 'clear') {
        terminal.write(_AnsiCodes.clearScreen);
      } else {
        void handleError(String message) {
          error(message);
        }

        ParsedCommandResult result = CommandParser.parseCommand(
            command,
            availableCommands: CoreCommands.list,
            setErrorMessage: handleError,
            initialArgs: [],
            initialFlagsAndOptions: {},
        );

        if (result.command != null) {
          await result.command!.run();
        }
      }
    } catch (e) {
      error('Failed to execute command: $command', details: e.toString());
      throw(e);
    }
  }

  // Unified Key Input Handler
  void _handleKeyInput(String data) async {
    // First, check for multi-character sequences that should be treated as a single command
    if (data == _AnsiCodes.cursorUp) {
      _navigateHistory(true);
      return;
    }
    if (data == _AnsiCodes.cursorDown) {
      _navigateHistory(false);
      return;
    }

    // If not a special sequence, process character by character
    for (var charRune in data.runes) {
      final char = String.fromCharCode(charRune);
      switch (char) {
        case _AnsiCodes.enter:
          if (_isAwaitingPromptInput) {
            await _handlePromptEnter();
          } else {
            await _handleCommandEnter();
          }
          break;
        case _AnsiCodes.backspace:
        case _AnsiCodes.delete:
          _handleBackspace();
          break;
        default:
          // Handle all other characters, including space
          if (charRune >= 32 && charRune != 127) { // Printable characters
            inputBuffer += char;
            terminal.write(char);
          }
      }
    }
  }

  void _navigateHistory(bool up) {
    if (history.isEmpty) return;
    if (up) {
      if (historyIndex > 0) {
        historyIndex--;
      } else {
        historyIndex = 0; // Stay at the first item
         }
    } else { // Down
      if (historyIndex < history.length - 1) {
        historyIndex++;
      } else {
        historyIndex = history.length; // Go to the "new" line buffer
        _replaceInputBuffer('');
        return;
      }
    }
    _replaceInputBuffer(history[historyIndex]);
      }

  Future<void> _handleCommandEnter() async {
    terminal.write('\r\n');
            String commandToExecute = inputBuffer;
            inputBuffer = '';
            await _executeCommand(commandToExecute);
            if (commandToExecute != 'clear') {
            writePrimaryPrompt();
    }
  }

  Future<void> _handlePromptEnter() async {
          final currentValue = inputBuffer;
          final String messageForReprompt = _activeInputPromptMessage ?? _mainCommandPrompt;

          if (!_currentPromptAllowEmpty && currentValue.trim().isEmpty) {
            _writeWithNewlineAndPromptFix(_penError('Input cannot be empty.'));
      _writeTemporaryPrompt(messageForReprompt);
      inputBuffer = ''; // Clear buffer for re-entry
            return;
          }

          bool isValid = true;
          if (_currentPromptValidator != null) {
            final validationResult = _currentPromptValidator!(currentValue);
      isValid = (validationResult is Future<bool>) ? await validationResult : validationResult;
          }

          if (isValid) {
            _isAwaitingPromptInput = false;
            terminal.write('\r\n');
            _promptCompleter?.complete(currentValue);
            _promptCompleter = null;
            inputBuffer = '';
      _activeInputPromptMessage = null;
            writePrimaryPrompt();
          } else {
            _writeWithNewlineAndPromptFix(_penError('Invalid input. Please try again.'));
      _writeTemporaryPrompt(messageForReprompt);
      inputBuffer = ''; // Clear buffer for re-entry
          }
  }

  void _handleBackspace() {
          if (inputBuffer.isNotEmpty) {
            inputBuffer = inputBuffer.substring(0, inputBuffer.length - 1);
            terminal.write('\b \b');
          }
      }

  void _replaceInputBuffer(String newInput) {
    // Visually clear current inputBuffer
    for (int i = 0; i < inputBuffer.length; i++) {
        terminal.write('\b \b');
    }
    inputBuffer = newInput;
    terminal.write(newInput);
  }

  void _writeWithNewlineAndPromptFix(String text) {
    terminal.write('\r${' ' * (_currentPromptText.length + inputBuffer.length)}\r');
    terminal.write(text.replaceAll('\n', '\r\n'));
    terminal.write('\r\n');
    if (!_isAwaitingPromptInput) {
      // Restore the main command prompt and current input buffer
      terminal.write('$_mainCommandPrompt$inputBuffer');
      _currentPromptText = _mainCommandPrompt; // Ensure current visual prompt is main prompt
    } else {
      // If awaiting input, restore the temporary input prompt and current input buffer
      final promptToDisplay = (_activeInputPromptMessage ?? _currentPromptText);
      terminal.write('$promptToDisplay$inputBuffer');
    }
  }

  @override
  void log(String message) {
    _writeWithNewlineAndPromptFix(message);
  }

  @override
  void error(String message, {String? details}) {
    String fullMessage = _penError('Error: $message');
    if (details != null && details.isNotEmpty) {
      fullMessage += '\r\n${_penDim(details)}';
    }
    _writeWithNewlineAndPromptFix(fullMessage);
  }

  @override
  void warning(String message) {
    _writeWithNewlineAndPromptFix(_penWarning('Warning: $message'));
  }

  @override
  void success(String message) {
    _writeWithNewlineAndPromptFix(_penSuccess(message));
  }

  @override
  void info(String message) {
    _writeWithNewlineAndPromptFix(_penInfo(message));
  }

  @override
  void printEmph(String message) {
    _writeWithNewlineAndPromptFix(_penEmph(message));
  }

  @override
  void printDim(String message) {
    _writeWithNewlineAndPromptFix(_penDim(message));
  }

  @override
  void printHeading(String message) {
    final heading = '${_penEmph(message.toUpperCase())}\r\n${'-' * message.length}';
    _writeWithNewlineAndPromptFix(heading);
  }

  @override
  void printProperty(String key, dynamic value) {
    _writeWithNewlineAndPromptFix('${_penEmph(key)}: $value');
  }

  @override
  void printList(List<String> items, {String title = 'Items:'}) {
    String listOutput = title;
    if (items.isEmpty) {
      listOutput += ' (No items)';
    } else {
      for (final item in items) {
        listOutput += '\r\n  - $item';
      }
    }
    _writeWithNewlineAndPromptFix(listOutput);
  }

  @override
  void printTable(List<List<String>> dataRows, {List<String>? headers}) {
    if (dataRows.isEmpty && (headers == null || headers.isEmpty)) {
      _writeWithNewlineAndPromptFix('(Empty table)');
      return;
    }

    StringBuffer sb = StringBuffer();
    List<int> columnWidths = [];

    if (headers != null && headers.isNotEmpty) {
      for (int i = 0; i < headers.length; i++) {
        columnWidths.add(headers[i].length);
      }
    }

    for (var row in dataRows) {
      for (int i = 0; i < row.length; i++) {
        if (i < columnWidths.length) {
          if (row[i].length > columnWidths[i]) {
            columnWidths[i] = row[i].length;
          }
        } else {
          columnWidths.add(row[i].length);
        }
      }
    }
    if (headers != null && headers.isNotEmpty) {
      for (int i = 0; i < headers.length; i++) {
        sb.write(_penEmph(headers[i].padRight(columnWidths[i])) + '  ');
      }
      sb.write('\r\n');
      for (int i = 0; i < headers.length; i++) {
        sb.write('-'.padRight(columnWidths[i], '-') + '  ');
      }
      sb.write('\r\n');
    }
    for (var row in dataRows) {
      for (int i = 0; i < row.length; i++) {
        sb.write(row[i].padRight(columnWidths[i]) + '  ');
      }
      sb.write('\r\n');
    }
    _writeWithNewlineAndPromptFix(sb.toString().trimRight());
  }

  @override
  Future<String> prompt(
      String message, {
        String? defaultValue,
        bool allowEmpty = false,
        FutureOr<bool> Function(String)? validator,
      }) {
    if (_isAwaitingPromptInput) {
      _promptCompleter?.completeError(StateError('Another prompt was initiated.'));
    }

    _isAwaitingPromptInput = true;
    _promptCompleter = Completer<String>();
    _currentPromptValidator = validator;
    _currentPromptAllowEmpty = allowEmpty;
    _activeInputPromptMessage = message; // Store the specific prompt message
    inputBuffer = defaultValue ?? '';

    _writeTemporaryPrompt(message); // This will set _currentPromptText to the temporary message
    terminal.write(inputBuffer);

    return _promptCompleter!.future.whenComplete(() {
      _currentPromptText = _mainCommandPrompt; // Reset visual prompt tracker to main prompt
      _activeInputPromptMessage = null; // Clear active message
    });
  }

  @override
  FutureOr<String> promptPassword(
      String message, {
        FutureOr<bool> Function(String)? validator,
      }) {
    return prompt(message, allowEmpty: false, validator: validator);
  }

  @override
  Future<bool> confirm(String message, {bool defaultValue = false}) async {
    return await popupService.showConfirmationDialog(title: 'Confirm', message: message);
  }

  @override
  Future<String> select(
      String message, {
        required List<String> options,
        String? defaultValue,
      }) async {
    final result = await popupService.showOptionSelectionDialog(
        title: 'Select',
        message: message,
        options: options,
        defaultSelections: defaultValue == null ? null : [defaultValue],
        allowMultipleSelections: false,
    );
    if (result.isEmpty) {
        if (defaultValue != null && options.contains(defaultValue)) return defaultValue;
        if (options.isNotEmpty) return options.first;
        throw StateError('Selection cancelled and no valid fallback option.');
    }
    return result.single;
  }

  @override
  Future<List<String>> multiSelect(
      String message, {
        required List<String> options,
        List<String>? defaultSelection,
      }) async {
    return await popupService.showOptionSelectionDialog(
    title: 'Select multiple',
    message: message,
    options: options,
    defaultSelections: defaultSelection,
    allowMultipleSelections: true,
    );
  }

  @override
  Future<T> withSpinner<T>({
    required String inProgressMessage,
    String? completionMessage,
    required Future<T> Function() task,
  }) async {
    return await popupService.executeWithSpinner(inProgressMessage: inProgressMessage, task: task);
  }

  @override
  Future<List<dynamic>?> promptForm(
      String formTitle,
      List<FormFieldDescriptor> fields,
      ) async {
    return await popupService.showDynamicFormDialog(
      title: formTitle,
      fields: fields,
    );
  }
}

