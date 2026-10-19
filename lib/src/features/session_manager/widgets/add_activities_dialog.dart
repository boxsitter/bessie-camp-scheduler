import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../models/schedule.dart';
import '../../../shared/constants/sizes.dart';
import '../../../shared/styles/text_styles.dart';
import '../../branch_manager/catalog_logic.dart';
import '../../branch_manager/widgets/catalog_rows.dart';
import '../session_setup_logic.dart';

/// Picks activities to offer during [block]. Closes with the chosen activity
/// ids (never an empty list), or null when cancelled.
class AddActivitiesDialog extends StatefulWidget {
  const AddActivitiesDialog({super.key, required this.block, required this.groups});

  final Block block;

  /// What can still be added, in the order to show it.
  final List<ActivityChoiceGroup> groups;

  @override
  State<AddActivitiesDialog> createState() => _AddActivitiesDialogState();
}

class _AddActivitiesDialogState extends State<AddActivitiesDialog> {
  final Set<String> _selected = {};

  void _set(Iterable<String> ids, bool selected) => setState(() => selected ? _selected.addAll(ids) : _selected.removeAll(ids));

  @override
  Widget build(BuildContext context) {
    return ShadDialog(
      title: const Text('Add activities'),
      description: Text('${widget.block.displayTitle}, ${formatBlockTimes(widget.block)}'),
      constraints: const BoxConstraints(maxWidth: 520),
      scrollable: true,
      actions: [
        ShadButton.secondary(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ShadButton(
          onPressed: _selected.isEmpty ? null : () => Navigator.of(context).pop(_selected.toList()),
          child: Text(_selected.isEmpty ? 'Add' : 'Add ${pluralize(_selected.length, 'activity', 'activities')}'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final group in widget.groups) ...[
            Row(
              children: [
                Expanded(child: GroupHeading(label: group.title, detail: '${group.activities.length}')),
                ShadButton.ghost(
                  size: ShadButtonSize.sm,
                  onPressed: () => _set([for (final a in group.activities) a.id], !group.activities.every((a) => _selected.contains(a.id))),
                  child: Text(group.activities.every((a) => _selected.contains(a.id)) ? 'Clear' : 'Select all'),
                ),
              ],
            ),
            for (final activity in group.activities)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: BessSizes.xs),
                child: ShadCheckbox(
                  value: _selected.contains(activity.id),
                  onChanged: (checked) => _set([activity.id], checked),
                  label: Text(activity.name),
                  sublabel: Text('${activity.category.title}, capacity ${activity.capacity}', style: BessTextStyles.label),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
