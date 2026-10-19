import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/errors.dart';
import '../../../core/logging.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/sizes.dart';
import '../../../shared/styles/text_styles.dart';

/// Shows a form dialog that must be closed with its own buttons, so that a
/// stray click outside cannot throw away what was typed.
Future<T?> showFormDialog<T>(Widget dialog) => Get.dialog<T>(dialog, barrierDismissible: false);

/// Runs [action] for a dialog's submit button. Returns null on success, or
/// the message to show inside the dialog (and logs what actually happened).
Future<String?> submitCatching(Future<void> Function() action) async {
  try {
    await action();
    return null;
  } catch (e, st) {
    final exception = AppException.from(e, st);
    log.w('Submitting a dialog failed', error: exception.cause ?? exception, stackTrace: st);
    return exception.message;
  }
}

/// Cancel and submit buttons for a [ShadDialog].
List<Widget> formDialogActions(BuildContext context, {required String submitLabel, required VoidCallback onSubmit, bool busy = false}) => [
  ShadButton.secondary(onPressed: busy ? null : () => Navigator.of(context).pop(), child: const Text('Cancel')),
  ShadButton(onPressed: busy ? null : onSubmit, child: Text(busy ? 'Saving...' : submitLabel)),
];

/// A form field with its label above and its problem (or hint) below.
class LabeledField extends StatelessWidget {
  const LabeledField({super.key, required this.label, required this.child, this.error, this.hint});

  final String label;
  final Widget child;
  final String? error;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: BessTextStyles.standardBold),
        const SizedBox(height: BessSizes.sm),
        child,
        if (error != null)
          Padding(padding: const EdgeInsets.only(top: BessSizes.xs), child: FormMessage(error!, isError: true))
        else if (hint != null)
          Padding(padding: const EdgeInsets.only(top: BessSizes.xs), child: FormMessage(hint!)),
      ],
    );
  }
}

/// A line of small text under a field, in the error color when it is a problem.
class FormMessage extends StatelessWidget {
  const FormMessage(this.message, {super.key, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Text(message, style: BessTextStyles.label.copyWith(color: isError ? BessColors.error : BessColors.textSecondary));
  }
}
