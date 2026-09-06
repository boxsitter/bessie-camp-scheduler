import 'package:bessie/src/cli/cli.dart';
import 'package:flutter/material.dart';

class DynamicTextFormField extends StatelessWidget {
  final TextFormFieldDescriptor descriptor;
  final Function(String?) onSaved;
  final String? initialValue;

  const DynamicTextFormField({
    super.key,
    required this.descriptor,
    required this.onSaved,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    // Replaced ShadInputFormField with standard TextFormField.
    return Material(
      type: MaterialType.transparency,
      child: TextFormField(
      // The 'decoration' property is used to configure the label, hint text, etc.
      decoration: InputDecoration(
        labelText: descriptor.label,
        hintText: descriptor.hintText,
        border: const OutlineInputBorder(),
      ),
      initialValue: initialValue ?? descriptor.defaultValue ?? '',
      obscureText: descriptor.isPassword,
      validator: (value) {
        if (descriptor.isRequired && (value == null || value.isEmpty) && !descriptor.allowEmpty) {
          return '${descriptor.label} is required.';
        }
        if (descriptor.validator != null) {
          final error = descriptor.validator!(value);
          if (error is String) return error;
        }
        return null;
      },
      onSaved: onSaved,
      ),
    );
  }
}

class DynamicBooleanFormField extends StatelessWidget {
  final BooleanFormFieldDescriptor descriptor;
  final Function(bool?) onSaved;
  final bool? initialValue;

  const DynamicBooleanFormField({
    super.key,
    required this.descriptor,
    required this.onSaved,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    // Replaced ShadCheckboxFormField with a FormField wrapping a SwitchListTile.
    return Material(
      type: MaterialType.transparency,
      child: FormField<bool>(
      initialValue: initialValue ?? descriptor.defaultValue ?? false,
      onSaved: onSaved,
      builder: (FormFieldState<bool> field) {
        return SwitchListTile(
          title: Text(descriptor.label),
          value: field.value ?? false,
          onChanged: (bool value) {
            field.didChange(value);
          },
        );
      },
      ),
    );
  }
}

class DynamicSelectFormField<T> extends StatelessWidget {
  final SelectFormFieldDescriptor<T> descriptor;
  final Function(T?) onSaved;

  const DynamicSelectFormField({
    super.key,
    required this.descriptor,
    required this.onSaved,
  });

  @override
  Widget build(BuildContext context) {
    // FIX: Wrap the DropdownButtonFormField in a Material widget.
    // This provides the necessary ancestor for Material widgets to draw correctly,
    // resolving the error when this field is used inside a non-Material dialog.
    return Material(
        // Setting the type to transparency ensures it doesn't add any unwanted background color.
        type: MaterialType.transparency,
        child: DropdownButtonFormField<T>(
          decoration: InputDecoration(
            labelText: descriptor.label,
            border: const OutlineInputBorder(),
          ),
          value: descriptor.defaultValue,
          items: descriptor.options.map((opt) {
            return DropdownMenuItem<T>(
              value: opt,
              child: Text(descriptor.optionLabelBuilder(opt)),
            );
          }).toList(),
          onChanged: (T? newValue) {
            onSaved(newValue);
          },
          validator: (value) {
            if (descriptor.isRequired && value == null) {
              return '${descriptor.label} is required.';
            }
            if (descriptor.validator != null) {
              final error = descriptor.validator!(value);
              if (error is String) return error;
            }
            return null;
          },
          onSaved: onSaved,
      ),
    );
  }
}

class DynamicMultiSelectFormField<T> extends StatelessWidget {
  final MultiSelectFormFieldDescriptor<T> descriptor;
  final Function(List<T>?) onSaved;

  const DynamicMultiSelectFormField({
    super.key,
    required this.descriptor,
    required this.onSaved,
  });

  @override
  Widget build(BuildContext context) {
    return FormField<List<T>>(
      onSaved: onSaved,
      initialValue: descriptor.defaultValue ?? [],
      validator: (List<T>? value) {
        if (descriptor.isRequired && (value == null || value.isEmpty)) {
          return '${descriptor.label} is required.';
        }
        if (descriptor.validator != null) {
          final error = descriptor.validator!(value);
          if (error is String) return error;
        }
        return null;
      },
      builder: (FormFieldState<List<T>> field) {
        // FIX: Wrap the InkWell in a Material widget.
        // This provides the necessary ancestor for the InkWell to render its
        // ripple effect, resolving the error when used in a non-Material dialog.
        return Material(
          type: MaterialType.transparency,
          child: InkWell(
          onTap: () async {
            final List<T>? result = await showDialog<List<T>>(
              context: context,
              builder: (BuildContext context) {
                return _MultiSelectDialog(
                  options: descriptor.options,
                  initialValue: field.value ?? [],
                  optionLabelBuilder: descriptor.optionLabelBuilder,
                  title: descriptor.label,
                );
              },
            );

            if (result != null) {
              field.didChange(result);
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: descriptor.label,
              border: const OutlineInputBorder(),
              errorText: field.errorText,
            ),
            child: (field.value?.isEmpty ?? true)
                ? const Text('Select multiple...', style: TextStyle(color: Colors.black54))
                : Text(field.value!.map((item) => descriptor.optionLabelBuilder(item)).join(', ')),
          ),
          ),
        );
      },
    );
  }
}

// NOTE: The _MultiSelectDialog helper class does not need any changes.
// It is included here for completeness.
class _MultiSelectDialog<T> extends StatefulWidget {
  final List<T> options;
  final List<T> initialValue;
  final String Function(T) optionLabelBuilder;
  final String title;

  const _MultiSelectDialog({
    required this.options,
    required this.initialValue,
    required this.optionLabelBuilder,
    required this.title,
  });

  @override
  State<_MultiSelectDialog<T>> createState() => _MultiSelectDialogState<T>();
}

class _MultiSelectDialogState<T> extends State<_MultiSelectDialog<T>> {
  late final List<T> _selectedValues;

  @override
  void initState() {
    super.initState();
    _selectedValues = List<T>.from(widget.initialValue);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: ListBody(
          children: widget.options.map((item) {
            return CheckboxListTile(
              title: Text(widget.optionLabelBuilder(item)),
              value: _selectedValues.contains(item),
              onChanged: (bool? checked) {
                setState(() {
                  if (checked == true) {
                    _selectedValues.add(item);
                  } else {
                    _selectedValues.remove(item);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text('OK'),
          onPressed: () {
            Navigator.of(context).pop(_selectedValues);
          },
        ),
      ],
    );
  }
}
