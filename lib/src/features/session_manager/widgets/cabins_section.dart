import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../models/cabin.dart';
import '../../../shared/constants/sizes.dart';
import '../../../shared/styles/text_styles.dart';
import '../../branch_manager/catalog_logic.dart';
import '../../branch_manager/widgets/catalog_rows.dart';
import '../../branch_manager/widgets/pill.dart';
import '../../branch_manager/widgets/section_card.dart';
import '../session_setup_logic.dart';

/// Which of the branch's cabins the session uses.
class SessionCabinsSection extends StatelessWidget {
  const SessionCabinsSection({
    super.key,
    required this.setup,
    required this.selected,
    required this.canEdit,
    required this.busy,
    required this.onToggle,
    required this.onSetMany,
    required this.onSave,
    required this.onReset,
  });

  final SessionSetup setup;

  /// The cabin ids ticked right now (saved or not).
  final Set<String> selected;
  final bool canEdit;
  final bool busy;
  final ValueChanged<String> onToggle;
  final void Function(Iterable<String> cabinIds, bool selected) onSetMany;
  final VoidCallback onSave;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final change = diffCabinSelection(registered: setup.registeredCabinIds, selected: selected, campersByCabin: setup.campersByCabin);
    return SectionCard(
      title: 'Cabins',
      subtitle: canEdit
          ? 'Tick the cabins this session uses. Campers can only be placed in cabins that are ticked.'
          : 'The cabins this session uses.',
      child: setup.cabins.isEmpty
          ? Text('The branch has no cabins yet. Add some on the branch catalog page.', style: BessTextStyles.standardSecondary)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final group in groupCabinsByVillage(setup.cabins)) ...[
                  _VillageHeading(group: group, selected: selected, canEdit: canEdit, onSetMany: onSetMany),
                  for (final cabin in group.cabins)
                    _CabinRow(setup: setup, cabin: cabin, checked: selected.contains(cabin.id), canEdit: canEdit, onToggle: () => onToggle(cabin.id)),
                ],
                if (canEdit) ...[
                  const SizedBox(height: BessSizes.md),
                  _SaveBar(change: change, busy: busy, onSave: onSave, onReset: onReset),
                ],
              ],
            ),
    );
  }
}

class _VillageHeading extends StatelessWidget {
  const _VillageHeading({required this.group, required this.selected, required this.canEdit, required this.onSetMany});

  final VillageGroup group;
  final Set<String> selected;
  final bool canEdit;
  final void Function(Iterable<String> cabinIds, bool selected) onSetMany;

  @override
  Widget build(BuildContext context) {
    final ids = [for (final cabin in group.cabins) cabin.id];
    final allSelected = ids.every(selected.contains);
    return Row(
      children: [
        Expanded(
          child: GroupHeading(label: group.label, detail: '${ids.where(selected.contains).length} of ${ids.length} ticked'),
        ),
        if (canEdit)
          ShadButton.ghost(size: ShadButtonSize.sm, onPressed: () => onSetMany(ids, !allSelected), child: Text(allSelected ? 'Clear' : 'Tick all')),
      ],
    );
  }
}

class _CabinRow extends StatelessWidget {
  const _CabinRow({required this.setup, required this.cabin, required this.checked, required this.canEdit, required this.onToggle});

  final SessionSetup setup;
  final Cabin cabin;
  final bool checked;
  final bool canEdit;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final registered = setup.registeredCabinIds.contains(cabin.id);
    final campers = setup.campersByCabin[cabin.id] ?? 0;
    return CatalogRow(
      content: Row(
        children: [
          Expanded(
            child: ShadCheckbox(value: checked, onChanged: canEdit ? (_) => onToggle() : null, label: Text(cabin.title)),
          ),
          if (registered && !checked && campers > 0)
            Pill('${pluralize(campers, 'camper')} will lose this cabin', tone: PillTone.danger)
          else if (registered)
            Pill('$campers of ${cabin.capacity} campers', tone: campers > cabin.capacity ? PillTone.warning : PillTone.neutral)
          else
            Pill('Sleeps ${cabin.capacity}'),
        ],
      ),
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.change, required this.busy, required this.onSave, required this.onReset});

  final CabinSelectionChange change;
  final bool busy;
  final VoidCallback onSave;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(_summary(change), style: BessTextStyles.standardSecondary)),
        ShadButton.secondary(onPressed: change.isEmpty || busy ? null : onReset, child: const Text('Reset')),
        const SizedBox(width: BessSizes.sm),
        ShadButton(onPressed: change.isEmpty || busy ? null : onSave, child: Text(busy ? 'Saving...' : 'Save cabins')),
      ],
    );
  }

  static String _summary(CabinSelectionChange change) {
    if (change.isEmpty) return 'No changes.';
    final parts = [
      if (change.added.isNotEmpty) '${pluralize(change.added.length, 'cabin')} added',
      if (change.removed.isNotEmpty) '${pluralize(change.removed.length, 'cabin')} removed',
    ];
    final left = change.campersLeftWithoutCabin;
    return left > 0 ? '${parts.join(', ')}. ${pluralize(left, 'camper')} will be left without a cabin.' : '${parts.join(', ')}.';
  }
}
