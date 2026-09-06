// import 'package:bessie/src/cli/io/form_field_descriptors.dart';
//
// import 'io_interfaces.dart';
//
// /// A utility class for interactive CLI input.
// class CliInput implements UserInput {
//   /// Prompts the user for a text input.
//   @override
//   String prompt(String message, {String? defaultValue, bool allowEmpty = false, Function(String)? validator}) {
//     final Input input = Input(
//       prompt: message,
//       defaultValue: defaultValue,
//       validator: (s) {
//         if (!allowEmpty && s.trim().isEmpty) {
//           return false;
//         }
//         if (validator != null) {
//           return validator(s);
//         }
//         return true;
//       },
//     );
//     return input.interact();
//   }
//
//   /// Prompts the user for a password (hidden input).
//   @override
//   String promptPassword(String message) {
//     final secret = Password(prompt: message);
//     return secret.interact();
//   }
//
//   /// Prompts the user for a yes/no confirmation.
//   @override
//   bool confirm(String message, {bool defaultValue = false}) {
//     final confirmation = Confirm(
//       prompt: message,
//       defaultValue: defaultValue,
//     );
//     return confirmation.interact();
//   }
//
//   /// Prompts the user to select one option from a list.
//   /// Returns the selected option's string value.
//   @override
//   String select(String message, {required List<String> options, String? defaultValue}) {
//     if (options.isEmpty) {
//       throw ArgumentError('Options list cannot be empty for select prompt.');
//     }
//     final selection = Select(
//       prompt: message,
//       options: options,
//       // interact package expects index for defaultValue, so we find it
//       initialIndex: defaultValue != null ? options.indexOf(defaultValue) : 0,
//     );
//     return options[selection.interact()];
//   }
//
//   /// Prompts the user to select multiple options from a list using checkboxes.
//   /// Returns a list of selected option strings.
//   @override
//   List<String> multiSelect(String message, {required List<String> options, List<String>? defaultSelection}) {
//     if (options.isEmpty) {
//       return [];
//     }
//     final defaultIndices = defaultSelection?.map((s) => options.indexOf(s)).where((i) => i != -1).toList();
//
//     final multiSelection = MultiSelect(
//       prompt: message,
//       options: options,
//       defaults: defaultIndices?.cast<bool>().toList(), // This might need adjustment based on interact's API for defaults
//       // The `defaults` parameter for MultiSelect expects List<bool>
//       // Let's make a mapping:
//     );
//
//     // Correctly map defaultSelection strings to a List<bool> for MultiSelect's defaults
//     List<bool> defaultBooleans = List.filled(options.length, false);
//     if (defaultSelection != null) {
//       for (String selectedItem in defaultSelection) {
//         int index = options.indexOf(selectedItem);
//         if (index != -1) {
//           defaultBooleans[index] = true;
//         }
//       }
//     }
//
//     final selectedIndices = multiSelection.interact();
//     return selectedIndices.map((index) => options[index]).toList();
//   }
//
//   /// Shows a spinner/loader while an asynchronous [task] is running.
//   ///
//   /// [inProgressMessage] is displayed next to the spinner while the task executes.
//   /// [completionMessage] (optional) is displayed when the task completes successfully.
//   /// If [completionMessage] is null, a default "inProgressMessage Complete!" will be used.
//   @override
//   Future<T> withSpinner<T>({
//     required String inProgressMessage,
//     String? completionMessage,
//     required Future<T> Function() task,
//   }) async {
//     // Determine the final message to show upon successful completion.
//     final String finalCompletionMessage = completionMessage ?? '$inProgressMessage Complete!';
//
//     // Initialize the spinner from package:interact.
//     // The .interact() method starts the spinner and returns a SpinnerState object
//     // which we use to control the spinner (mark as done or failed).
//     final interact.SpinnerState spinnerState = interact.Spinner(
//       // The rightPrompt callback determines the text displayed.
//       // It receives a boolean `done` which is true when spinnerState.done() or .failed() is called.
//       rightPrompt: (bool taskIsFinished) {
//         if (taskIsFinished) {
//           return ' $finalCompletionMessage'; // Text when task is done
//         } else {
//           // Text while task is in progress. Note the trailing spaces to make room for
//           // the spinner characters that will be prepended by the interact package.
//           return ' $inProgressMessage  ';
//         }
//       },
//       // Customize the icon shown when the spinner is marked as 'done'.
//       icon: '✅',
//
//       // Optional: Provide a custom animation sequence if you don't like the default.
//       // sequence: const ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'], // Example Braille spinner
//     ).interact();
//
//     T result = await task();
//     spinnerState.done();
//     return result;
//   }
//
//   @override
//   Future<List?> promptForm(String formTitle, List<FormFieldDescriptor> fields) {
//     // TODO: implement promptForm
//     throw UnimplementedError();
//   }
// }
//
// // Optional global instance or inject it.
// // final cliInput = CliInput();