import 'package:flutter/material.dart';

import '../../../models/camper.dart';
import '../../../shared/styles/text_styles.dart';
import '../../../shared/widgets/loaders/circular_loader.dart';
import '../../../shared/widgets/misc/card_selector.dart';
import '../../../shared/widgets/wrappers/tint.dart';

/// The campers of one cabin; campers whose preferences are saved are green.
class CamperSelector extends StatelessWidget {
  const CamperSelector({
    super.key,
    required this.campers,
    required this.selectedCamper,
    required this.onSelectCamper,
    required this.isPending,
    this.cabinName,
  });

  final String? cabinName;
  final List<Camper> campers;
  final Camper? selectedCamper;
  final void Function(Camper camper) onSelectCamper;

  /// Whether a camper's preferences are being saved (or about to be).
  final bool Function(String camperId) isPending;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(cabinName ?? 'Campers', style: BessTextStyles.boldCardTitle),
        const SizedBox(height: 8),
        Expanded(
          child: CardSelector<Camper>(
            cardHeight: 50,
            cardWidth: double.infinity,
            items: campers,
            itemCompleted: (camper) => camper.preferencesSubmitted,
            selectedItem: selectedCamper,
            onSelectItem: onSelectCamper,
            childBuilder: (context, camper) => Center(
              child: isPending(camper.id)
                  ? const SizedBox(width: 24, height: 24, child: BessCircularLoader())
                  : Text(
                      camper.displayTitle,
                      style: BessTextStyles.standard.copyWith(color: Tint.of(context)?.foregroundColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
