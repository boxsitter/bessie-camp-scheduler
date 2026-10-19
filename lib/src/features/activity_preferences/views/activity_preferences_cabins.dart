import 'package:flutter/material.dart';

import '../../../shared/constants/colors.dart';
import '../../../shared/constants/sizes.dart';
import '../../../shared/styles/text_styles.dart';
import '../../../shared/widgets/buttons/card_button.dart';
import '../../../shared/widgets/misc/widget_grid.dart';
import '../controllers/activity_preferences_controller.dart';
import '../models/cabin_group.dart';

/// The cabins of the session, each with how many campers are done.
class ActivityPreferencesCabins extends StatelessWidget {
  const ActivityPreferencesCabins({super.key, required this.controller});

  final ActivityPreferencesController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cabins', style: BessTextStyles.lightTitle, overflow: TextOverflow.clip, maxLines: 1),
          const SizedBox(height: BessSizes.spaceBtwSections),
          Expanded(
            child: WidgetGrid<CabinGroup>(
              items: controller.cabinGroups,
              itemBuilder: (context, group) => _CabinCard(group: group, onPressed: () => controller.selectCabinGroup(group)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CabinCard extends StatelessWidget {
  const _CabinCard({required this.group, required this.onPressed});

  final CabinGroup group;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CardButton(
      tintConditions: [(group.isInProgress, BessColors.yellow), (group.isComplete, BessColors.green)],
      height: 90,
      width: 250,
      onPressed: onPressed,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(group.title, style: BessTextStyles.boldCardTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Text('${group.submitted}/${group.total} campers completed', style: BessTextStyles.largerLabel),
        ],
      ),
    );
  }
}
