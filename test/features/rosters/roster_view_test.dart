import 'package:bessie/src/features/rosters/models/roster_column.dart';
import 'package:bessie/src/features/rosters/models/roster_context.dart';
import 'package:bessie/src/features/rosters/models/roster_view.dart';
import 'package:bessie/src/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

import 'roster_fixtures.dart';

const _name = FieldColumn(RosterField.fullName);
const _last = FieldColumn(RosterField.lastName);
const _age = FieldColumn(RosterField.age);
const _cabin = FieldColumn(RosterField.cabin);
const _arrived = FieldColumn(RosterField.arrived);
const _swim = FieldColumn(RosterField.canSwim);
const _asi = FieldColumn(RosterField.satisfactionIndex);

void main() {
  final am1 = makeBlock('b1', 'AM1');
  final am2 = makeBlock('b2', 'AM2', dayIndex: 1);
  final archery = makeActivity('act-archery', 'Archery');
  final canoe = makeActivity('act-canoe', 'Canoeing');
  final schedule = makeSchedule(
    blocks: [am1, am2],
    activities: [archery, canoe],
    scheduled: {'s1': ('b1', 'act-archery'), 's2': ('b1', 'act-canoe'), 's3': ('b2', 'act-archery')},
  );
  final context = RosterContext(
    schedule: schedule,
    cabinsById: {
      'cab2': makeCabin('cab2', 'Cabin 2'),
      'cab10': makeCabin('cab10', 'Cabin 10'),
      'cabx': makeCabin('cabx', 'C-3', displayName: 'Eagles'),
    },
    now: DateTime(2026, 7, 6),
  );
  final view = RosterView(context);

  group('cell text', () {
    test('shows the name the camper goes by', () {
      final camper = makeCamper(first: 'Katherine', preferred: 'Kate', last: 'Johnson');
      expect(view.text(camper, _name), 'Kate Johnson');
      expect(view.text(camper, const FieldColumn(RosterField.firstName)), 'Katherine');
      expect(view.text(camper, const FieldColumn(RosterField.preferredName)), 'Kate');
      expect(view.text(makeCamper(), const FieldColumn(RosterField.preferredName)), '');
    });

    test('formats birthdate as MM/DD/YYYY and age against the context date', () {
      final camper = makeCamper(birthdate: DateTime(2014, 7, 7));
      expect(view.text(camper, const FieldColumn(RosterField.birthdate)), '07/07/2014');
      expect(view.text(camper, _age), '11'); // turns 12 the day after the context date
      expect(view.text(makeCamper(birthdate: DateTime(2014, 7, 6)), _age), '12');
    });

    test('prints the cabin title, not its id', () {
      expect(view.text(makeCamper(cabinId: 'cabx'), _cabin), 'Eagles');
      expect(view.text(makeCamper(cabinId: 'cab2'), _cabin), 'Cabin 2');
      expect(view.text(makeCamper(), _cabin), RosterView.noCabin);
      expect(view.text(makeCamper(cabinId: 'gone'), _cabin), 'Unknown cabin');
    });

    test('can swim reports can swim, not arrived', () {
      final camper = makeCamper(arrived: false, canSwim: true);
      expect(view.cell(camper, _swim), const RosterCell('Yes'));
      expect(view.cell(camper, _arrived), const RosterCell('No', tone: CellTone.alert));
      final other = makeCamper(arrived: true, canSwim: false);
      expect(view.cell(other, _swim), const RosterCell('No', tone: CellTone.alert));
      expect(view.cell(other, _arrived), const RosterCell('Yes'));
    });

    test('optional values are blank rather than "null"', () {
      final camper = makeCamper();
      expect(view.text(camper, const FieldColumn(RosterField.gender)), '');
      expect(view.text(camper, const FieldColumn(RosterField.ultracampId)), '');
      expect(view.text(camper, _asi), 'N/A');
      expect(view.text(makeCamper(gender: Gender.nonBinary, ultracampId: '42', satisfaction: 0.5), const FieldColumn(RosterField.gender)), 'NB');
      expect(view.text(makeCamper(satisfaction: 0.5), _asi), '0.50');
    });

    test('preferences complete follows whether preferences were saved', () {
      const column = FieldColumn(RosterField.preferencesSubmitted);
      expect(view.cell(makeCamper(), column).tone, CellTone.alert);
      expect(view.text(makeCamper(preferencesSubmittedAt: DateTime(2026)), column), 'Yes');
    });

    test('block columns print the activity name or Unassigned', () {
      final column = BlockColumn(am1);
      final assigned = makeCamper(assignments: {'b1': 's2'});
      expect(view.cell(assigned, column), const RosterCell('Canoeing'));
      expect(view.cell(makeCamper(), column), const RosterCell('Unassigned', tone: CellTone.alert));
      expect(view.cell(makeCamper(assignments: {'b1': 'nope'}), column).tone, CellTone.alert);
      expect(view.cell(assigned, BlockColumn(am2)).text, 'Unassigned');
    });
  });

  group('sorting', () {
    test('orders age by number, not as text', () {
      final campers = [
        makeCamper(first: 'A', birthdate: DateTime(2016, 1, 1)), // 10
        makeCamper(first: 'B', birthdate: DateTime(2017, 1, 1)), // 9
        makeCamper(first: 'C', birthdate: DateTime(2012, 1, 1)), // 14
      ];
      expect(view.sorted(campers, _age, SortDirection.asc).map((c) => c.firstName), ['B', 'A', 'C']);
      expect(view.sorted(campers, _age, SortDirection.desc).map((c) => c.firstName), ['C', 'A', 'B']);
    });

    test('is case-insensitive and natural for text', () {
      final campers = [
        makeCamper(last: 'zimmer'),
        makeCamper(last: 'Adams'),
        makeCamper(last: 'baker'),
      ];
      expect(view.sorted(campers, _last, SortDirection.asc).map((c) => c.lastName), ['Adams', 'baker', 'zimmer']);
    });

    test('sorts cabins naturally and campers without a cabin last, in both directions', () {
      final campers = [
        makeCamper(first: 'A', cabinId: 'cab10'),
        makeCamper(first: 'B'),
        makeCamper(first: 'C', cabinId: 'cab2'),
      ];
      expect(view.sorted(campers, _cabin, SortDirection.asc).map((c) => c.firstName), ['C', 'A', 'B']);
      expect(view.sorted(campers, _cabin, SortDirection.desc).map((c) => c.firstName), ['A', 'C', 'B']);
    });

    test('sorts by activity name with unassigned last', () {
      final campers = [
        makeCamper(first: 'A', assignments: {'b1': 's2'}), // Canoeing
        makeCamper(first: 'B'),
        makeCamper(first: 'C', assignments: {'b1': 's1'}), // Archery
      ];
      expect(view.sorted(campers, BlockColumn(am1), SortDirection.asc).map((c) => c.firstName), ['C', 'A', 'B']);
      expect(view.sorted(campers, BlockColumn(am1), SortDirection.desc).map((c) => c.firstName), ['A', 'C', 'B']);
    });

    test('sorts booleans and numbers, missing satisfaction last', () {
      final campers = [
        makeCamper(first: 'A', arrived: true, satisfaction: 0.9),
        makeCamper(first: 'B', arrived: false),
        makeCamper(first: 'C', arrived: false, satisfaction: 0.2),
      ];
      expect(view.sorted(campers, _arrived, SortDirection.asc).map((c) => c.firstName), ['B', 'C', 'A']);
      expect(view.sorted(campers, _asi, SortDirection.asc).map((c) => c.firstName), ['C', 'A', 'B']);
      expect(view.sorted(campers, _asi, SortDirection.desc).map((c) => c.firstName), ['A', 'C', 'B']);
    });

    test('breaks ties by name and does not mutate its input', () {
      final campers = [
        makeCamper(first: 'Zed', last: 'Same'),
        makeCamper(first: 'Amy', last: 'Same'),
      ];
      expect(view.sorted(campers, _last, SortDirection.desc).map((c) => c.firstName), ['Amy', 'Zed']);
      expect(campers.first.firstName, 'Zed');
    });
  });

  group('searching', () {
    final campers = [
      makeCamper(first: 'Katherine', preferred: 'Kate', last: 'Johnson'),
      makeCamper(first: 'Alan', last: 'Turing'),
    ];

    test('matches first, preferred, last and full names, ignoring case', () {
      expect(view.filter(campers, 'kat').map((c) => c.firstName), ['Katherine']);
      expect(view.filter(campers, 'KATE JOHN').map((c) => c.firstName), ['Katherine']);
      expect(view.filter(campers, 'katherine johnson').map((c) => c.firstName), ['Katherine']);
      expect(view.filter(campers, 'ing').map((c) => c.firstName), ['Alan']);
    });

    test('an empty or blank query matches everyone', () {
      expect(view.filter(campers, ''), hasLength(2));
      expect(view.filter(campers, '  '), hasLength(2));
      expect(view.filter(campers, 'nobody'), isEmpty);
    });
  });

  group('grouping', () {
    final campers = [
      makeCamper(first: 'A', cabinId: 'cab10'),
      makeCamper(first: 'B'),
      makeCamper(first: 'C', cabinId: 'cab2'),
      makeCamper(first: 'D', cabinId: 'cab10'),
    ];

    test('ungrouped is one group with everyone', () {
      final groups = view.arrange(campers, sortBy: _last);
      expect(groups, hasLength(1));
      expect(groups.single.key, RosterGroup.allKey);
      expect(groups.single.campers, hasLength(4));
    });

    test('groups by cabin title in natural order with "No cabin" last', () {
      final groups = view.arrange(campers, sortBy: _name, groupBy: _cabin);
      expect(groups.map((g) => g.title), ['Cabin 2', 'Cabin 10', 'No cabin']);
      expect(groups.map((g) => g.heading), ['Cabin - Cabin 2', 'Cabin - Cabin 10', 'Cabin - No cabin']);
      expect(groups[1].campers.map((c) => c.firstName), ['A', 'D']);
      expect(groups.map((g) => g.key).toSet(), hasLength(3));
    });

    test('groups by block column with the activity name as the whole heading', () {
      final withActivities = [
        makeCamper(first: 'A', assignments: {'b1': 's2'}),
        makeCamper(first: 'B'),
        makeCamper(first: 'C', assignments: {'b1': 's1'}),
        makeCamper(first: 'D', assignments: {'b1': 's2'}),
      ];
      final groups = view.arrange(withActivities, sortBy: _name, groupBy: BlockColumn(am1));
      expect(groups.map((g) => g.title), ['Archery', 'Canoeing', 'Unassigned']);
      expect(groups.map((g) => g.heading), ['Archery', 'Canoeing', 'Unassigned']);
      expect(groups[1].campers.map((c) => c.firstName), ['A', 'D']);
    });

    test('blank values form an "Unspecified" group', () {
      final groups = view.arrange([makeCamper(first: 'A'), makeCamper(first: 'B', gender: Gender.male)], sortBy: _name, groupBy: const FieldColumn(RosterField.gender));
      expect(groups.map((g) => g.title), ['M', 'Unspecified']);
    });

    test('applies the search before grouping and sorts within groups', () {
      final groups = view.arrange(
        [makeCamper(first: 'Bo', last: 'Z', cabinId: 'cab2'), makeCamper(first: 'Al', last: 'Y', cabinId: 'cab2'), makeCamper(first: 'Cy', last: 'Quinn', cabinId: 'cab10')],
        query: 'o',
        sortBy: _last,
        groupBy: _cabin,
      );
      expect(groups.map((g) => g.title), ['Cabin 2']);
      expect(groups.single.campers.map((c) => c.firstName), ['Bo']);
    });

    test('yields no groups when nobody matches', () {
      expect(view.arrange(campers, query: 'zzz', sortBy: _last, groupBy: _cabin), isEmpty);
    });
  });
}
