// user_io_interface.dart

import 'dart:async';

import 'form_field_descriptors.dart';

/// Interface for handling user input operations.
abstract class UserInput {
  FutureOr<String> prompt(
    String message, {
    String? defaultValue,
    bool allowEmpty = false,
    FutureOr<bool> Function(String)? validator,
  });

  FutureOr<String> promptPassword(String message);

  FutureOr<bool> confirm(String message, {bool defaultValue = false});

  FutureOr<String> select(
    String message, {
    required List<String> options,
    String? defaultValue,
  });

  FutureOr<List<String>> multiSelect(
    String message, {
    required List<String> options,
    List<String>? defaultSelection,
  });

  Future<T> withSpinner<T>({
    required String inProgressMessage,
    String? completionMessage,
    required Future<T> Function() task,
  });

  /// Prompts the user with a dynamically generated form.
  ///
  /// [formTitle]: The title for the form dialog.
  /// [fields]: A list of [FormFieldDescriptor] objects defining the form.
  ///
  /// Returns a `Future<Map<String, dynamic>?>`.
  /// The map contains the collected data, with keys matching the `id` of each `FormFieldDescriptor`.
  /// Returns `null` if the user cancels the form.
  /// Returns an empty map if the form is submitted with no fields (edge case).
  Future<List<dynamic>?> promptForm(
    String formTitle,
    List<FormFieldDescriptor> fields,
  );
}

/// Interface for handling user output operations.
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
