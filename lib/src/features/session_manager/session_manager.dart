import 'package:bessie/src/shared/constants/sizes.dart';
import 'package:bessie/src/shared/styles/text_styles.dart';
import 'package:bessie/src/shared/widgets/buttons/card_button.dart';
import 'package:bessie/src/shared/widgets/header/menu_bar.dart';
import 'package:bessie/src/features/session_manager/session_manager_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../shared/widgets/layouts/templates/site_layout.dart';

class SessionManager extends StatelessWidget {
  const SessionManager({super.key});

  @override
  Widget build(BuildContext context) {
    return BessSiteTemplate(desktop: SessionManagerDesktop(), menuBar: BessMenuBar(),);
  }
}

class SessionManagerDesktop extends StatelessWidget {
  const SessionManagerDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SessionManagerController>(
      builder: (controller) {
        Widget content;
        if (controller.isLoading) {
          content = const Center(child: CircularProgressIndicator());
        } else if (controller.cabinPrinIdsToNames.isEmpty) {
          content = const Center(child: Text("No cabins found."));
        } else {
          content = SingleChildScrollView(
            child: Wrap(
              spacing: BessSizes.spaceBtwItems / 2,
              runSpacing: BessSizes.spaceBtwItems / 2,
              children: controller.cabinPrinIdsToNames.entries.map((entry) {
                final String cabinPrinId = entry.key;
                final String cabinName = entry.value;

                final isSelected = controller.selectedCabinPrinIds.contains(cabinPrinId);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: BessSizes.xs, vertical: BessSizes.xs),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: isSelected,
                        onChanged: (bool? newValue) {
                          controller.toggleCabinSelection(cabinPrinId);
                        },
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      Flexible(
                        child: Text(
                          cabinName,
                          style: Theme.of(context).textTheme.bodyMedium,
                          softWrap: false,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(BessSizes.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Active Cabins',
                style: BessTextStyles.tableHeader,
              ),
              const SizedBox(height: BessSizes.spaceBtwSections),
              content,
              const SizedBox(height: BessSizes.spaceBtwInputFields),
              CardButton(
                child: Text('Commit Changes', style: BessTextStyles.standard, maxLines: 1,),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                onPressed: () => controller.commitSelection(),
              ),
            ],
          ),
        );
      },
    );
  }
}
