import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../models/camper.dart';
import '../../../models/schedule.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/sizes.dart';
import '../../../shared/styles/text_styles.dart';
import '../../../shared/widgets/buttons/action_initiator.dart';
import '../../../shared/widgets/buttons/card_button.dart';
import '../../../shared/widgets/containers/titled_container.dart';
import '../../../shared/widgets/misc/card_selector.dart';
import '../../../shared/widgets/misc/widget_list.dart';
import '../../../shared/widgets/wrappers/tint.dart';
import '../controllers/rosters_controller.dart';
import 'roster_colors.dart';

/// The panel for moving the selected campers into an activity: pick a period,
/// pick one of its activities, check the summary and assign.
class ActivitySwitcher extends StatelessWidget {
  const ActivitySwitcher({super.key, required this.controller});

  final RostersController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BessSizes.md),
      decoration: BoxDecoration(border: BorderDirectional(bottom: BorderSide(color: BessColors.borderPrimary, width: 2))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TitledContainer(
              title: 'Select Activity Period',
              child: CardSelector<Block>(
                items: controller.schedule.blocks,
                onSelectItem: controller.selectBlock,
                selectedItem: controller.selectedBlock,
                childBuilder: (context, block) => SizedBox(
                  height: 25,
                  child: Center(
                    child: Text(
                      block.displayTitle,
                      style: BessTextStyles.standardBold.copyWith(color: Tint.of(context)?.foregroundColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: BessSizes.spaceBtwItems),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: TitledContainer(
                    title: 'Select Activity',
                    child: controller.selectedBlock == null
                        ? Center(child: Text('Select an activity period first!', style: BessTextStyles.tableHeaderSecondary))
                        : _ActivityList(controller: controller),
                  ),
                ),
                Expanded(
                  child: TitledContainer(
                    title: 'Summary',
                    child: controller.hasSelection
                        ? WidgetList<Camper>(
                            items: controller.selectedCampers,
                            itemBuilder: (context, camper) => _SummaryRow(camper: camper, controller: controller),
                          )
                        : Center(child: Text('Select some campers first!', style: BessTextStyles.tableHeaderSecondary)),
                  ),
                ),
                const SizedBox(height: BessSizes.spaceBtwItems),
                ActionInitiator(
                  onPressed: controller.assignSelected,
                  disabled: !controller.canAssignToSelectedActivity,
                  awaiting: controller.assigning,
                  enabledText: 'Assign ${controller.selectedCampers.length == 1 ? 'camper' : '${controller.selectedCampers.length} campers'}',
                  disabledText: 'Nothing to assign yet',
                  awaitingText: 'One moment...',
                  width: double.infinity,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityList extends StatelessWidget {
  const _ActivityList({required this.controller});

  final RostersController controller;

  @override
  Widget build(BuildContext context) {
    final activities = controller.selectedBlockActivities;
    if (activities.isEmpty) {
      return Center(child: Text('Nothing is scheduled in this period.', style: BessTextStyles.tableHeaderSecondary));
    }
    return ListView.builder(
      clipBehavior: Clip.none,
      itemCount: activities.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: _ActivityCard(scheduled: activities[index], controller: controller),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.scheduled, required this.controller});

  final ScheduledActivity scheduled;
  final RostersController controller;

  @override
  Widget build(BuildContext context) {
    final seats = controller.seatsOf(scheduled);
    final hint = controller.preferenceHintFor(scheduled);
    final overCapacity = seats.wouldOverflow;
    final List<TintCondition> tint = [
      (controller.selectedScheduledId == scheduled.id, BessColors.primary),
      (hint != null, hint == null ? null : preferenceColor(hint)),
      (overCapacity, BessColors.red),
      (true, BessColors.green),
    ];

    return CardButton(
      tintConditions: tint,
      height: 60,
      onPressed: () => controller.selectScheduled(scheduled),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(controller.activityName(scheduled), style: BessTextStyles.boldCardTitle, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 16),
          if (seats.incoming > 0)
            Text(
              '${seats.incoming}+',
              overflow: TextOverflow.clip,
              style: BessTextStyles.standard.copyWith(color: overCapacity ? BessColors.red : BessColors.green),
            ),
          const SizedBox(width: 4),
          Text('${seats.enrolled}/${seats.capacity}', overflow: TextOverflow.clip, style: BessTextStyles.standardBold),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.camper, required this.controller});

  final Camper camper;
  final RostersController controller;

  @override
  Widget build(BuildContext context) {
    final change = controller.plannedChange(camper);
    final Widget trailing;
    if (change == null) {
      trailing = Text('No change', style: BessTextStyles.standardBold);
    } else if (change.from == null) {
      trailing = Text('Assign to ${change.to}', style: BessTextStyles.standardBold);
    } else {
      trailing = Row(
        children: [
          Text(change.from!, style: BessTextStyles.standardBold),
          const SizedBox(width: 8),
          const Icon(LucideIcons.arrowRight600),
          const SizedBox(width: 8),
          Text(change.to, style: BessTextStyles.standardBold),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(camper.displayTitle, style: BessTextStyles.standard)),
          trailing,
        ],
      ),
    );
  }
}
