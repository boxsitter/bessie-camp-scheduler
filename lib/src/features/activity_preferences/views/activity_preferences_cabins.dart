import 'package:bessie/src/shared/widgets/loaders/circular_loader.dart';
import 'package:bessie/src/ember_core.dart';
import 'package:flutter/material.dart';

import '../../../shared/constants/colors.dart';
import '../../../shared/constants/sizes.dart';
import '../../../shared/styles/text_styles.dart';
import '../../../shared/widgets/buttons/card_button.dart';
import '../../../shared/widgets/misc/widget_grid.dart';
import '../controllers/activity_preferences_controller_diplomatic.dart';

class ActivityPreferencesCabins extends StatelessWidget {
  const ActivityPreferencesCabins({
    super.key,
    required this.controller,
  });

  final ActivityPreferencesControllerDiplomatic controller;

  @override
  Widget build(BuildContext context) {
    if (controller.isCabinDataLoaded == false || controller.isCamperDataLoaded == false) {
      return const BessCircularLoader();
    }
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          'Cabins',
          style: BessTextStyles.lightTitle,
          overflow: TextOverflow.clip,
          maxLines: 1,
        ),
        const SizedBox(height: BessSizes.spaceBtwSections),
        Expanded(
          // Here is the corrected usage of WidgetGrid
          child: WidgetGrid<MapEntry<CabinDependantId, PrincipalCabin>>(
            // 1. Pass the data to the 'items' property.
            // We convert the 'entries' Iterable to a List.
            items: controller.cabins.entries.toList(),

            // 2. Define the builder function to create a widget for each item.
            itemBuilder: (context, item) {
              // 'item' is our MapEntry. Its 'value' is the cabin object.
              final cabin = item.value;
              final name = cabin.displayTitle;

              // Get completion data for this specific cabin using its key.
              final completionRatio = controller.startedOutOfCount(item.key);
              final preferencesCount = completionRatio.$1;
              final count = completionRatio.$2;

              // Calculate the button's visual state.
              final bool isCompleted = preferencesCount >= count;
              final bool isInProgress = preferencesCount > 0 && !isCompleted;

              return CardButton(
                tintConditions: [(isInProgress, BessColors.yellow), (isCompleted, BessColors.green)],
                height: 90,
                width: 250,
                // Pass the entire 'item' (MapEntry) to the controller on press.
                onPressed: () => controller.setSelectedCabin((item.key, item.value)),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: BessTextStyles.boldCardTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$preferencesCount/$count campers completed',
                      style: BessTextStyles.largerLabel,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}
