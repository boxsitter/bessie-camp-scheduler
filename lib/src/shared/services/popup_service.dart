import 'dart:math';

import 'package:bessie/src/shared/constants/sizes.dart';
import 'package:bessie/src/shared/utils/helpers/helper_functions.dart';
import 'package:bessie/src/shared/widgets/loaders/circular_loader.dart';
import 'package:bessie/src/cli/cli.dart';
import 'package:bessie/src/ember_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/colors.dart';
import '../styles/text_styles.dart';
import '../widgets/form_inputs/dynamic_form_fields.dart';

class PopupService extends GetxService {

  Future<bool> showFullScreenDialog({
    String? title,
    String? description,
    List<Widget>? actions,
    Widget? child,
  }) async {
    return await Get.dialog<bool>(
      ShadDialog(
        title: title != null ? Text(title) : null,
        description: description != null ? Text(description) : null,
        actions: actions ?? [],
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 200),
    ) ??
    false;
  }

  Future<bool> showConfirmationDialog({
    String? title,
    String? message,
  }) async {
    return await showFullScreenDialog(
      title: title,
      description: message,
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false), // Return false on cancel
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Get.back(result: true), // Return true on confirm
          child: Text('Confirm'),
        ),
      ],
      child: null,
    );
  }

  /// Shows a dialog for selecting one or more options from a list.
  ///
  /// Args:
  ///   [title]: The title of the dialog.
  ///   [message]: A descriptive message for the dialog.
  ///   [options]: The list of string options to display.
  ///   [defaultSelections]: A list of options that should be pre-selected.
  ///                      For single selection mode, only the first item in this list is considered.
  ///   [allowMultipleSelections]: If true, uses checkboxes for multiple selections.
  ///                              If false, uses a dropdown (ShadSelect) for single selection.
  ///
  /// Returns:
  ///   A list of selected option strings.
  ///   If single selection mode and no selection is made or dialog cancelled,
  ///   it attempts to return the default or an empty list.
  ///   If multiple selection mode and cancelled, returns an empty list.
  Future<List<String>> showOptionSelectionDialog({
    required String title,
    required String message,
    required List<String> options,
    List<String>? defaultSelections, // Can be used for both single (first item) and multi
    bool allowMultipleSelections = false,
  }) async {
    if (options.isEmpty) {
      return []; // No options to select from
    }

    // For single selection (ShadSelect)
    RxString singleSelectedValue = ''.obs;
    if (!allowMultipleSelections) {
      String? initialSingleSelection = defaultSelections?.isNotEmpty == true && options.contains(defaultSelections!.first)
          ? defaultSelections.first
          : (options.isNotEmpty ? options.first : null);
      if (initialSingleSelection == null && options.isNotEmpty) {
        initialSingleSelection = options.first;
      }
      singleSelectedValue.value = initialSingleSelection ?? ""; // Ensure it's not null for ShadSelect if "" is not a valid option.
      // Or handle null initialValue in ShadSelect if it supports it.
    }

    // For multiple selections (Checkboxes)
    RxList<String> multiSelectedValues = RxList<String>.from(
      defaultSelections?.where((s) => options.contains(s)).toList() ?? <String>[],
    );

    Widget selectionWidget;
    if (allowMultipleSelections) {
      selectionWidget = Container(
        width: 350, // Adjust width as needed
        constraints: BoxConstraints(maxHeight: Get.height * 0.5), // Limit height
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: options.length,
          itemBuilder: (context, index) {
            final option = options[index];
            return Obx(() => ShadCheckbox(
              label: Text(option),
              value: multiSelectedValues.contains(option),
              onChanged: (isChecked) {
                if (isChecked == true) {
                  if (!multiSelectedValues.contains(option)) {
                    multiSelectedValues.add(option);
                  }
                } else {
                  multiSelectedValues.remove(option);
                }
              },
            ));
          },
        ),
      );
    } else {
      // Single Selection using ShadSelect
      if (singleSelectedValue.value.isEmpty && options.isNotEmpty) {
        // Ensure a default is picked if current singleSelectedValue is empty (placeholder)
        // and there are options. This is important if ShadSelect requires a non-null initialValue
        // that's part of the options.
        singleSelectedValue.value = options.first;
      }
      selectionWidget = Container(
        padding: const EdgeInsets.symmetric(vertical: BessSizes.spaceBtwItems), //
        width: 300, // Adjust width as needed
        child: ShadSelect<String>(
          selectedOptionBuilder: (context, value) => Text(value.isNotEmpty ? value : "Select..."), // Handle empty string case
          placeholder: const Text('Select an option'),
          initialValue: singleSelectedValue.value,
          options: options
              .map((option) => ShadOption<String>(
            value: option,
            child: Text(option),
          ))
              .toList(),
          onChanged: (value) {
            singleSelectedValue.value = value!;
          },
        ),
      );
    }

    bool? dialogResult = await showFullScreenDialog(
      title: title,
      description: message,
      child: selectionWidget,
      actions: [
        ShadButton.outline(
          child: const Text('Cancel'),
          onPressed: () => Get.back(result: false),
        ),
        ShadButton(
          child: const Text('Confirm'),
          onPressed: () => Get.back(result: true),
        ),
      ],
    );

    if (dialogResult == true) {
      if (allowMultipleSelections) {
        return multiSelectedValues.toList();
      } else {
        // For single selection, if singleSelectedValue.value is empty (e.g. placeholder was shown and not changed)
        // and a selection is mandatory per UserInput, this might need adjustment.
        // However, UserInput.select expects a String, not List<String>.
        // This unified dialog returns List<String>. The adapter (GuiInput) will handle this.
        return singleSelectedValue.value.isNotEmpty ? [singleSelectedValue.value] : [];
      }
    }
    // User cancelled or closed dialog, return empty list to satisfy Future<List<String>>
    // The caller (GuiInput) will need to adapt this for UserInput.select (single string)
    return [];
  }

  Future<T> executeWithSpinner<T>({
    required String inProgressMessage,
    String? title,
    required Future<T> Function() task,
  }) async {
    Get.dialog(
      ShadDialog(
        title: title != null ? Text(title) : null,
        description: Text(inProgressMessage),
        child: const Padding(
          padding: EdgeInsets.all(BessSizes.lg), //
          child: Center(child: BessCircularLoader()),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      final result = await task();
      if (Get.isDialogOpen == true) {
        Get.back();
      }
      return result;
    } catch (e) {
      if (Get.isDialogOpen == true) {
        Get.back();
      }
      rethrow;
    }
  }

  void showToast({
    String? title,
    String? message,
    Widget? action,
    LogType? logType
  }){
    final sonner = ShadSonner.of(Get.context!);
    final id = Random().nextInt(1000);
    final Color? color;
    switch(logType) {
      case LogType.success:
        color = BessColors.success;
        break;
      case LogType.error:
        color = BessColors.error;
        break;
      case LogType.warning:
        color = BessColors.warning;
        break;
      case LogType.critical:
        color = BessColors.error;
        break;
      case LogType.unknownError:
        color = BessColors.error;
        break;
      case LogType.failure:
        color = BessColors.warning;
        break;
      default:
        color = null;
    }

    sonner.show(
      ShadToast(
        showCloseIconOnlyWhenHovered: false,
        duration: logType?.toastDuration ?? const Duration(milliseconds: 2500),
        id: id,
        title: title != null ? Text(title) : null,
        description: message != null ?
          Column(
            children: [
              SizedBox(height: 6),

              Text(message),
            ],
          )
            : null,
        action: action,
        padding: EdgeInsets.fromLTRB(24, 24, 32, 24),
        radius: BorderRadius.circular(BessSizes.cardRadiusMd),
        backgroundColor: color != null ? BessHelperFunctions.blendColors(color, BessColors.core, 225) : BessColors.core,
        border: Border.all(width: 2, color: color != null ? color : BessColors.borderPrimary),
        titleStyle: BessTextStyles.tableHeader.copyWith(fontSize: 16),
        descriptionStyle:  BessTextStyles.standard,
      ),
    );
  }

  Future<bool> showActivityInfo(PrincipalActivity activity) async {
    return await showFullScreenDialog(
      title: activity.name,
      description: activity.description,
    );
  }

  Future<List<dynamic>?> showDynamicFormDialog({
    required String title,
    required List<FormFieldDescriptor> fields,
    String confirmButtonText = 'Submit',
    String cancelButtonText = 'Cancel',
  }) async {
    final formKey = GlobalKey<FormState>();
    // Use a List to store the current values of the form fields, in order.
    // Initialize with nulls or default values.
    final List<dynamic> formValues = List<dynamic>.filled(fields.length, null, growable: false);

    // Initialize formValues with defaultValues from descriptors
    for (int i = 0; i < fields.length; i++) {
      final field = fields[i];
      formValues[i] = field.defaultValue;
      // if (field is MultiSelectFormFieldDescriptor && field.defaultValue != null) {
      //   formValues[i] = List.from(field.defaultValue as List);
      // }
    }

    List<Widget> buildFormWidgets() {
      List<Widget> widgets = [];
      for (int i = 0; i < fields.length; i++) {
        final field = fields[i];
        Widget fieldWidget;

        // It's important that onSaved captures the index 'i' correctly.
        final currentIndex = i;

        if (field is TextFormFieldDescriptor) {
          fieldWidget = DynamicTextFormField(
            descriptor: field,
            initialValue: formValues[currentIndex] as String?,
            onSaved: (value) => formValues[currentIndex] = value,
          );
        } else if (field is BooleanFormFieldDescriptor) {
          fieldWidget = DynamicBooleanFormField(
            descriptor: field,
            initialValue: formValues[currentIndex] as bool?,
            onSaved: (value) => formValues[currentIndex] = value,
          );
        } else if (field is SelectFormFieldDescriptor) {
          fieldWidget = DynamicSelectFormField(
            descriptor: field,
            onSaved: (value) => formValues[currentIndex] = value,
          );
        } else if (field is MultiSelectFormFieldDescriptor) {
          fieldWidget = DynamicMultiSelectFormField(
            descriptor: field,
            onSaved: (value) => formValues[currentIndex] = value,
          );
        } else {
          fieldWidget = Text('Unsupported field type: ${field.runtimeType}');
        }
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: fieldWidget,
        ));
      }
      return widgets;
    }

    final bool? success = await Get.dialog<bool>(
      ShadDialog(
        title: Text(title),
        description: const Text('Please fill in the details below.'),
        child: Container(
          width: Get.width * 0.8,
          constraints: BoxConstraints(maxHeight: Get.height * 0.7),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: buildFormWidgets(),
              ),
            ),
          ),
        ),
        actions: [
          ShadButton.outline(
            child: Text(cancelButtonText),
            onPressed: () => Get.back(result: false),
          ),
          ShadButton(
            child: Text(confirmButtonText),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                Get.back(result: true);
              }
            },
          ),
        ],
      ),
      barrierDismissible: false,
    );

    if (success == true) {
      return formValues; // Returns the ordered list of values
    }
    return null; // User cancelled
  }

}
