import 'package:bessie/src/features/session_manager/session_setup_logic.dart';
import 'package:bessie/src/models/camp_session.dart';
import 'package:bessie/src/models/organization.dart';
import 'package:bessie/src/models/schedule.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures.dart';

void main() {
  group('counting', () {
    test('camperCountsByCabin ignores campers without a cabin', () {
      final counts = camperCountsByCabin([camper('a', cabinId: 'oak'), camper('b', cabinId: 'oak'), camper('c', cabinId: 'fox'), camper('d')]);
      expect(counts, {'oak': 2, 'fox': 1});
    });

    test('enrollmentCounts counts every assignment to a scheduled activity', () {
      final counts = enrollmentCounts([
        camper('a', assignments: {'b1': 'sa1', 'b2': 'sa2'}),
        camper('b', assignments: {'b1': 'sa1'}),
        camper('c'),
      ]);
      expect(counts, {'sa1': 2, 'sa2': 1});
    });
  });

  group('diffCabinSelection', () {
    const campersByCabin = {'oak': 4, 'fox': 3, 'elm': 0};

    test('nothing changes when the selection matches', () {
      final change = diffCabinSelection(registered: {'oak', 'fox'}, selected: {'fox', 'oak'}, campersByCabin: campersByCabin);
      expect(change.isEmpty, isTrue);
      expect(change.campersLeftWithoutCabin, 0);
    });

    test('adding cabins leaves nobody without a cabin', () {
      final change = diffCabinSelection(registered: {'oak'}, selected: {'oak', 'fox', 'elm'}, campersByCabin: campersByCabin);
      expect(change.added, {'fox', 'elm'});
      expect(change.removed, isEmpty);
      expect(change.campersLeftWithoutCabin, 0);
    });

    test('removing cabins counts the campers staying in them', () {
      final change = diffCabinSelection(registered: {'oak', 'fox', 'elm'}, selected: {'fox'}, campersByCabin: campersByCabin);
      expect(change.removed, {'oak', 'elm'});
      expect(change.campersLeftWithoutCabin, 4);
    });

    test('removing an empty cabin is free', () {
      final change = diffCabinSelection(registered: {'oak', 'elm'}, selected: {'oak'}, campersByCabin: campersByCabin);
      expect(change.isEmpty, isFalse);
      expect(change.campersLeftWithoutCabin, 0);
    });

    test('adding and removing at once', () {
      final change = diffCabinSelection(registered: {'oak'}, selected: {'fox'}, campersByCabin: campersByCabin);
      expect(change.added, {'fox'});
      expect(change.removed, {'oak'});
      expect(change.campersLeftWithoutCabin, 4);
    });

    test('a cabin nobody counted has no campers', () {
      final change = diffCabinSelection(registered: {'unknown'}, selected: const {}, campersByCabin: campersByCabin);
      expect(change.campersLeftWithoutCabin, 0);
    });
  });

  group('SessionSetup', () {
    final blockA = block('a');
    final sessionActivities = [activity('soccer', name: 'Soccer', capacity: 20), activity('arts', name: 'arts', capacity: 8)];
    final schedule = Schedule(
      days: [ScheduleDay(id: 'day0', sessionId: 'session', dayIndex: 0, date: DateTime(2026, 7, 6))],
      blocks: [blockA],
      scheduledActivities: const [
        ScheduledActivity(id: 'sa-soccer', sessionId: 'session', blockId: 'a', activityId: 'soccer'),
        ScheduledActivity(id: 'sa-arts', sessionId: 'session', blockId: 'a', activityId: 'arts'),
      ],
      activitiesById: {for (final a in sessionActivities) a.id: a},
    );
    final setup = SessionSetup(
      session: sessionStarting(DateTime(2026, 7, 6)),
      cabins: [cabin('oak'), cabin('fox'), cabin('elm')],
      registeredCabinIds: ['oak', 'fox'],
      campers: [
        camper('a', cabinId: 'oak', assignments: {'a': 'sa-soccer'}),
        camper('b', cabinId: 'oak', assignments: {'a': 'sa-soccer'}),
        camper('c'),
      ],
      schedule: schedule,
      activities: sessionActivities,
    );

    test('summarizes the session', () {
      expect(setup.camperCount, 3);
      expect(setup.blockCount, 1);
      expect(setup.registeredCabinCount, 2);
      expect(setup.scheduledActivityCount, 2);
      expect(setup.campersByCabin, {'oak': 2});
      expect(setup.branchCabinIds, {'oak', 'fox', 'elm'});
    });

    test('counts enrollment per scheduled activity', () {
      final soccer = schedule.scheduledActivityById('sa-soccer')!;
      final arts = schedule.scheduledActivityById('sa-arts')!;
      expect(setup.enrolledIn(soccer), 2);
      expect(setup.enrolledIn(arts), 0);
    });

    test('lists what a block offers by activity name, ignoring case', () {
      expect(setup.offeredIn(blockA).map((s) => s.activityId), ['arts', 'soccer']);
    });
  });

  group('groupBlocksByDay', () {
    test('orders days and the blocks within them', () {
      final days = groupBlocksByDay([
        block('tue-late', dayIndex: 1, startHour: 13),
        block('mon', dayIndex: 0),
        block('tue-early', dayIndex: 1, startHour: 9),
      ]);

      expect(days.map((d) => d.dayIndex), [0, 1]);
      expect(days[1].blocks.map((b) => b.id), ['tue-early', 'tue-late']);
      expect(days[1].date, DateTime(2026, 7, 7));
    });

    test('has a readable heading', () {
      expect(groupBlocksByDay([block('mon')]).single.heading, 'Day 1 - Monday, Jul 6');
    });

    test('is empty without blocks', () {
      expect(groupBlocksByDay(const []), isEmpty);
    });
  });

  group('formatClock', () {
    test('uses a twelve hour clock', () {
      expect(formatClock(const Duration(hours: 0, minutes: 5)), '12:05 AM');
      expect(formatClock(const Duration(hours: 9, minutes: 15)), '9:15 AM');
      expect(formatClock(const Duration(hours: 12)), '12:00 PM');
      expect(formatClock(const Duration(hours: 13, minutes: 30)), '1:30 PM');
      expect(formatClock(const Duration(hours: 23, minutes: 59)), '11:59 PM');
    });

    test('formats a block as a range', () {
      expect(formatBlockTimes(block('a')), '10:15 AM - 11:15 AM');
    });
  });

  group('addableActivityGroups', () {
    final catalog = [
      activity('soccer', name: 'Soccer'),
      activity('arts', name: 'Arts'),
      activity('swim-skills', name: 'Swim Skills', skills: true),
      activity('archery-skills', name: 'Archery Skills', skills: true),
    ];

    test('offers standard activities first for a normal block, by name', () {
      final groups = addableActivityGroups(block: block('a'), catalog: catalog, offeredActivityIds: const []);

      expect(groups.map((g) => g.title), [standardActivitiesTitle, skillsRecsTitle]);
      expect(groups[0].activities.map((a) => a.name), ['Arts', 'Soccer']);
      expect(groups[1].activities.map((a) => a.name), ['Archery Skills', 'Swim Skills']);
    });

    test('offers skills recs first for a skills rec block but still allows everything', () {
      final groups = addableActivityGroups(block: block('a', skills: true), catalog: catalog, offeredActivityIds: const []);

      expect(groups.map((g) => g.title), [skillsRecsTitle, standardActivitiesTitle]);
      expect(groups.expand((g) => g.activities), hasLength(catalog.length));
    });

    test('leaves out what the block already offers', () {
      final groups = addableActivityGroups(block: block('a'), catalog: catalog, offeredActivityIds: ['soccer', 'swim-skills']);

      expect(groups[0].activities.map((a) => a.id), ['arts']);
      expect(groups[1].activities.map((a) => a.id), ['archery-skills']);
    });

    test('drops groups that end up empty', () {
      final groups = addableActivityGroups(block: block('a'), catalog: catalog, offeredActivityIds: ['swim-skills', 'archery-skills']);
      expect(groups.map((g) => g.title), [standardActivitiesTitle]);
    });

    test('is empty when everything is offered or the catalog is empty', () {
      expect(addableActivityGroups(block: block('a'), catalog: catalog, offeredActivityIds: [for (final a in catalog) a.id]), isEmpty);
      expect(addableActivityGroups(block: block('a'), catalog: const [], offeredActivityIds: const []), isEmpty);
    });

    test('ignores offered ids that are not in the catalog', () {
      final groups = addableActivityGroups(block: block('a'), catalog: catalog, offeredActivityIds: ['deleted']);
      expect(groups.expand((g) => g.activities), hasLength(catalog.length));
    });
  });

  group('LimitsDraft', () {
    test('converts to and from the session limits', () {
      const limits = PreferenceLimits(maxRequests: 4, maxVetoes: 1, maxSkillsRequests: 3, maxSkillsVetoes: 0);
      final draft = LimitsDraft.fromLimits(limits);

      expect(draft.toLimits().maxRequests, 4);
      expect(draft.toLimits().maxVetoes, 1);
      expect(draft.toLimits().maxSkillsRequests, 3);
      expect(draft.toLimits().maxSkillsVetoes, 0);
    });

    test('compares by value', () {
      expect(LimitsDraft.defaults, LimitsDraft.defaults.copyWith());
      expect(LimitsDraft.defaults == LimitsDraft.defaults.copyWith(maxVetoes: 5), isFalse);
      expect(LimitsDraft.defaults.hashCode, LimitsDraft.defaults.copyWith().hashCode);
    });

    test('copyWith changes one limit and keeps every limit within bounds', () {
      final draft = LimitsDraft.defaults.copyWith(maxRequests: 7);
      expect(draft.maxRequests, 7);
      expect(draft.maxVetoes, LimitsDraft.defaults.maxVetoes);
      expect(LimitsDraft.defaults.copyWith(maxVetoes: -3).maxVetoes, 0);
      expect(LimitsDraft.defaults.copyWith(maxRequests: 1000).maxRequests, LimitsDraft.highest);
    });
  });

  group('validateNewSession', () {
    final date = DateTime(2026, 7, 6);

    test('accepts a name and a date', () {
      expect(validateNewSession(name: 'Session 3', startsOn: date).hasErrors, isFalse);
    });

    test('requires a name', () {
      expect(validateNewSession(name: '', startsOn: date).name, isNotNull);
      expect(validateNewSession(name: '   ', startsOn: date).name, isNotNull);
    });

    test('requires a date', () {
      expect(validateNewSession(name: 'Session 3', startsOn: null).startsOn, isNotNull);
    });

    test('names are unique within the season, ignoring case and spaces', () {
      final errors = validateNewSession(name: ' session 1 ', startsOn: date, existingNames: ['Session 1', 'Session 2']);
      expect(errors.name, contains('already'));
      expect(validateNewSession(name: 'Session 3', startsOn: date, existingNames: ['Session 1']).name, isNull);
    });

    test('limits the length of the name', () {
      expect(validateNewSession(name: 'x' * (maxSessionNameLength + 1), startsOn: date).name, isNotNull);
    });

    test('reports both problems together', () {
      final errors = validateNewSession(name: '', startsOn: null);
      expect(errors.name, isNotNull);
      expect(errors.startsOn, isNotNull);
    });
  });

  group('season helpers', () {
    final season = Season(id: 'season', branchId: 'branch', name: 'Summer 2026', startsOn: DateTime(2026, 6, 15), endsOn: DateTime(2026, 8, 21));

    test('outsideSeasonWarning only speaks up outside the season', () {
      expect(outsideSeasonWarning(DateTime(2026, 7, 6), season), isNull);
      expect(outsideSeasonWarning(DateTime(2026, 6, 15), season), isNull);
      expect(outsideSeasonWarning(DateTime(2026, 8, 21), season), isNull);
      expect(outsideSeasonWarning(DateTime(2026, 9, 1), season), allOf(contains('Summer 2026'), contains('Jun 15'), contains('Aug 21')));
      expect(outsideSeasonWarning(DateTime(2027, 7, 6), null), isNull);
    });

    test('suggestedSessionStart is a week after the latest session', () {
      final sessions = [sessionStarting(DateTime(2026, 6, 22), id: 'a'), sessionStarting(DateTime(2026, 7, 6), id: 'b')];
      expect(suggestedSessionStart(sessions: sessions, season: season, today: DateTime(2026, 1, 1)), DateTime(2026, 7, 13));
    });

    test('suggestedSessionStart rolls over month ends', () {
      final sessions = [sessionStarting(DateTime(2026, 7, 27))];
      expect(suggestedSessionStart(sessions: sessions, season: season, today: DateTime(2026, 1, 1)), DateTime(2026, 8, 3));
    });

    test('suggestedSessionStart falls back to the start of the season, then today', () {
      expect(suggestedSessionStart(sessions: const [], season: season, today: DateTime(2026, 1, 1)), DateTime(2026, 6, 15));
      expect(suggestedSessionStart(sessions: const [], season: null, today: DateTime(2026, 1, 9, 14, 30)), DateTime(2026, 1, 9));
    });
  });
}
