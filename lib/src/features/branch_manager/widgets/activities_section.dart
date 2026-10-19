import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../models/activity.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/sizes.dart';
import '../../../shared/styles/text_styles.dart';
import '../catalog_logic.dart';
import 'catalog_rows.dart';
import 'pill.dart';
import 'section_card.dart';

/// The branch's activities grouped by category, with create/edit/delete for
/// people who may change session data.
class ActivitiesSection extends StatelessWidget {
  const ActivitiesSection({
    super.key,
    required this.activities,
    required this.canEdit,
    required this.onCreate,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Activity> activities;
  final bool canEdit;
  final VoidCallback onCreate;
  final ValueChanged<Activity> onEdit;
  final ValueChanged<Activity> onDelete;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Activities',
      subtitle: '${pluralize(activities.length, 'activity', 'activities')} in the catalog',
      trailing:
          canEdit
              ? ShadButton(
                size: ShadButtonSize.sm,
                leading: const Icon(LucideIcons.plus, size: 16),
                onPressed: onCreate,
                child: const Text('New activity'),
              )
              : null,
      child:
          activities.isEmpty
              ? Text(canEdit ? 'No activities yet. Create the first one.' : 'No activities yet.', style: BessTextStyles.standardSecondary)
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final group in groupActivitiesByCategory(activities)) ...[
                    GroupHeading(label: group.category.title, detail: '${group.activities.length}'),
                    for (final activity in group.activities)
                      _ActivityRow(
                        activity: activity,
                        canEdit: canEdit,
                        onEdit: () => onEdit(activity),
                        onDelete: () => onDelete(activity),
                      ),
                  ],
                ],
              ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity, required this.canEdit, required this.onEdit, required this.onDelete});

  final Activity activity;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final badges = activityBadges(activity);
    return CatalogRow(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: BessSizes.sm,
            runSpacing: BessSizes.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(activity.name, style: BessTextStyles.standardBold),
              for (final badge in badges)
                Pill(badge.label, tone: badge == ActivityBadge.hidden ? PillTone.warning : PillTone.info, tooltip: badge.hint),
              Pill('Capacity ${activity.capacity}'),
              if (activity.maxAssignments != null)
                Pill('Max ${activity.maxAssignments} per camper', tooltip: 'Most times one camper may get it in a session.'),
            ],
          ),
          if (activity.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: BessSizes.xs),
              child: Text(activity.description, style: BessTextStyles.standardSecondary, maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
        ],
      ),
      actions: [
        if (canEdit) ...[
          RowIconButton(icon: LucideIcons.pencil, tooltip: 'Edit ${activity.name}', onPressed: onEdit),
          RowIconButton(icon: LucideIcons.trash2, tooltip: 'Delete ${activity.name}', color: BessColors.error, onPressed: onDelete),
        ],
      ],
    );
  }
}
