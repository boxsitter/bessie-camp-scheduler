import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../models/organization.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/sizes.dart';
import '../../branch_manager/widgets/form_widgets.dart';
import '../session_setup_logic.dart';
import 'limits_section.dart';

/// Creates a session in the current season. [onSubmit] creates it; if that
/// throws, the dialog stays open and shows why (for example a duplicate name).
class NewSessionDialog extends StatefulWidget {
  const NewSessionDialog({
    super.key,
    required this.existingNames,
    required this.season,
    required this.initialStart,
    required this.initialLimits,
    required this.onSubmit,
  });

  /// The names of the season's sessions, which the new one must not repeat.
  final List<String> existingNames;
  final Season? season;
  final DateTime initialStart;
  final LimitsDraft initialLimits;
  final Future<void> Function(NewSessionRequest request) onSubmit;

  @override
  State<NewSessionDialog> createState() => _NewSessionDialogState();
}

class _NewSessionDialogState extends State<NewSessionDialog> {
  final _name = TextEditingController();
  late DateTime? _startsOn = widget.initialStart;
  late LimitsDraft _limits = widget.initialLimits;
  bool _registerAllCabins = true;

  NewSessionErrors _errors = const NewSessionErrors();
  bool _validateOnChange = false;
  bool _busy = false;
  String? _submitError;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  NewSessionErrors _validate() => validateNewSession(name: _name.text, startsOn: _startsOn, existingNames: widget.existingNames);

  void _revalidate() {
    if (_validateOnChange) setState(() => _errors = _validate());
  }

  Future<void> _submit() async {
    final errors = _validate();
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
    final request = NewSessionRequest(
      name: _name.text.trim(),
      startsOn: _startsOn!,
      limits: _limits,
      registerAllCabins: _registerAllCabins,
    );
    final failure = await submitCatching(() => widget.onSubmit(request));
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
    const gap = SizedBox(height: BessSizes.md);
    final startsOn = _startsOn;
    return ShadDialog(
      title: const Text('New session'),
      description: const Text('The session starts with the branch\'s weekly block template and no activities scheduled.'),
      constraints: const BoxConstraints(maxWidth: 520),
      scrollable: true,
      actions: formDialogActions(context, submitLabel: 'Create session', onSubmit: _submit, busy: _busy),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: BessSizes.sm),
          LabeledField(
            label: 'Name',
            error: _errors.name,
            child: ShadInput(
              controller: _name,
              autofocus: true,
              placeholder: const Text('e.g. Session 3'),
              onChanged: (_) => _revalidate(),
            ),
          ),
          gap,
          LabeledField(
            label: 'First day',
            error: _errors.startsOn,
            hint: startsOn == null ? null : outsideSeasonWarning(startsOn, widget.season),
            child: ShadDatePicker(
              selected: startsOn,
              initialMonth: startsOn,
              placeholder: const Text('Pick a date'),
              formatDate: DateFormat.yMMMEd().format,
              // The app's outline buttons are red; a date is not a warning.
              foregroundColor: BessColors.textPrimary,
              hoverForegroundColor: BessColors.textPrimary,
              hoverBackgroundColor: BessColors.crust,
              onChanged: (date) {
                setState(() => _startsOn = date == null ? null : DateTime(date.year, date.month, date.day));
                _revalidate();
              },
            ),
          ),
          gap,
          LabeledField(
            label: 'Preference limits',
            child: LimitsEditor(draft: _limits, onChanged: (limits) => setState(() => _limits = limits)),
          ),
          gap,
          ShadSwitch(
            value: _registerAllCabins,
            onChanged: (value) => setState(() => _registerAllCabins = value),
            label: const Text('Register all cabins'),
            sublabel: const Text('Untick to choose the session\'s cabins afterwards.'),
          ),
          if (_submitError != null) ...[gap, FormMessage(_submitError!, isError: true)],
        ],
      ),
    );
  }
}
