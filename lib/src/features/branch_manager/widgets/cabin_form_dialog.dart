import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../models/cabin.dart';
import '../../../shared/constants/sizes.dart';
import '../catalog_logic.dart';
import 'form_widgets.dart';

/// Adds a cabin to the branch. [onSubmit] stores it; if it throws, the dialog
/// stays open and shows why.
class CabinFormDialog extends StatefulWidget {
  const CabinFormDialog({super.key, required this.existingCabins, required this.onSubmit});

  final List<Cabin> existingCabins;
  final Future<void> Function(CabinFormInput input) onSubmit;

  @override
  State<CabinFormDialog> createState() => _CabinFormDialogState();
}

class _CabinFormDialogState extends State<CabinFormDialog> {
  final _name = TextEditingController();
  final _displayName = TextEditingController();
  final _village = TextEditingController();
  final _capacity = TextEditingController(text: '10');

  CabinFormErrors _errors = const CabinFormErrors();
  bool _validateOnChange = false;
  bool _busy = false;
  String? _submitError;

  late final List<String> _villages = [
    for (final group in groupCabinsByVillage(widget.existingCabins))
      if (group.village.isNotEmpty) group.village,
  ];

  @override
  void dispose() {
    _name.dispose();
    _displayName.dispose();
    _village.dispose();
    _capacity.dispose();
    super.dispose();
  }

  CabinFormInput get _input =>
      CabinFormInput(name: _name.text, displayName: _displayName.text, village: _village.text, capacity: _capacity.text);

  void _revalidate() {
    if (_validateOnChange) setState(() => _errors = validateCabinForm(_input, existing: widget.existingCabins));
  }

  Future<void> _submit() async {
    final errors = validateCabinForm(_input, existing: widget.existingCabins);
    if (errors.hasErrors) {
      setState(() {
        _validateOnChange = true;
        _errors = errors;
      });
      return;
    }
    setState(() {
      _busy = true;
      _submitError = null;
    });
    final failure = await submitCatching(() => widget.onSubmit(_input));
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _busy = false;
        _submitError = failure;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: BessSizes.ms);
    return ShadDialog(
      title: const Text('New cabin'),
      description: const Text('Add a cabin to the branch. Register it for a session on the session setup page.'),
      constraints: const BoxConstraints(maxWidth: 480),
      scrollable: true,
      actions: formDialogActions(context, submitLabel: 'Create cabin', onSubmit: _submit, busy: _busy),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: BessSizes.sm),
          LabeledField(
            label: 'Name',
            error: _errors.name,
            child: ShadInput(controller: _name, autofocus: true, placeholder: const Text('e.g. Oak'), onChanged: (_) => _revalidate()),
          ),
          gap,
          LabeledField(
            label: 'Display name',
            error: _errors.displayName,
            hint: 'Optional. Shown instead of the name.',
            child: ShadInput(controller: _displayName, onChanged: (_) => _revalidate()),
          ),
          gap,
          LabeledField(
            label: 'Village',
            hint: 'Optional. Cabins in the same village are listed together.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShadInput(controller: _village, placeholder: const Text('e.g. Pines')),
                if (_villages.isNotEmpty) ...[
                  const SizedBox(height: BessSizes.sm),
                  Wrap(
                    spacing: BessSizes.sm,
                    runSpacing: BessSizes.sm,
                    children: [
                      for (final village in _villages)
                        ShadButton.secondary(size: ShadButtonSize.sm, onPressed: () => _village.text = village, child: Text(village)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          gap,
          LabeledField(
            label: 'Capacity',
            error: _errors.capacity,
            hint: 'Campers the cabin sleeps.',
            child: ShadInput(
              controller: _capacity,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => _revalidate(),
            ),
          ),
          if (_submitError != null) ...[gap, FormMessage(_submitError!, isError: true)],
        ],
      ),
    );
  }
}
