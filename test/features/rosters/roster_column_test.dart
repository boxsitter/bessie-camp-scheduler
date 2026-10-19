import 'package:bessie/src/features/rosters/models/roster_column.dart';
import 'package:bessie/src/services/roster_import_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'roster_fixtures.dart';

void main() {
  group('columns', () {
    test('field columns are equal when they show the same field', () {
      expect(const FieldColumn(RosterField.age), const FieldColumn(RosterField.age));
      expect(const FieldColumn(RosterField.age), isNot(const FieldColumn(RosterField.cabin)));
    });

    test('block columns are equal when they show the same block, however often it was loaded', () {
      expect(BlockColumn(makeBlock('b1', 'AM1')), BlockColumn(makeBlock('b1', 'AM1')));
      expect(BlockColumn(makeBlock('b1', 'AM1')), isNot(BlockColumn(makeBlock('b2', 'AM1'))));
      expect(BlockColumn(makeBlock('x', 'AM1')), isNot(const FieldColumn(RosterField.age)));
    });

    test('block columns are titled with the weekday and block title', () {
      expect(BlockColumn(makeBlock('b1', 'AM1')).title, 'Monday - AM1');
      expect(BlockColumn(makeBlock('b1', 'AM1')).allowGrouping, isTrue);
    });
  });

  group('remapToSchedule', () {
    final old1 = makeBlock('old1', 'AM1');
    final old2 = makeBlock('old2', 'PM1', dayIndex: 1, startHour: 14);
    final columns = <RosterColumn>[const FieldColumn(RosterField.fullName), BlockColumn(old1), BlockColumn(old2)];

    test('keeps a block that is still there, as the freshly loaded object', () {
      final fresh = makeBlock('old1', 'AM1');
      final schedule = makeSchedule(blocks: [fresh, old2], activities: []);
      final remapped = RosterColumns.remapToSchedule(columns, schedule);
      expect(remapped, hasLength(3));
      expect((remapped[1] as BlockColumn).block, same(fresh));
    });

    test('moves to the equivalent block of another session and drops blocks with no counterpart', () {
      final next1 = makeBlock('new1', 'AM1');
      final schedule = makeSchedule(blocks: [next1, makeBlock('new9', 'Evening', dayIndex: 3)], activities: []);
      final remapped = RosterColumns.remapToSchedule(columns, schedule);
      expect(remapped, [const FieldColumn(RosterField.fullName), BlockColumn(next1)]);
    });

    test('drops every block column when the schedule is empty and never duplicates one', () {
      final empty = makeSchedule(blocks: [], activities: []);
      expect(RosterColumns.remapToSchedule(columns, empty), [const FieldColumn(RosterField.fullName)]);

      final twin = makeSchedule(blocks: [makeBlock('only', 'AM1')], activities: []);
      final twice = RosterColumns.remapToSchedule([BlockColumn(old1), BlockColumn(makeBlock('old3', 'AM1'))], twin);
      expect(twice, hasLength(1));
    });

    test('remap of a field column is the column itself', () {
      const column = FieldColumn(RosterField.age);
      expect(RosterColumns.remap(column, makeSchedule(blocks: [], activities: [])), same(column));
    });
  });

  group('field catalogue', () {
    test('lists the importable fields with their UltraCamp headers', () {
      final required = RosterField.values.where((f) => f.isRequired).map((f) => f.csvHeader);
      expect(required, ['nameFirst', 'nameLast', 'Birthdate']);
      expect(RosterField.gender.csvHeaders, ['expressionName', 'Gender']);
      expect(RosterField.age.csvHeaders, isEmpty);
    });

    test('every header it advertises is understood by the roster parser', () {
      final fields = RosterField.values.where((f) => f.csvHeader != null).toList();
      final header = fields.map((f) => f.csvHeader).join(',');
      final values = fields
          .map((f) {
            switch (f) {
              case RosterField.birthdate:
                return '06/15/2014';
              case RosterField.gender:
                return 'Female';
              case RosterField.cabin:
                return 'Cabin 1';
              default:
                return 'x-${f.name}';
            }
          })
          .join(',');

      final parsed = const RosterCsvParser().parse('$header\n$values\n');
      final row = parsed.rows.single;
      expect(row.firstName, 'x-firstName');
      expect(row.lastName, 'x-lastName');
      expect(row.preferredName, 'x-preferredName');
      expect(row.ultracampId, 'x-ultracampId');
      expect(row.cabinName, 'Cabin 1');
    });

    test('the alternate gender header is accepted too', () {
      final parsed = const RosterCsvParser().parse('nameFirst,nameLast,Birthdate,Gender\nAda,Lovelace,12/10/2014,F\n');
      expect(parsed.rows.single.gender?.code, 'F');
    });
  });
}
