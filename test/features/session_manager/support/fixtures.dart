import 'package:bessie/src/models/activity.dart';
import 'package:bessie/src/models/cabin.dart';
import 'package:bessie/src/models/camp_session.dart';
import 'package:bessie/src/models/camper.dart';
import 'package:bessie/src/models/enums.dart';
import 'package:bessie/src/models/schedule.dart';

Cabin cabin(String id, {int capacity = 10, String village = 'Pines', int position = 0, String? displayName}) =>
    Cabin(id: id, branchId: 'branch', name: id, displayName: displayName, village: village, capacity: capacity, position: position);

Activity activity(String id, {String? name, bool skills = false, int capacity = 10, bool hidden = false, bool double = false}) => Activity(
  id: id,
  branchId: 'branch',
  name: name ?? id,
  description: 'About $id',
  capacity: capacity,
  category: skills ? ActivityCategory.skills : ActivityCategory.other,
  isSkillsRec: skills,
  doubleSchedule: double,
  maxAssignments: null,
  isHidden: hidden,
  preferenceRequired: true,
);

Camper camper(String id, {String? cabinId, Map<String, String> assignments = const {}}) => Camper(
  id: id,
  sessionId: 'session',
  firstName: id,
  preferredName: null,
  lastName: 'Camper',
  gender: null,
  birthdate: DateTime(2015, 1, 1),
  note: '',
  cabinId: cabinId,
  ultracampId: null,
  arrived: false,
  canSwim: false,
  satisfactionIndex: null,
  preferencesSubmittedAt: null,
  assignments: assignments,
);

Block block(String id, {int dayIndex = 0, int startHour = 10, bool skills = false, DateTime? date}) => Block(
  id: id,
  sessionId: 'session',
  dayId: 'day$dayIndex',
  title: 'Block $id',
  date: date ?? DateTime(2026, 7, 6 + dayIndex),
  dayIndex: dayIndex,
  startTime: Duration(hours: startHour, minutes: 15),
  endTime: Duration(hours: startHour + 1, minutes: 15),
  isSkillsRec: skills,
);

CampSession sessionStarting(DateTime date, {String id = 's'}) => CampSession(
  id: id,
  seasonId: 'season',
  name: 'Session $id',
  startsOn: date,
  limits: const PreferenceLimits(maxRequests: 3, maxVetoes: 2, maxSkillsRequests: 2, maxSkillsVetoes: 1),
);
