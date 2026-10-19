import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../models/activity.dart';
import '../../../models/schedule.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/sizes.dart';
import '../../../shared/styles/text_styles.dart';
import '../../branch_manager/catalog_logic.dart';
import '../../branch_manager/widgets/catalog_rows.dart';
import '../../branch_manager/widgets/pill.dart';
import '../../branch_manager/widgets/section_card.dart';
import '../session_setup_logic.dart';

/// What is offered in each block of the session, with add and remove for
/// people who may change session data.
class ScheduleSection extends StatelessWidget {
  const ScheduleSection({
    super.key,
    required this.setup,
    required this.canEdit,
    required this.busy,
    required this.onAdd,
    required this.onRemove,
  });

  final SessionSetup setup;
  final bool canEdit;
  final bool busy;
  final ValueChanged<Block> onAdd;
  final void Function(Block block, ScheduledActivity scheduled) onRemove;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Schedule',
      subtitle:
          'The activities campers can be placed in during each block. The number beside an activity is campers assigned out of its capacity.',
      child:
          setup.schedule.blocks.isEmpty
              ? Text('This session has no blocks yet.', style: BessTextStyles.standardSecondary)
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final day in groupBlocksByDay(setup.schedule.blocks)) ...[
                    GroupHeading(label: day.heading),
                    for (final block in day.blocks)
                      Padding(
                        padding: const EdgeInsets.only(bottom: BessSizes.sm),
                        child: _BlockTile(
                          setup: setup,
                          block: block,
                          canEdit: canEdit,
                          busy: busy,
                          onAdd: () => onAdd(block),
                          onRemove: (scheduled) => onRemove(block, scheduled),
                        ),
                      ),
                  ],
                ],
              ),
    );
  }
}

class _BlockTile extends StatelessWidget {
  const _BlockTile({
    required this.setup,
    required this.block,
    required this.canEdit,
    required this.busy,
    required this.onAdd,
    required this.onRemove,
  });

  final SessionSetup setup;
  final Block block;
  final bool canEdit;
  final bool busy;
  final VoidCallback onAdd;
  final ValueChanged<ScheduledActivity> onRemove;

  @override
  Widget build(BuildContext context) {
    final offered = setup.offeredIn(block);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(BessSizes.ms),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(BessSizes.cardRadiusMd),
        border: Border.all(color: BessColors.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: BessSizes.sm,
                  runSpacing: BessSizes.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(block.title, style: BessTextStyles.standardBold),
                    Text(formatBlockTimes(block), style: BessTextStyles.standardSecondary),
                    if (block.isSkillsRec) const Pill('Skills rec', tone: PillTone.info),
                    Pill(pluralize(offered.length, 'activity', 'activities')),
                  ],
                ),
              ),
              if (canEdit)
                ShadButton.secondary(
                  size: ShadButtonSize.sm,
                  leading: const Icon(LucideIcons.plus, size: 16),
                  onPressed: busy ? null : onAdd,
                  child: const Text('Add activities'),
                ),
            ],
          ),
          const SizedBox(height: BessSizes.sm),
          if (offered.isEmpty)
            Text('Nothing is offered yet.', style: BessTextStyles.standardSecondary)
          else
            Wrap(
              spacing: BessSizes.sm,
              runSpacing: BessSizes.sm,
              children: [
                for (final scheduled in offered)
                  if (setup.schedule.activityOf(scheduled) case final activity?)
                    _ActivityChip(
                      activity: activity,
                      enrolled: setup.enrolledIn(scheduled),
                      onRemove: canEdit && !busy ? () => onRemove(scheduled) : null,
                    ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ActivityChip extends StatelessWidget {
  const _ActivityChip({required this.activity, required this.enrolled, required this.onRemove});

  final Activity activity;
  final int enrolled;

  /// Null when the activity cannot be removed (read-only, or busy).
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final overCapacity = enrolled > activity.capacity;
    return Container(
      padding: EdgeInsets.fromLTRB(BessSizes.ms, BessSizes.xs, onRemove == null ? BessSizes.ms : BessSizes.xs, BessSizes.xs),
      decoration: BoxDecoration(color: BessColors.background, borderRadius: BorderRadius.circular(BessSizes.cardRadiusSm)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (activity.isHidden) ...[
            Tooltip(message: ActivityBadge.hidden.hint, child: Icon(LucideIcons.eyeOff, size: 14, color: BessColors.textSecondary)),
            const SizedBox(width: BessSizes.xs),
          ],
          Text(activity.name, style: BessTextStyles.standard),
          const SizedBox(width: BessSizes.sm),
          Text(
            '$enrolled/${activity.capacity}',
            style: BessTextStyles.label.copyWith(
              color: overCapacity ? BessColors.error : BessColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (onRemove != null)
            Tooltip(
              message: 'Remove ${activity.name} from this block',
              child: ShadIconButton.ghost(width: 24, height: 24, icon: const Icon(LucideIcons.x, size: 14), onPressed: onRemove),
            ),
        ],
      ),
    );
  }
}
