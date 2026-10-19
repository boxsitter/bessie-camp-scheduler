import 'package:bessie/src/algorithms/evaluation/participant_evaluation_report.dart';
import 'package:bessie/src/features/rosters/models/roster_column.dart';
import 'package:bessie/src/features/rosters/models/roster_context.dart';
import 'package:bessie/src/features/rosters/models/roster_csv_exporter.dart';
import 'package:bessie/src/features/rosters/models/roster_view.dart';
import 'package:bessie/src/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

import 'roster_fixtures.dart';

void main() {
  final am1 = makeBlock('b1', 'AM1');
  final schedule = makeSchedule(
    blocks: [am1],
    activities: [makeActivity('a1', 'Archery'), makeActivity('a2', 'Arts, Crafts & "Fun"')],
    scheduled: {'s1': ('b1', 'a1'), 's2': ('b1', 'a2')},
  );
  final view = RosterView(
    RosterContext(
      schedule: schedule,
      cabinsById: {'c1': makeCabin('c1', 'Cabin 1'), 'c2': makeCabin('c2', 'Cabin 2')},
      now: DateTime(2026, 7, 6),
    ),
  );

  const name = FieldColumn(RosterField.fullName);
  const cabin = FieldColumn(RosterField.cabin);
  final block = BlockColumn(am1);

  final ada = makeCamper(first: 'Ada', last: 'Lovelace', cabinId: 'c1', assignments: {'b1': 's1'});
  final bo = makeCamper(first: 'Bo', last: 'Brown', cabinId: 'c2', assignments: {'b1': 's2'});
  final cy = makeCamper(first: 'Cy', last: 'Green', cabinId: 'c1');

  String export(List<RosterColumn> columns, {RosterColumn? groupBy}) {
    final groups = view.arrange([ada, bo, cy], sortBy: RosterColumns.lastName, groupBy: groupBy);
    return RosterCsvExporter.export(groups: groups, columns: columns, view: view, grouped: groupBy != null);
  }

  group('escaping', () {
    test('leaves plain fields alone', () {
      expect(RosterCsvExporter.escapeField('plain text'), 'plain text');
      expect(RosterCsvExporter.escapeField(''), '');
    });

    test('quotes fields with commas, quotes or line breaks and doubles quotes', () {
      expect(RosterCsvExporter.escapeField('a,b'), '"a,b"');
      expect(RosterCsvExporter.escapeField('say "hi"'), '"say ""hi"""');
      expect(RosterCsvExporter.escapeField('line1\nline2'), '"line1\nline2"');
      expect(RosterCsvExporter.escapeField('line1\r\nline2'), '"line1\r\nline2"');
    });
  });

  group('ungrouped', () {
    test('is a header row followed by one row per camper in table order', () {
      expect(export([name, cabin]), 'Full Name,Cabin\nBo Brown,Cabin 2\nCy Green,Cabin 1\nAda Lovelace,Cabin 1\n');
    });

    test('block columns print the activity name, escaped, or Unassigned', () {
      final csv = export([name, block]);
      expect(csv.split('\n'), [
        'Full Name,Monday - AM1',
        'Bo Brown,"Arts, Crafts & ""Fun"""',
        'Cy Green,Unassigned',
        'Ada Lovelace,Archery',
        '',
      ]);
    });

    test('with nobody to list it is only the header', () {
      final csv = RosterCsvExporter.export(groups: view.arrange([], sortBy: name), columns: [name], view: view, grouped: false);
      expect(csv, 'Full Name\n');
    });

    test('escapes notes with commas', () {
      final noted = makeCamper(first: 'Di', last: 'Note', note: 'allergic to nuts, bees');
      final groups = view.arrange([noted], sortBy: name);
      final csv = RosterCsvExporter.export(groups: groups, columns: const [FieldColumn(RosterField.note)], view: view, grouped: false);
      expect(csv, 'Note\n"allergic to nuts, bees"\n');
    });
  });

  group('grouped', () {
    test('writes each group title, the header, its campers and a blank line', () {
      expect(
        export([name], groupBy: cabin),
        'Cabin 1\nFull Name\nCy Green\nAda Lovelace\n\n'
        'Cabin 2\nFull Name\nBo Brown\n\n',
      );
    });

    test('groups by an activity block under the activity name', () {
      final csv = export([name], groupBy: block);
      expect(csv, startsWith('Archery\nFull Name\nAda Lovelace\n\n'));
      expect(csv, contains('"Arts, Crafts & ""Fun"""\nFull Name\nBo Brown\n'));
      expect(csv, endsWith('Unassigned\nFull Name\nCy Green\n\n'));
    });

    test('skips empty groups', () {
      expect(RosterCsvExporter.export(groups: const [RosterGroup(key: 'k', title: 'Empty', heading: 'Empty', campers: [])], columns: [name], view: view, grouped: true), '');
    });
  });

  test('evaluation report puts the camper name in front of the engine columns', () {
    final reports = [
      ParticipantEvaluationReport(participantId: 'p1', preferencesSatisfied: true, noveltyScore: 0.5),
      ParticipantEvaluationReport(participantId: 'p2', preferencesSatisfied: false, noveltyScore: null),
    ];
    final csv = RosterCsvExporter.evaluationReport(reports, nameOf: (id) => id == 'p1' ? 'Lovelace, Ada' : null);
    expect(csv.split('\n'), [
      'Camper,Participant ID,Preferences Satisfied,Novelty Index',
      '"Lovelace, Ada",p1,true,0.500',
      ',p2,false,N/A',
      '',
    ]);
  });

  test('sorting direction is respected by the exported order', () {
    final groups = view.arrange([ada, bo, cy], sortBy: RosterColumns.lastName, direction: SortDirection.desc);
    final csv = RosterCsvExporter.export(groups: groups, columns: [name], view: view, grouped: false);
    expect(csv, 'Full Name\nAda Lovelace\nCy Green\nBo Brown\n');
  });
}
