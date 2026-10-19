import 'package:bessie/src/features/rosters/models/roster_messages.dart';
import 'package:bessie/src/models/camper.dart';
import 'package:bessie/src/services/roster_import_service.dart';
import 'package:flutter_test/flutter_test.dart';

ParsedRoster _parsed({int duplicatesInFile = 0}) => ParsedRoster(rows: const [], skippedBlankRows: 0, duplicatesInFile: duplicatesInFile);

void main() {
  test('countOf pluralises', () {
    expect(countOf(1, 'camper'), '1 camper');
    expect(countOf(0, 'camper'), '0 campers');
    expect(countOf(2, 'activity', 'activities'), '2 activities');
  });

  test('fileStamp is safe in file names', () {
    expect(fileStamp(DateTime(2026, 10, 9, 8, 5)), '2026-10-09_0805');
  });

  group('summarizeImport', () {
    test('reports added campers', () {
      final summary = summarizeImport(_parsed(), const CamperImportResult(inserted: 3, duplicates: 0, unknownCabins: []));
      expect(summary.message, 'Added 3 campers.');
      expect(summary.imported, isTrue);
      expect(summary.cabinWarning, isNull);
    });

    test('adds up duplicates from the database and from the file', () {
      final summary = summarizeImport(
        _parsed(duplicatesInFile: 2),
        const CamperImportResult(inserted: 1, duplicates: 3, unknownCabins: []),
      );
      expect(summary.message, 'Added 1 camper. Skipped 5 duplicates already on the roster.');
    });

    test('says so when there is nothing new', () {
      final all = summarizeImport(_parsed(), const CamperImportResult(inserted: 0, duplicates: 4, unknownCabins: []));
      expect(all.imported, isFalse);
      expect(all.message, 'No new campers: all 4 campers in the file are already on the roster.');
      final one = summarizeImport(_parsed(), const CamperImportResult(inserted: 0, duplicates: 1, unknownCabins: []));
      expect(one.message, 'No new campers: the camper in the file is already on the roster.');
    });

    test('lists cabins that are not part of the session', () {
      final summary = summarizeImport(_parsed(), const CamperImportResult(inserted: 2, duplicates: 0, unknownCabins: ['Nowhere', 'Moon']));
      expect(summary.cabinWarning, contains('Nowhere, Moon'));
    });
  });
}
