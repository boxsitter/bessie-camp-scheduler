import 'dart:async';
import 'dart:collection';

import 'package:bessie/src/cli/cli.dart';

/// A [UserInput] and [UserOutput] for tests: answers questions from queues
/// scripted up front and records everything the command prints.
class FakeIo implements UserInput, UserOutput {
  FakeIo({Iterable<String> prompts = const [], Iterable<bool> confirmations = const [], Iterable<List<dynamic>?> forms = const []})
    : _promptAnswers = Queue.of(prompts),
      _confirmAnswers = Queue.of(confirmations),
      _formAnswers = Queue.of(forms);

  final Queue<String> _promptAnswers;
  final Queue<bool> _confirmAnswers;
  final Queue<List<dynamic>?> _formAnswers;

  /// Everything printed, in order, one entry per call (`error: ...`, `Key: value`, ...).
  final List<String> lines = [];

  /// The rows of every table printed.
  final List<List<List<String>>> tables = [];

  /// The questions asked, in order.
  final List<String> prompts = [];
  final List<String> confirmations = [];

  /// The title and fields of every form shown.
  final List<(String, List<FormFieldDescriptor>)> forms = [];

  String get output => lines.join('\n');
  bool printed(String fragment) => lines.any((line) => line.contains(fragment));

  // UserInput -----------------------------------------------------------------

  @override
  FutureOr<String> prompt(
    String message, {
    String? defaultValue,
    bool allowEmpty = false,
    FutureOr<bool> Function(String)? validator,
  }) async {
    prompts.add(message);
    if (_promptAnswers.isEmpty) throw StateError('Unexpected prompt: $message');
    final answer = _promptAnswers.removeFirst();
    if (validator != null && !await validator(answer)) throw StateError('The scripted answer "$answer" fails validation for: $message');
    return answer;
  }

  @override
  FutureOr<String> promptPassword(String message) => prompt(message);

  @override
  FutureOr<bool> confirm(String message, {bool defaultValue = false}) {
    confirmations.add(message);
    if (_confirmAnswers.isEmpty) throw StateError('Unexpected confirmation: $message');
    return _confirmAnswers.removeFirst();
  }

  @override
  FutureOr<String> select(String message, {required List<String> options, String? defaultValue}) => throw UnimplementedError();

  @override
  FutureOr<List<String>> multiSelect(String message, {required List<String> options, List<String>? defaultSelection}) =>
      throw UnimplementedError();

  @override
  Future<T> withSpinner<T>({required String inProgressMessage, String? completionMessage, required Future<T> Function() task}) => task();

  @override
  Future<List<dynamic>?> promptForm(String formTitle, List<FormFieldDescriptor> fields) async {
    forms.add((formTitle, fields));
    if (_formAnswers.isEmpty) throw StateError('Unexpected form: $formTitle');
    return _formAnswers.removeFirst();
  }

  // UserOutput ----------------------------------------------------------------

  @override
  void log(String message) => lines.add(message);

  @override
  void error(String message, {String? details}) => lines.add('error: $message');

  @override
  void warning(String message) => lines.add('warning: $message');

  @override
  void success(String message) => lines.add('success: $message');

  @override
  void info(String message) => lines.add('info: $message');

  @override
  void printEmph(String message) => lines.add(message);

  @override
  void printDim(String message) => lines.add(message);

  @override
  void printHeading(String message) => lines.add(message);

  @override
  void printProperty(String key, dynamic value) => lines.add('$key: $value');

  @override
  void printList(List<String> items, {String title = 'Items:'}) => lines.addAll([title, ...items]);

  @override
  void printTable(List<List<String>> dataRows, {List<String>? headers}) {
    tables.add([if (headers != null) headers, ...dataRows]);
    lines.addAll([for (final row in dataRows) row.join(' | ')]);
  }
}
