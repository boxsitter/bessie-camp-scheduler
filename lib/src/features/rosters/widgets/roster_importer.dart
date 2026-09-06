import 'package:bessie/src/shared/widgets/buttons/action_initiator.dart';
import 'package:flutter/material.dart';

import '../../../shared/constants/sizes.dart';

/// A widget to create a standardized popup for importing CSV files.
class RosterImporter extends StatelessWidget {
  final bool isImporting;
  final VoidCallback onImport;

  const RosterImporter({
    super.key,
    required this.isImporting,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(BessSizes.defaultSpace),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Import Instructions',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: BessSizes.spaceBtwItems),
          const Text(
            'This expects a spreadsheet export from UltraCamp. '
                'It must be a .csv file. UltraCamp will call it something like "export for excel".',
          ),
          const SizedBox(height: BessSizes.spaceBtwItems),
          const Text(
            'The exported UltraCamp report should be of the master roster for a single camp session and contain the fields:',
          ),
          const SizedBox(height: BessSizes.spaceBtwItems),
          const Text(
            '• "nameFirst"\n'
                '• "nameLast"\n'
                '• "Birthdate"\n'
                '• "nickname"\n'
                '• "idPerson"\n'
                '• "gender" or "expressionName"\n'
                '• "Cabin"',
          ),
          const SizedBox(height: BessSizes.spaceBtwItems),
          const Text(
              'The data for nickname, gender/expressionName, or cabin can be empty or incomplete, but Bessie expects the column to at least be included in the report.'
          ),
          const SizedBox(height: BessSizes.spaceBtwSections),
          Center(
            // No Obx needed, as the parent GetBuilder will handle rebuilds.
            child: ActionInitiator(
              enabledText: 'Add File',
              awaitingText: 'Importing... (this may take a while)',
              onPressed: onImport,
              awaiting: !isImporting,
            ),
          ),
        ],
      ),
    );
  }
}