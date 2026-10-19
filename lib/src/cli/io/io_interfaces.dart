import 'dart:async';

import 'form_field_descriptors.dart';

/// Thrown by an input method when the user backs out of a prompt.
///
/// Whoever runs a command catches it and reports "Cancelled", so commands
/// don't each have to handle every prompt returning nothing.
class InputCancelled implements Exception {
  const InputCancelled();

  @override
  String toString() => 'InputCancelled';
}

/// How a command asks the user for things.
abstract class UserInput {
  FutureOr<String> prompt(String message, {String? defaultValue, bool allowEmpty = false, FutureOr<bool> Function(String)? validator});

  /// Like [prompt] but the typed characters are not echoed.
  FutureOr<String> promptPassword(String message);

  FutureOr<bool> confirm(String message, {bool defaultValue = false});

  /// Picks one of [options]; throws [InputCancelled] if the user backs out.
  FutureOr<String> select(String message, {required List<String> options, String? defaultValue});

  FutureOr<List<String>> multiSelect(String message, {required List<String> options, List<String>? defaultSelection});

  Future<T> withSpinner<T>({required String inProgressMessage, String? completionMessage, required Future<T> Function() task});

  /// Shows a form described by [fields].
  ///
  /// Returns the values in the order of [fields] (for a select field the
  /// chosen option object itself), or null if the user cancels.
  Future<List<dynamic>?> promptForm(String formTitle, List<FormFieldDescriptor> fields);
}

/// How a command reports back to the user.
abstract class UserOutput {
  void log(String message);
  void error(String message, {String? details});
  void warning(String message);
  void success(String message);
  void info(String message);
  void printEmph(String message);
  void printDim(String message);
  void printHeading(String message);
  void printProperty(String key, dynamic value);
  void printList(List<String> items, {String title = 'Items:'});
  void printTable(List<List<String>> dataRows, {List<String>? headers});
}
