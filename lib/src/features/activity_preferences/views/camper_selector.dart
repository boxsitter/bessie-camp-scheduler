import 'package:bessie/src/shared/widgets/loaders/circular_loader.dart';
import 'package:bessie/src/shared/widgets/misc/card_selector.dart';
import 'package:bessie/src/ember_core.dart';
import 'package:flutter/material.dart';

import '../../../shared/styles/text_styles.dart';
import '../../../shared/widgets/wrappers/tint.dart';

class CamperSelector extends StatelessWidget {
  const CamperSelector({
    super.key,
    this.campers = const [],
    this.selectedCamper,
    this.onSelectCamper,
    required this.isCampersLoaded,
    this.cabinName,
    this.totalActivities,
    required this.entriesSaving,
    required this.isLoading,
  });

  final String? cabinName;
  final List<Camper> campers;
  final Camper? selectedCamper;
  final void Function(Camper)? onSelectCamper;
  final bool isCampersLoaded;
  final int? totalActivities;
  final Set<CamperId> entriesSaving;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isCampersLoaded == false) {
      return BessCircularLoader();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          cabinName != null ? cabinName! : 'Campers',
          style: BessTextStyles.boldCardTitle,
        ),
        SizedBox(
          height: 8,
        ),
        Expanded(
          child: CardSelector(
            cardHeight: 50,
            cardWidth: double.infinity,
            maxLines: 2,
            items: campers,
            itemCompleted: (Camper camper) => camper.preferencesStarted == true,
            selectedItem: selectedCamper,
            onSelectItem: onSelectCamper ?? (Camper) => {},
            isHorizontal: false,
            childBuilder: (BuildContext context, Camper item) => Column(
              children: [
                Expanded(
                  child: Center(
                    child: Builder(builder: (context) {
                      if (entriesSaving.contains(item.id) && isLoading) {
                        return Container(
                          width: 24,
                          height: 24,
                          child: BessCircularLoader(),
                        );
                      }
                      return Text(
                        '${item.displayTitle}',
                        style: BessTextStyles.standard.copyWith(
                          // This will now correctly find the foregroundColor provided by Tint.
                          color: Tint.of(context)?.foregroundColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
