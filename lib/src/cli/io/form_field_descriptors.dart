import 'dart:async';

/// Describes one field of a form a command shows through `UserInput.promptForm`.
abstract class FormFieldDescriptor<T> {
  FormFieldDescriptor({required this.label, this.defaultValue, this.isRequired = true, this.validator});

  final String label;
  final T? defaultValue;
  final bool isRequired;

  /// Returns null when the value is acceptable, otherwise the message to show.
  final FutureOr<String?> Function(T?)? validator;
}

class TextFormFieldDescriptor extends FormFieldDescriptor<String> {
  TextFormFieldDescriptor({
    required super.label,
    super.defaultValue,
    this.hintText,
    this.allowEmpty = false,
    this.isPassword = false,
    super.isRequired,
    super.validator,
  });

  final String? hintText;
  final bool allowEmpty;
  final bool isPassword;
}

class BooleanFormFieldDescriptor extends FormFieldDescriptor<bool> {
  BooleanFormFieldDescriptor({required super.label, super.defaultValue = false, super.isRequired, super.validator});
}

/// Choose one of [options]; the form returns the chosen option object.
class SelectFormFieldDescriptor<T> extends FormFieldDescriptor<T> {
  SelectFormFieldDescriptor({
    required super.label,
    required this.options,
    required this.optionLabelBuilder,
    super.defaultValue,
    super.isRequired,
    super.validator,
  }) : assert(options.isNotEmpty, 'A select field needs at least one option.');

  final List<T> options;
  final String Function(dynamic value) optionLabelBuilder;
}

/// Choose any number of [options]; the form returns the list of chosen objects.
class MultiSelectFormFieldDescriptor<T> extends FormFieldDescriptor<List<T>> {
  MultiSelectFormFieldDescriptor({
    required super.label,
    required this.options,
    required this.optionLabelBuilder,
    super.defaultValue,
    super.isRequired,
    super.validator,
  }) : assert(options.isNotEmpty, 'A multi-select field needs at least one option.');

  final List<T> options;
  final String Function(dynamic value) optionLabelBuilder;
}
