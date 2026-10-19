import 'package:bessie/src/models/activity.dart';
import 'package:bessie/src/models/camper.dart';
import 'package:bessie/src/models/camp_session.dart';
import 'package:bessie/src/models/cabin.dart';
import 'package:bessie/src/models/enums.dart';
import 'package:bessie/src/models/organization.dart';
import 'package:bessie/src/models/row_codec.dart';
import 'package:bessie/src/models/schedule.dart';
import 'package:bessie/src/models/staff_profile.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> camperRow({Map<String, dynamic>? overrides}) => {
  'id': 'c1',
  'session_id': 's1',
  'first_name': 'Ada',
  'preferred_name': null,
  'last_name': 'Lovelace',
  'gender': 'F',
  'birthdate': '2015-12-10',
  'note': '',
  'cabin_id': 'cab1',
  'ultracamp_id': '1001',
  'arrived': true,
  'can_swim': false,
  'activity_satisfaction_index': 1,
  'preferences_submitted_at': '2026-07-06T14:30:00+00:00',
  'assignments': [
    {'block_id': 'b1', 'scheduled_activity_id': 'sa1'},
    {'block_id': 'b2', 'scheduled_activity_id': 'sa2'},
  ],
  'camper_preferences': [
    {'activity_id': 'a1', 'kind': 'request'},
    {'activity_id': 'a2', 'kind': 'veto'},
  ],
  ...?overrides,
};

void main() {
  group('row codecs', () {
    test('dates are local calendar dates and round-trip', () {
      final date = parseDate('2026-07-06');
      expect(date, DateTime(2026, 7, 6));
      expect(date.isUtc, isFalse);
      expect(formatDbDate(date), '2026-07-06');
      expect(parseDate('2026-07-06T00:00:00+00:00'), DateTime(2026, 7, 6), reason: 'only the date part matters');
    });

    test('times are durations since midnight', () {
      expect(parseTime('10:15:00'), const Duration(hours: 10, minutes: 15));
      expect(formatDbTime(const Duration(hours: 9, minutes: 5)), '09:05:00');
    });
  });

  group('Camper', () {
    test('parses embedded assignments and preferences', () {
      final camper = Camper.fromRow(camperRow());
      expect(camper.assignments, {'b1': 'sa1', 'b2': 'sa2'});
      expect(camper.preferences, {'a1': PreferenceKind.request, 'a2': PreferenceKind.veto});
      expect(camper.requestedActivityIds, {'a1'});
      expect(camper.vetoedActivityIds, {'a2'});
      expect(camper.gender, Gender.female);
      expect(camper.satisfactionIndex, 1.0);
      expect(camper.preferencesSubmitted, isTrue);
      expect(camper.birthdate, DateTime(2015, 12, 10));
    });

    test('works without embeds', () {
      final camper = Camper.fromRow(camperRow(overrides: {'assignments': null, 'camper_preferences': null, 'preferences_submitted_at': null, 'gender': null}));
      expect(camper.assignments, isEmpty);
      expect(camper.preferences, isEmpty);
      expect(camper.preferencesSubmitted, isFalse);
      expect(camper.gender, isNull);
    });

    test('names', () {
      final plain = Camper.fromRow(camperRow());
      expect(plain.name, 'Ada');
      expect(plain.fullName, 'Ada Lovelace');
      expect(plain.displayTitle, 'Ada L');
      final nick = Camper.fromRow(camperRow(overrides: {'preferred_name': 'Lady A'}));
      expect(nick.name, 'Lady A');
      expect(nick.fullNamePreferred, 'Lady A Lovelace');
      expect(nick.fullName, 'Ada Lovelace');
    });

    test('age counts whole years and handles birthdays', () {
      final camper = Camper.fromRow(camperRow());
      expect(camper.ageOn(DateTime(2026, 12, 9)), 10);
      expect(camper.ageOn(DateTime(2026, 12, 10)), 11);
      expect(camper.ageOn(DateTime(2015, 1, 1)), 0, reason: 'never negative');
    });

    test('copyWith keeps unrelated fields and can clear the cabin', () {
      final camper = Camper.fromRow(camperRow());
      expect(camper.copyWith(arrived: false).arrived, isFalse);
      expect(camper.copyWith(arrived: false).cabinId, 'cab1');
      expect(camper.copyWith(clearCabin: true).cabinId, isNull);
      expect(camper.copyWith(clearPreferencesSubmitted: true).preferencesSubmitted, isFalse);
    });
  });

  group('Schedule', () {
    final monday = ScheduleDay(id: 'd1', sessionId: 's', dayIndex: 0, date: DateTime(2026, 7, 6));
    final tuesday = ScheduleDay(id: 'd2', sessionId: 's', dayIndex: 1, date: DateTime(2026, 7, 7));

    Block block(String id, ScheduleDay day, String title, int hour, {bool skills = false}) => Block.fromRow({
      'id': id,
      'session_id': 's',
      'day_id': day.id,
      'title': title,
      'start_time': '${hour.toString().padLeft(2, '0')}:15:00',
      'end_time': '${(hour + 1).toString().padLeft(2, '0')}:00:00',
      'is_skills_rec': skills,
    }, day);

    test('blocks combine day and wall-clock time without timezones', () {
      final b = block('b', monday, 'Choice 1', 10);
      expect(b.start, DateTime(2026, 7, 6, 10, 15));
      expect(b.end, DateTime(2026, 7, 6, 11));
      expect(b.weekdayName, 'Monday');
      expect(b.displayTitle, 'Monday - Choice 1');
    });

    test('keeps blocks chronological and offers lookups', () {
      const pottery = Activity(
        id: 'a1', branchId: 'br', name: 'Pottery', description: '', capacity: 8, category: ActivityCategory.creative,
        isSkillsRec: false, doubleSchedule: false, maxAssignments: null, isHidden: false, preferenceRequired: true,
      );
      final schedule = Schedule(
        days: [tuesday, monday],
        blocks: [block('b3', tuesday, 'Skills', 9, skills: true), block('b2', monday, 'Choice 2', 11), block('b1', monday, 'Choice 1', 10)],
        scheduledActivities: const [
          ScheduledActivity(id: 'sa1', sessionId: 's', blockId: 'b1', activityId: 'a1'),
          ScheduledActivity(id: 'sa2', sessionId: 's', blockId: 'b2', activityId: 'a1'),
        ],
        activitiesById: {'a1': pottery},
      );
      expect(schedule.blocks.map((b) => b.id), ['b1', 'b2', 'b3']);
      expect(schedule.days.map((d) => d.id), ['d1', 'd2']);
      expect(schedule.scheduledIn('b1').single.id, 'sa1');
      expect(schedule.activityOf(schedule.scheduledActivityById('sa2')!), pottery);
      expect(schedule.offeredActivities, {pottery});
      expect(schedule.blockById('nope'), isNull);
    });
  });

  test('PreferenceLimits picks the right limit', () {
    const limits = PreferenceLimits(maxRequests: 3, maxVetoes: 2, maxSkillsRequests: 1, maxSkillsVetoes: 0);
    expect(limits.maxFor(PreferenceKind.request, skillsRec: false), 3);
    expect(limits.maxFor(PreferenceKind.veto, skillsRec: false), 2);
    expect(limits.maxFor(PreferenceKind.request, skillsRec: true), 1);
    expect(limits.maxFor(PreferenceKind.veto, skillsRec: true), 0);
  });

  test('CampSession and Season parse', () {
    final session = CampSession.fromRow({
      'id': 's', 'season_id': 'se', 'name': 'Session 1', 'starts_on': '2026-07-06',
      'max_requests': 3, 'max_vetoes': 2, 'max_skills_requests': 2, 'max_skills_vetoes': 1,
    });
    expect(session.startsOn, DateTime(2026, 7, 6));
    expect(session.limits.maxVetoes, 2);

    final season = Season.fromRow({'id': 'se', 'branch_id': 'b', 'name': 'Summer', 'starts_on': '2026-06-29', 'ends_on': '2026-08-21'});
    expect(season.contains(DateTime(2026, 6, 29)), isTrue);
    expect(season.contains(DateTime(2026, 8, 21)), isTrue);
    expect(season.contains(DateTime(2026, 8, 22)), isFalse);
  });

  test('Cabin shows its display name when set', () {
    final row = {'id': 'c', 'branch_id': 'b', 'name': 'Squirt', 'display_name': 'Ernie', 'village': 'Meadow', 'capacity': 8, 'position': 1};
    expect(Cabin.fromRow(row).title, 'Ernie');
    expect(Cabin.fromRow({...row, 'display_name': null}).title, 'Squirt');
  });

  test('StaffRole permissions', () {
    expect(StaffRole.counselor.canEditSessionData, isFalse);
    expect(StaffRole.admin.canEditSessionData, isTrue);
    expect(StaffRole.admin.canManageStructure, isFalse);
    expect(StaffRole.director.canManageStructure, isTrue);
    expect(StaffRole.fromDb('root'), StaffRole.root);
  });

  test('StaffProfile parses and derives names', () {
    final profile = StaffProfile.fromRow({
      'id': 'u', 'organization_id': 'o', 'first_name': 'Dana', 'last_name': 'Director', 'preferred_name': null,
      'role': 'director', 'active': true, 'preferences': {'last_session_id': 'x'},
    });
    expect(profile.fullName, 'Dana Director');
    expect(profile.initials, 'DD');
    expect(profile.preferences['last_session_id'], 'x');
  });

  test('CamperImportRow serializes for the import RPC', () {
    final json = CamperImportRow(
      firstName: 'Ada', lastName: 'Lovelace', birthdate: DateTime(2015, 12, 10), gender: Gender.nonBinary, cabinName: 'Oak',
    ).toJson();
    expect(json['birthdate'], '2015-12-10');
    expect(json['gender'], 'NB');
    expect(json['cabin'], 'Oak');
    expect(CamperImportResult.fromJson({'inserted': 2, 'duplicates': 1, 'unknown_cabins': ['X']}).unknownCabins, ['X']);
  });
}
