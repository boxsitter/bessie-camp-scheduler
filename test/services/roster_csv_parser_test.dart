import 'dart:convert';

import 'package:bessie/src/models/enums.dart';
import 'package:bessie/src/services/roster_import_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = RosterCsvParser();

  const header = 'idPerson,nameFirst,nickname,nameLast,expressionName,Birthdate,Cabin';

  test('parses an UltraCamp export', () {
    final roster = parser.parse('''
$header
1001,Ada,,Lovelace,Female,12/10/2015 12:00:00 AM,Oak
1002,"Grace, Jr.",Gracie,Hopper,Nonbinary (prefers female overnight housing),1/2/2014,
''');

    expect(roster.rows, hasLength(2));
    final ada = roster.rows[0];
    expect(ada.firstName, 'Ada');
    expect(ada.lastName, 'Lovelace');
    expect(ada.birthdate, DateTime(2015, 12, 10), reason: 'time of day is ignored, no timezone shift');
    expect(ada.gender, Gender.female);
    expect(ada.cabinName, 'Oak');
    expect(ada.ultracampId, '1001');
    expect(ada.preferredName, isNull);

    final grace = roster.rows[1];
    expect(grace.firstName, 'Grace, Jr.', reason: 'quoted commas survive');
    expect(grace.preferredName, 'Gracie');
    expect(grace.gender, Gender.nonBinary);
    expect(grace.cabinName, isNull);
    expect(grace.birthdate, DateTime(2014, 1, 2));
  });

  test('tolerates CRLF line endings, a BOM, header case, column order and extra columns', () {
    final bytes = [0xEF, 0xBB, 0xBF, ...'Extra,BIRTHDATE,NameLast,NameFirst\r\nx,2016-03-04,Turing,Alan\r\n'.codeUnits];
    final roster = parser.parse(parser.decode(bytes));
    expect(roster.rows.single.firstName, 'Alan');
    expect(roster.rows.single.birthdate, DateTime(2016, 3, 4));
  });

  test('decodes UTF-8 names correctly', () {
    final bytes = 'nameFirst,nameLast,Birthdate\nJosé,Muñoz,5/6/2015\n'.codeUnits;
    // String.codeUnits of non-ASCII isn't UTF-8; encode properly.
    final utf8Bytes = const Utf8Encoder().convert('nameFirst,nameLast,Birthdate\nJosé,Muñoz,5/6/2015\n');
    expect(bytes, isNot(utf8Bytes));
    final roster = parser.parse(parser.decode(utf8Bytes));
    expect(roster.rows.single.firstName, 'José');
    expect(roster.rows.single.lastName, 'Muñoz');
  });

  test('skips blank rows and de-duplicates within the file', () {
    final roster = parser.parse('''
nameFirst,nameLast,Birthdate
Ada,Lovelace,1/1/2015
,,
ada,LOVELACE,1/1/2015
Ada,Lovelace,1/2/2015
''');
    expect(roster.rows, hasLength(2), reason: 'same name with another birthdate is a different camper');
    expect(roster.skippedBlankRows, 1);
    expect(roster.duplicatesInFile, 1);
  });

  group('errors name the problem', () {
    test('missing required column', () {
      expect(
        () => parser.parse('nameFirst,nameLast\nAda,Lovelace\n'),
        throwsA(isA<RosterImportException>().having((e) => e.message, 'message', contains('Birthdate'))),
      );
    });

    test('impossible dates', () {
      expect(
        () => parser.parse('nameFirst,nameLast,Birthdate\nAda,Lovelace,2/30/2015\n'),
        throwsA(isA<RosterImportException>().having((e) => e.message, 'message', allOf(contains('row 2'), contains('2/30/2015')))),
      );
    });

    test('missing values', () {
      expect(
        () => parser.parse('nameFirst,nameLast,Birthdate\nAda,,1/1/2015\n'),
        throwsA(isA<RosterImportException>().having((e) => e.message, 'message', contains('Row 2'))),
      );
    });

    test('no data rows', () {
      expect(() => parser.parse('nameFirst,nameLast,Birthdate\n'), throwsA(isA<RosterImportException>()));
    });
  });

  group('parseBirthdate', () {
    test('accepts the formats UltraCamp and ISO use', () {
      expect(RosterCsvParser.parseBirthdate('12/31/2010'), DateTime(2010, 12, 31));
      expect(RosterCsvParser.parseBirthdate('1/2/2010 3:04:05 PM'), DateTime(2010, 1, 2));
      expect(RosterCsvParser.parseBirthdate('2010-01-02'), DateTime(2010, 1, 2));
      expect(RosterCsvParser.parseBirthdate('2010-01-02T10:00:00Z'), DateTime(2010, 1, 2));
    });

    test('rejects nonsense', () {
      expect(RosterCsvParser.parseBirthdate('13/1/2010'), isNull);
      expect(RosterCsvParser.parseBirthdate('2/29/2015'), isNull, reason: '2015 is not a leap year');
      expect(RosterCsvParser.parseBirthdate('soon'), isNull);
    });

    test('accepts a real leap day', () {
      expect(RosterCsvParser.parseBirthdate('2/29/2016'), DateTime(2016, 2, 29));
    });
  });

  test('parseGender', () {
    expect(RosterCsvParser.parseGender('Male'), Gender.male);
    expect(RosterCsvParser.parseGender('female'), Gender.female);
    expect(RosterCsvParser.parseGender('Non-binary'), Gender.nonBinary);
    expect(RosterCsvParser.parseGender('NonBinary (prefers male overnight housing)'), Gender.nonBinary);
    expect(RosterCsvParser.parseGender(''), isNull);
    expect(RosterCsvParser.parseGender(null), isNull);
    expect(RosterCsvParser.parseGender('other'), isNull);
  });
}
