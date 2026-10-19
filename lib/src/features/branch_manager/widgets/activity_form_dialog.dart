import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../models/activity.dart';
import '../../../models/enums.dart';
import '../../../shared/constants/sizes.dart';
import '../catalog_logic.dart';
import 'form_widgets.dart';

/// Creates ([activity] null) or edits an activity. [onSubmit] stores the
/// result; if it throws, the dialog stays open and shows why.
class ActivityFormDialog extends StatefulWidget {
  const ActivityFormDialog({super.key, this.activity, required this.otherActivityNames, required this.onSubmit});

  final Activity? activity;

  /// The names of the branch's other activities, which this one must not repeat.
  final List<String> otherActivityNames;
  final Future<void> Function(ActivityFormInput input) onSubmit;

  @override
  State<ActivityFormDialog> createState() => _ActivityFormDialogState();
}

class _ActivityFormDialogState extends State<ActivityFormDialog> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _capacity;
  late final TextEditingController _maxAssignments;
  late ActivityCategory _category;
  late bool _isSkillsRec;
  late bool _doubleSchedule;
  late bool _isHidden;
  late bool _preferenceRequired;

  ActivityFormErrors _errors = const ActivityFormErrors();
  bool _validateOnChange = false;
  bool _busy = false;
  String? _submitError;

  bool get _isEditing => widget.activity != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.activity == null ? const ActivityFormInput(capacity: '10') : ActivityFormInput.fromActivity(widget.activity!);
    _name = TextEditingController(text: initial.name);
    _description = TextEditingController(text: initial.description);
    _capacity = TextEditingController(text: initial.capacity);
    _maxAssignments = TextEditingController(text: initial.maxAssignments);
    _category = initial.category;
    _isSkillsRec = initial.isSkillsRec;
    _doubleSchedule = initial.doubleSchedule;
    _isHidden = initial.isHidden;
    _preferenceRequired = initial.preferenceRequired;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _capacity.dispose();
    _maxAssignments.dispose();
    super.dispose();
  }

  ActivityFormInput get _input => ActivityFormInput(
    name: _name.text,
    description: _description.text,
    capacity: _capacity.text,
    category: _category,
    isSkillsRec: _isSkillsRec,
    doubleSchedule: _doubleSchedule,
    maxAssignments: _maxAssignments.text,
    isHidden: _isHidden,
    preferenceRequired: _preferenceRequired,
  );

  void _revalidate() {
    if (_validateOnChange) setState(() => _errors = validateActivityForm(_input, otherActivityNames: widget.otherActivityNames));
  }

  Future<void> _submit() async {
    final errors = validateActivityForm(_input, otherActivityNames: widget.otherActivityNames);
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
      title: Text(_isEditing ? 'Edit activity' : 'New activity'),
      description: Text(_isEditing ? 'Changes apply to every session that offers it.' : 'Add an activity to the branch catalog.'),
      constraints: const BoxConstraints(maxWidth: 520),
      scrollable: true,
      actions: formDialogActions(context, submitLabel: _isEditing ? 'Save changes' : 'Create activity', onSubmit: _submit, busy: _busy),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: BessSizes.sm),
          LabeledField(
            label: 'Name',
            error: _errors.name,
            child: ShadInput(controller: _name, autofocus: true, placeholder: const Text('e.g. Archery'), onChanged: (_) => _revalidate()),
          ),
          gap,
          LabeledField(
            label: 'Description',
            hint: 'Shown to campers when they choose activities.',
            child: ShadTextarea(controller: _description, minHeight: 64, placeholder: const Text('What happens in this activity?')),
          ),
          gap,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: LabeledField(
                  label: 'Capacity',
                  error: _errors.capacity,
                  hint: 'Campers per block.',
                  child: ShadInput(
                    controller: _capacity,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => _revalidate(),
                  ),
                ),
              ),
              const SizedBox(width: BessSizes.md),
              Expanded(
                child: LabeledField(
                  label: 'Max per camper',
                  error: _errors.maxAssignments,
                  hint: 'Optional. Times in a session.',
                  child: ShadInput(
                    controller: _maxAssignments,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    placeholder: const Text('No limit'),
                    onChanged: (_) => _revalidate(),
                  ),
                ),
              ),
            ],
          ),
          gap,
          LabeledField(
            label: 'Category',
            child: SizedBox(
              width: double.infinity,
              child: ShadSelect<ActivityCategory>(
                initialValue: _category,
                selectedOptionBuilder: (context, category) => Text(category.title),
                options: [for (final category in ActivityCategory.values) ShadOption(value: category, child: Text(category.title))],
                onChanged: (category) {
                  if (category == null) return;
                  setState(() {
                    _isSkillsRec = skillsRecAfterCategoryChange(from: _category, to: category, isSkillsRec: _isSkillsRec);
                    _category = category;
                  });
                },
              ),
            ),
          ),
          gap,
          _SwitchRow(
            label: 'Skills rec',
            description: ActivityBadge.skillsRec.hint,
            value: _isSkillsRec,
            onChanged: (value) => setState(() => _isSkillsRec = value),
          ),
          _SwitchRow(
            label: 'Double block',
            description: ActivityBadge.doubleBlock.hint,
            value: _doubleSchedule,
            onChanged: (value) => setState(() => _doubleSchedule = value),
          ),
          _SwitchRow(
            label: 'Hidden',
            description: ActivityBadge.hidden.hint,
            value: _isHidden,
            onChanged: (value) => setState(() => _isHidden = value),
          ),
          _SwitchRow(
            label: 'Campers rank it',
            description: 'Off for activities campers are placed in without choosing them.',
            value: _preferenceRequired,
            onChanged: (value) => setState(() => _preferenceRequired = value),
          ),
          if (_submitError != null) ...[gap, FormMessage(_submitError!, isError: true)],
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({required this.label, required this.description, required this.value, required this.onChanged});

  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BessSizes.xs),
      child: ShadSwitch(value: value, onChanged: onChanged, label: Text(label), sublabel: Text(description)),
    );
  }
}
