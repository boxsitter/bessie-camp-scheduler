import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../models/cabin.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/sizes.dart';
import '../../../shared/styles/text_styles.dart';
import '../catalog_logic.dart';
import 'catalog_rows.dart';
import 'pill.dart';
import 'section_card.dart';

/// The branch's cabins grouped by village, with create/delete for people who
/// may change session data.
class CabinsCatalogSection extends StatelessWidget {
  const CabinsCatalogSection({super.key, required this.cabins, required this.canEdit, required this.onCreate, required this.onDelete});

  final List<Cabin> cabins;
  final bool canEdit;
  final VoidCallback onCreate;
  final ValueChanged<Cabin> onDelete;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Cabins',
      subtitle: '${pluralize(cabins.length, 'cabin')} in the branch. Register them for a session on the session setup page.',
      trailing: canEdit
          ? ShadButton(size: ShadButtonSize.sm, leading: const Icon(LucideIcons.plus, size: 16), onPressed: onCreate, child: const Text('New cabin'))
          : null,
      child: cabins.isEmpty
          ? Text(canEdit ? 'No cabins yet. Create the first one.' : 'No cabins yet.', style: BessTextStyles.standardSecondary)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final group in groupCabinsByVillage(cabins)) ...[
                  GroupHeading(label: group.label, detail: '${pluralize(group.cabins.length, 'cabin')}, sleeps ${group.capacity}'),
                  for (final cabin in group.cabins) _CabinRow(cabin: cabin, canEdit: canEdit, onDelete: () => onDelete(cabin)),
                ],
              ],
            ),
    );
  }
}

class _CabinRow extends StatelessWidget {
  const _CabinRow({required this.cabin, required this.canEdit, required this.onDelete});

  final Cabin cabin;
  final bool canEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return CatalogRow(
      content: Wrap(
        spacing: BessSizes.sm,
        runSpacing: BessSizes.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(cabin.title, style: BessTextStyles.standardBold),
          if (cabin.displayName != null) Text('(${cabin.name})', style: BessTextStyles.standardSecondary),
          Pill('Sleeps ${cabin.capacity}'),
        ],
      ),
      actions: [
        if (canEdit) RowIconButton(icon: LucideIcons.trash2, tooltip: 'Delete ${cabin.title}', color: BessColors.error, onPressed: onDelete),
      ],
    );
  }
}
