import 'package:bessie/src/core/errors.dart';
import 'package:bessie/src/features/branch_manager/catalog_logic.dart';
import 'package:bessie/src/models/activity.dart';
import 'package:bessie/src/models/cabin.dart';
import 'package:bessie/src/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Cabin cabin(String name, {String village = '', int position = 0, String? displayName, int capacity = 10}) => Cabin(
  id: 'cabin-$name',
  branchId: 'branch',
  name: name,
  displayName: displayName,
  village: village,
  capacity: capacity,
  position: position,
);

Activity activity(
  String name, {
  ActivityCategory category = ActivityCategory.other,
  bool skills = false,
  bool double = false,
  bool hidden = false,
  bool ranked = true,
  int capacity = 10,
}) => Activity(
  id: 'activity-$name',
  branchId: 'branch',
  name: name,
  description: '',
  capacity: capacity,
  category: category,
  isSkillsRec: skills,
  doubleSchedule: double,
  maxAssignments: null,
  isHidden: hidden,
  preferenceRequired: ranked,
);

void main() {
  group('pluralize', () {
    test('uses the singular only for one', () {
      expect(pluralize(0, 'camper'), '0 campers');
      expect(pluralize(1, 'camper'), '1 camper');
      expect(pluralize(2, 'camper'), '2 campers');
      expect(pluralize(1, 'activity', 'activities'), '1 activity');
      expect(pluralize(3, 'activity', 'activities'), '3 activities');
    });
  });

  group('groupCabinsByVillage', () {
    test('orders villages by their first cabin and cabins by position', () {
      final groups = groupCabinsByVillage([
        cabin('Heron', village: 'Meadow', position: 7),
        cabin('Maple', village: 'Pines', position: 2),
        cabin('Fox', village: 'Meadow', position: 5),
        cabin('Oak', village: 'Pines', position: 1),
      ]);

      expect(groups.map((g) => g.village), ['Pines', 'Meadow']);
      expect(groups[0].cabins.map((c) => c.name), ['Oak', 'Maple']);
      expect(groups[1].cabins.map((c) => c.name), ['Fox', 'Heron']);
    });

    test('breaks position ties by name, treating numbers naturally', () {
      final groups = groupCabinsByVillage([
        cabin('Cabin 10', village: 'A'),
        cabin('Cabin 9', village: 'A'),
        cabin('cabin 2', village: 'A'),
      ]);
      expect(groups.single.cabins.map((c) => c.name), ['cabin 2', 'Cabin 9', 'Cabin 10']);
    });

    test('sorts by the name shown, so a display name wins over the name', () {
      final groups = groupCabinsByVillage([cabin('Squirt', displayName: 'Ernie'), cabin('Birch')]);
      expect(groups.single.cabins.map((c) => c.title), ['Birch', 'Ernie']);
    });

    test('lists cabins without a village last, under a readable label', () {
      final groups = groupCabinsByVillage([
        cabin('Loner', position: 1),
        cabin('Oak', village: 'Pines', position: 9),
        cabin('Blank', village: '  ', position: 2),
      ]);

      expect(groups.map((g) => g.label), ['Pines', noVillageLabel]);
      expect(groups.last.cabins.map((c) => c.name), ['Loner', 'Blank']);
    });

    test('sums capacity per village and handles no cabins', () {
      final groups = groupCabinsByVillage([cabin('Oak', village: 'Pines', capacity: 10), cabin('Squirt', village: 'Pines', capacity: 8)]);
      expect(groups.single.capacity, 18);
      expect(groupCabinsByVillage(const []), isEmpty);
    });
  });

  test('nextCabinPosition lists a new cabin after all the others', () {
    expect(nextCabinPosition(const []), 1);
    expect(nextCabinPosition([cabin('A', position: 3), cabin('B', position: 8), cabin('C', position: 1)]), 9);
  });

  group('validateCabinForm', () {
    final existing = [cabin('Oak', displayName: 'Big Oak'), cabin('Maple')];

    test('accepts a complete form', () {
      final errors = validateCabinForm(const CabinFormInput(name: 'Birch', capacity: '10'), existing: existing);
      expect(errors.hasErrors, isFalse);
    });

    test('requires a name and a capacity', () {
      final errors = validateCabinForm(const CabinFormInput(name: '   '));
      expect(errors.name, isNotNull);
      expect(errors.capacity, isNotNull);
    });

    test('capacity must be a whole number from 1 up', () {
      String? capacity(String text) => validateCabinForm(CabinFormInput(name: 'A', capacity: text)).capacity;
      expect(capacity('1'), isNull);
      expect(capacity(' 12 '), isNull);
      expect(capacity('0'), isNotNull);
      expect(capacity('-3'), isNotNull);
      expect(capacity('2.5'), isNotNull);
      expect(capacity('ten'), isNotNull);
      expect(capacity('$maxCabinCapacity'), isNull);
      expect(capacity('${maxCabinCapacity + 1}'), isNotNull);
    });

    test('names and display names may not repeat, ignoring case, among names or display names', () {
      expect(validateCabinForm(const CabinFormInput(name: 'oak', capacity: '5'), existing: existing).name, contains('already'));
      expect(validateCabinForm(const CabinFormInput(name: 'big oak', capacity: '5'), existing: existing).name, contains('already'));
      expect(
        validateCabinForm(const CabinFormInput(name: 'New', displayName: 'MAPLE', capacity: '5'), existing: existing).displayName,
        contains('already'),
      );
    });

    test('limits the length of names', () {
      final long = 'x' * (maxCabinNameLength + 1);
      expect(validateCabinForm(CabinFormInput(name: long, capacity: '5')).name, isNotNull);
      expect(validateCabinForm(CabinFormInput(name: 'A', displayName: long, capacity: '5')).displayName, isNotNull);
    });
  });

  group('groupActivitiesByCategory', () {
    test('follows the declared category order, skips empty categories and sorts by name', () {
      final groups = groupActivitiesByCategory([
        activity('Swim', category: ActivityCategory.waterfront),
        activity('Pottery', category: ActivityCategory.creative),
        activity('arts', category: ActivityCategory.creative),
        activity('Quiet time'),
        activity('Archery Skills', category: ActivityCategory.skills, skills: true),
      ]);

      expect(groups.map((g) => g.category), [
        ActivityCategory.creative,
        ActivityCategory.waterfront,
        ActivityCategory.skills,
        ActivityCategory.other,
      ]);
      expect(groups.first.activities.map((a) => a.name), ['arts', 'Pottery']);
    });

    test('is empty without activities', () {
      expect(groupActivitiesByCategory(const []), isEmpty);
    });
  });

  group('activityBadges', () {
    test('lists each special trait and nothing for a plain activity', () {
      expect(activityBadges(activity('Plain')), isEmpty);
      expect(activityBadges(activity('Ropes', double: true)), [ActivityBadge.doubleBlock]);
      expect(activityBadges(activity('Everything', skills: true, double: true, hidden: true, ranked: false)), [
        ActivityBadge.skillsRec,
        ActivityBadge.doubleBlock,
        ActivityBadge.hidden,
        ActivityBadge.noRanking,
      ]);
    });
  });

  group('validateActivityForm', () {
    const valid = ActivityFormInput(name: 'Archery', capacity: '10');

    test('accepts a minimal form and a fully filled one', () {
      expect(validateActivityForm(valid).hasErrors, isFalse);
      expect(
        validateActivityForm(
          const ActivityFormInput(name: 'Ropes', description: 'High up', capacity: '8', maxAssignments: '2', doubleSchedule: true),
        ).hasErrors,
        isFalse,
      );
    });

    test('requires a name', () {
      expect(validateActivityForm(const ActivityFormInput(capacity: '10')).name, isNotNull);
      expect(validateActivityForm(const ActivityFormInput(name: '   ', capacity: '10')).name, isNotNull);
    });

    test('names are unique ignoring case and surrounding spaces', () {
      expect(
        validateActivityForm(const ActivityFormInput(name: ' archery ', capacity: '10'), otherActivityNames: ['Archery']).name,
        contains('already'),
      );
      expect(validateActivityForm(valid, otherActivityNames: ['Pottery']).name, isNull);
    });

    test('limits the length of the name', () {
      expect(validateActivityForm(ActivityFormInput(name: 'x' * (maxActivityNameLength + 1), capacity: '10')).name, isNotNull);
      expect(validateActivityForm(ActivityFormInput(name: 'x' * maxActivityNameLength, capacity: '10')).name, isNull);
    });

    test('capacity is required and positive', () {
      String? capacity(String text) => validateActivityForm(ActivityFormInput(name: 'A', capacity: text)).capacity;
      expect(capacity(''), isNotNull);
      expect(capacity('0'), isNotNull);
      expect(capacity('-1'), isNotNull);
      expect(capacity('1.5'), isNotNull);
      expect(capacity('abc'), isNotNull);
      expect(capacity('1'), isNull);
      expect(capacity('$maxActivityCapacity'), isNull);
      expect(capacity('${maxActivityCapacity + 1}'), isNotNull);
    });

    test('the per-camper limit is optional but must be positive when given', () {
      String? limit(String text) => validateActivityForm(ActivityFormInput(name: 'A', capacity: '5', maxAssignments: text)).maxAssignments;
      expect(limit(''), isNull);
      expect(limit('   '), isNull);
      expect(limit('2'), isNull);
      expect(limit('0'), isNotNull);
      expect(limit('x'), isNotNull);
      expect(limit('${maxActivityAssignments + 1}'), isNotNull);
    });

    test('reports every problem at once', () {
      final errors = validateActivityForm(const ActivityFormInput(maxAssignments: '0'));
      expect([errors.name, errors.capacity, errors.maxAssignments], everyElement(isNotNull));
    });
  });

  group('buildActivity', () {
    test('trims text and parses numbers', () {
      final built = buildActivity(
        const ActivityFormInput(
          name: '  Ropes Course ',
          description: ' High up ',
          capacity: ' 8 ',
          category: ActivityCategory.campClassics,
          doubleSchedule: true,
          maxAssignments: '2',
          isHidden: true,
          preferenceRequired: false,
        ),
        branchId: 'b1',
        id: 'a1',
      );

      expect(built.id, 'a1');
      expect(built.branchId, 'b1');
      expect(built.name, 'Ropes Course');
      expect(built.description, 'High up');
      expect(built.capacity, 8);
      expect(built.category, ActivityCategory.campClassics);
      expect(built.doubleSchedule, isTrue);
      expect(built.maxAssignments, 2);
      expect(built.isHidden, isTrue);
      expect(built.preferenceRequired, isFalse);
      expect(built.isSkillsRec, isFalse);
    });

    test('a blank limit means no limit and a new activity has no id', () {
      final built = buildActivity(const ActivityFormInput(name: 'Archery', capacity: '10'), branchId: 'b1');
      expect(built.maxAssignments, isNull);
      expect(built.id, isEmpty);
    });

    test('round-trips through the form', () {
      final original = activity(
        'Archery',
        category: ActivityCategory.sportsAndAthletics,
        skills: true,
        double: true,
        hidden: true,
        ranked: false,
        capacity: 12,
      );
      final rebuilt = buildActivity(ActivityFormInput.fromActivity(original), branchId: original.branchId, id: original.id);

      expect(rebuilt.toInsertRow(), original.toInsertRow());
      expect(rebuilt.id, original.id);
    });
  });

  group('skillsRecAfterCategoryChange', () {
    test('choosing the skills category marks a skills rec', () {
      expect(skillsRecAfterCategoryChange(from: ActivityCategory.other, to: ActivityCategory.skills, isSkillsRec: false), isTrue);
    });

    test('leaving the skills category clears the mark', () {
      expect(skillsRecAfterCategoryChange(from: ActivityCategory.skills, to: ActivityCategory.creative, isSkillsRec: true), isFalse);
    });

    test('other changes keep what the user chose', () {
      expect(skillsRecAfterCategoryChange(from: ActivityCategory.creative, to: ActivityCategory.silly, isSkillsRec: true), isTrue);
      expect(skillsRecAfterCategoryChange(from: ActivityCategory.creative, to: ActivityCategory.silly, isSkillsRec: false), isFalse);
    });
  });

  group('activityStillScheduledMessage', () {
    final archery = activity('Archery');

    test('explains a foreign key refusal', () {
      final refusal = AppException.from(PostgrestException(message: 'violates foreign key constraint', code: '23503'));
      expect(activityStillScheduledMessage(refusal, archery), allOf(contains('Archery'), contains('scheduled')));
    });

    test('has nothing to say about other failures', () {
      expect(activityStillScheduledMessage(AppException('The server rejected that request.'), archery), isNull);
      expect(activityStillScheduledMessage(AppException.from(PostgrestException(message: 'denied', code: '42501')), archery), isNull);
      expect(activityStillScheduledMessage(StateError('boom'), archery), isNull);
    });
  });
}
