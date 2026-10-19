import '../../../models/camper.dart';
import '../../../services/roster_import_service.dart';

/// "1 camper", "3 campers".
String countOf(int count, String singular, [String? plural]) => '$count ${count == 1 ? singular : (plural ?? '${singular}s')}';

/// A timestamp that is safe in file names: `2026-10-19_1405`.
String fileStamp(DateTime time) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${time.year.toString().padLeft(4, '0')}-${two(time.month)}-${two(time.day)}_${two(time.hour)}${two(time.minute)}';
}

/// What to tell the user about a finished roster import.
class ImportSummary {
  const ImportSummary({required this.message, required this.imported, this.cabinWarning});

  /// The main outcome; a success when [imported], otherwise an info.
  final String message;
  final bool imported;

  /// Set when some cabins in the file don't belong to the session.
  final String? cabinWarning;
}

ImportSummary summarizeImport(ParsedRoster parsed, CamperImportResult result) {
  final skipped = result.duplicates + parsed.duplicatesInFile;
  final String message;
  if (result.inserted > 0) {
    message = skipped > 0
        ? 'Added ${countOf(result.inserted, 'camper')}. Skipped ${countOf(skipped, 'duplicate')} already on the roster.'
        : 'Added ${countOf(result.inserted, 'camper')}.';
  } else if (skipped > 0) {
    message = 'No new campers: ${skipped == 1 ? 'the camper in the file is' : 'all $skipped campers in the file are'} already on the roster.';
  } else {
    message = 'The file didn\'t contain any campers to add.';
  }

  final cabins = result.unknownCabins;
  return ImportSummary(
    message: message,
    imported: result.inserted > 0,
    cabinWarning: cabins.isEmpty
        ? null
        : 'These cabins are not part of this session, so their campers were added without a cabin: ${cabins.join(', ')}.',
  );
}
