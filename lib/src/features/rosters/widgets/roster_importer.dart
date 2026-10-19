import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../shared/constants/sizes.dart';
import '../../../shared/services/popup_service.dart';
import '../../../shared/widgets/buttons/action_initiator.dart';
import '../controllers/rosters_controller.dart';
import '../models/roster_column.dart';

/// Opens the import dialog: what the file must contain, and a button that
/// picks it. The dialog closes itself once the roster was imported.
Future<void> showRosterImporter(RostersController controller) async {
  await Get.find<PopupService>().showFullScreenDialog(
    title: 'Import campers',
    child: RosterImporter(
      importing: controller.importing,
      onImport: () async {
        final imported = await controller.importCsv();
        if (imported && (Get.isDialogOpen ?? false)) Get.back();
      },
    ),
  );
}

/// Instructions for importing an UltraCamp roster, with the button to start.
class RosterImporter extends StatelessWidget {
  const RosterImporter({super.key, required this.importing, required this.onImport});

  final RxBool importing;
  final VoidCallback onImport;

  static String _bullet(RosterField field) =>
      '• ${field.csvHeaders.map((header) => '"$header"').join(' or ')}${field.isRequired ? '' : ' (optional)'}';

  @override
  Widget build(BuildContext context) {
    final columns = RosterField.values.where((field) => field.csvHeader != null);
    return Padding(
      padding: const EdgeInsets.all(BessSizes.defaultSpace),
      child: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This expects a spreadsheet export from UltraCamp. '
              'It must be a .csv file. UltraCamp will call it something like "export for excel".',
            ),
            const SizedBox(height: BessSizes.spaceBtwItems),
            const Text('The exported UltraCamp report should be of the master roster for a single camp session and contain the columns:'),
            const SizedBox(height: BessSizes.spaceBtwItems),
            Text(columns.map(_bullet).join('\n')),
            const SizedBox(height: BessSizes.spaceBtwItems),
            const Text(
              'The data for the optional columns can be empty or incomplete. '
              'Campers who are already on the roster are skipped, and campers whose cabin isn\'t part of this session are added without a cabin.',
            ),
            const SizedBox(height: BessSizes.spaceBtwSections),
            Center(
              child: Obx(
                () => ActionInitiator(
                  enabledText: 'Choose file',
                  awaitingText: 'Importing... (this may take a while)',
                  onPressed: onImport,
                  awaiting: importing.value,
                  width: 220,
                  height: 48,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
